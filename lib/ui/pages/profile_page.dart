import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socialgame/services/auth.dart';
import 'package:socialgame/services/firestore.dart';
import 'package:socialgame/ui/pages/create_message_page.dart';
import 'package:socialgame/ui/widgets/AppDialog.dart';
import 'package:socialgame/ui/widgets/app_button.dart';
import 'package:socialgame/ui/widgets/base_app_bar.dart';
import 'package:socialgame/ui/widgets/dig_button.dart';
import 'package:socialgame/utils/timeago.dart';

class ProfilePage extends ConsumerStatefulWidget {
  final String? uid;
  const ProfilePage({this.uid, Key? key}) : super(key: key);
  static const routeName = '/profile';

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final textController = TextEditingController();
  int endTime = DateTime.now().millisecondsSinceEpoch + (1000 * 90);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final arguments = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map;
    final uid = widget.uid ?? arguments['uid'];
    final isOwner = uid == FirebaseAuth.instance.currentUser?.uid;

    final userAsyncValue = ref.watch(AuthService.appUserStreamProvider(uid));

    final currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return userAsyncValue.when(
      data: (user) {
        if (user == null) return const SizedBox();

        // final isMarried = user.marriedTo != null;

        return Scaffold(
          appBar: BaseAppBar(
            title: user.displayName,
          ),
          body: SafeArea(
            child: StreamBuilder<Map<String, dynamic>>(
                stream:
                    FirestoreAPI.friendRequestStream(currentUserUid, user.uid),
                builder: (context, snapshot) {
                  final requestData = snapshot.data ?? {};
                  print('_ProfilePageState.friend request $requestData');

                  return ListView(
                    children: [
                      if (requestData.isNotEmpty)
                        ListTile(
                          title: Text(
                              '${requestData['display_name']} wants to be friends'),
                          trailing: AppButton(
                            title: 'Add',
                            onTap: () {
                              FirestoreAPI.addFriend(user, true);
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.grey,
                          radius: 48,
                          child: Text(
                            user.displayName[0].toUpperCase(),
                            style: Theme.of(context).textTheme.headline4,
                          ),
                        ),
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.all(16.0),
                      //   child: Text(
                      //     user.toMap().toString(),
                      //     style: Theme.of(context).textTheme.bodyText1,
                      //   ),
                      // ),
                      // Padding(
                      //   padding: const EdgeInsets.all(16.0),
                      //   child: Text(
                      //     timeAgo(user.createdAt),
                      //     style: Theme.of(context).textTheme.bodyText1,
                      //   ),
                      // ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: StreamBuilder<Map<String, dynamic>>(
                          stream: FirestoreAPI.userStatsStream(uid),
                          builder: (context, snapshot) {
                            final stats = snapshot.data ?? {};
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                StatsWidget(
                                  title: 'Faith',
                                  subtitle: (stats['faith'] ?? 0).toString(),
                                ),
                                StatsWidget(
                                  title: 'Coins',
                                  subtitle: (stats['coins'] ?? 0).toString(),
                                ),
                                StatsWidget(
                                  title: 'Age',
                                  subtitle: timeAgo(user.createdAt),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      if (!isOwner)
                        ListTile(
                          title: TextFormField(
                            controller: textController,
                            decoration: InputDecoration(
                              label: const Text('Commands'),
                              hintText: 'What do you want to do?',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.face_outlined),
                                onPressed: () async {
                                  final text = textController.text;
                                  FirestoreAPI.addPlayerCommand(
                                    await AuthService.currentAppUser(),
                                    user,
                                    text,
                                  ).catchError((e) =>
                                      AppDialog.show(context, e.toString()));
                                },
                              ),
                            ),
                          ),
                        ),

                      if (!isOwner)
                        ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: StreamBuilder<Map<String, dynamic>>(
                                  stream: FirestoreAPI.friendStream(user.uid),
                                  builder: (context, snapshot) {
                                    final data = snapshot.data;
                                    print('_ProfilePageState.build $data');

                                    final isFriend = data != null &&
                                        data['accepted'] == true;

                                    return StreamBuilder<Map<String, dynamic>>(
                                      stream: FirestoreAPI.friendRequestStream(
                                        user.uid,
                                        currentUserUid,
                                      ),
                                      builder: (context, snapshot) {
                                        final requestData2 =
                                            snapshot.data ?? {};

                                        final hasRequest =
                                            requestData2.isNotEmpty;

                                        return AppButton(
                                          onTap: () {
                                            if (!hasRequest && !isFriend) {
                                              FirestoreAPI.addFriendRequest(
                                                  user);
                                            } else if (isFriend) {
                                              FirestoreAPI.removeFriend(
                                                  user.uid);
                                            }
                                          },
                                          title: isFriend
                                              ? 'Following'
                                              : hasRequest
                                                  ? 'Requested'
                                                  : 'Add Friend',
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppButton(
                                  onTap: () {
                                    Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                CreateMessagePage(user: user)));
                                  },
                                  title: 'Message',
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!isOwner)
                        ListTile(
                          title: Text(
                            'lick, slap, hug',
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_horiz),
                            onPressed: () async {
                              Navigator.of(context).pushNamed('/commands');
                            },
                          ),
                        ),
                      if (isOwner) DigButton(user),
                      if (isOwner) BakeButton(user),
                      // ListTile(
                      //   title: const Text('Marry'),
                      //   onTap: () async {
                      //     final currentUser =
                      //         await AuthService.currentAppUser();
                      //     user.marriedTo == null
                      //         ? FirestoreAPI.marry(currentUser, user)
                      //         : FirestoreAPI.divorce(currentUser, user);
                      //   },
                      // ),

                      StreamBuilder<Map<String, dynamic>>(
                          stream: FirestoreAPI.userInventoryStream(uid),
                          builder: (context, snapshot) {
                            final data = snapshot.data ?? {};

                            final items = data.values.toList();

                            return Column(
                              children: [
                                ListTile(
                                  title: Text('Items (${data.keys.length})'),
                                ),
                                // ListTile(
                                //   title: Text(data.toString()),
                                // ),
                                GridView.extent(
                                  shrinkWrap: true,
                                  maxCrossAxisExtent: 200,
                                  padding: const EdgeInsets.all(20),
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  children: List.generate(
                                    data.keys.length,
                                    (index) {
                                      final item =
                                          items[index] as Map<String, dynamic>;
                                      final emoji = item['emoji'];
                                      final name = item['name'];
                                      final quantity = item['quantity'] ?? 0;
                                      return Card(
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(20),
                                          ),
                                        ),
                                        elevation: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          alignment: Alignment.center,
                                          // color: Colors.red,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text('$name x$quantity'),
                                              const SizedBox(height: 8),
                                              Text(
                                                emoji ?? '',
                                                style: const TextStyle(
                                                    fontSize: 48),
                                              ),
                                              const SizedBox(height: 8),
                                              AppButton(
                                                title: 'Use',
                                                onTap: () {
                                                  FirestoreAPI.useItem(item);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }),
                    ],
                  );
                }),
          ),
        );
      },
      error: (error, _) => Text(error.toString()),
      loading: () => const SizedBox(),
    );
  }
}

class StatsWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  const StatsWidget({Key? key, required this.title, required this.subtitle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .subtitle1
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.subtitle2,
        ),
      ],
    );
  }
}
