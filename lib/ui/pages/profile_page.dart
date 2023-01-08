import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socialgame/services/auth.dart';
import 'package:socialgame/services/firestore.dart';
import 'package:socialgame/ui/widgets/base_app_bar.dart';
import 'package:socialgame/ui/widgets/dig_button.dart';
import 'package:socialgame/ui/widgets/married_profile_page.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);
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
    final arguments = ModalRoute.of(context)?.settings.arguments as Map;
    final uid = arguments['uid'];

    final userAsyncValue = ref.watch(AuthService.appUserStreamProvider(uid));

    final isOwner = uid == FirebaseAuth.instance.currentUser?.uid;

    return userAsyncValue.when(
      data: (user) {
        if (user == null) return const SizedBox();

        final isMarried = user.marriedTo != null;

        return Scaffold(
          appBar: BaseAppBar(
            title: user.displayName,
          ),
          body: SafeArea(
            child: isMarried
                ? MarriedProfilePage(user: user)
                : ListView(
                    children: [
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
                                  title: 'Friends',
                                  subtitle: '0',
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
                                  );
                                },
                              ),
                            ),
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
                              // FirestoreAPI.marry(
                              //     await AuthService.currentAppUser(), user);
                            },
                          ),
                        ),
                      if (isOwner) DigButton(user),
                      ListTile(),
                      ListTile(
                        title: Text('Inventory'),
                      ),
                    ],
                  ),
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

String timeAgo(DateTime date) {
  final duration = DateTime.now().difference(date);

  if (duration.inSeconds <= 0) {
    return 'just now';
  }
  if (duration.inMinutes <= 0) {
    return '${duration.inSeconds} seconds';
  }
  if (duration.inHours <= 0) {
    return '${duration.inMinutes} minutes';
  }
  if (duration.inDays <= 0) {
    return '${duration.inHours} hours';
  }
  if (duration.inDays < 30) {
    return '${duration.inDays} days';
  }
  if (duration.inDays < 365) {
    final months = duration.inDays / 30;
    return '${months.floor()} months';
  }

  final years = duration.inDays / 365;
  return '${years.floor()} years';
}
