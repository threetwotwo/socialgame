import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socialgame/player.dart';
import 'package:socialgame/services/auth.dart';
import 'package:socialgame/services/firestore.dart';
import 'package:socialgame/ui/pages/create_message_page.dart';
import 'package:socialgame/ui/pages/profile_page.dart';
import 'package:socialgame/ui/widgets/app_button.dart';
import 'package:socialgame/ui/widgets/base_app_bar.dart';
import 'package:socialgame/ui/widgets/dig_button.dart';
import 'package:socialgame/utils/timeago.dart';

class MarriedProfilePage extends ConsumerStatefulWidget {
  final Player user;
  const MarriedProfilePage({Key? key, required this.user}) : super(key: key);

  @override
  ConsumerState<MarriedProfilePage> createState() => _MarriedProfilePageState();
}

class _MarriedProfilePageState extends ConsumerState<MarriedProfilePage> {
  late final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // final isOwner = widget.user.uid == FirebaseAuth.instance.currentUser?.uid;

    final spouseAsyncValue =
        ref.watch(AuthService.appUserStreamProvider(widget.user.marriedTo!));
    return spouseAsyncValue.when(
      data: (spouse) {
        if (spouse == null) return const SizedBox();
        return Scaffold(
          appBar: BaseAppBar(
            title: '${widget.user.displayName} & ${spouse.displayName}',
          ),
          body: SafeArea(
            child: StreamBuilder<Map<String, dynamic>>(
                stream: FirestoreAPI.userStatsStream(widget.user.uid),
                builder: (context, snapshot) {
                  final stats1 = snapshot.data ?? {};
                  final coins1 = stats1['coins'] ?? 0;

                  return StreamBuilder<Map<String, dynamic>>(
                      stream: FirestoreAPI.userStatsStream(spouse.uid),
                      builder: (context, snapshot) {
                        final stats2 = snapshot.data ?? {};
                        final coins2 = stats2['coins'] ?? 0;

                        return ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.grey,
                                    radius: 48,
                                    child: Text(
                                      widget.user.displayName[0].toUpperCase(),
                                      style:
                                          Theme.of(context).textTheme.headline4,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    backgroundColor: Colors.grey,
                                    radius: 48,
                                    child: Text(
                                      spouse.displayName[0].toUpperCase(),
                                      style:
                                          Theme.of(context).textTheme.headline4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                StatsWidget(
                                    title: 'Coins',
                                    subtitle: (coins1 + coins2).toString()),
                                if (spouse.marriedAt != null)
                                  StatsWidget(
                                      title: 'Married for',
                                      subtitle: timeAgo(spouse.marriedAt!)),
                              ],
                            ),
                            ListTile(
                              title: AppButton(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CreateMessagePage(user: widget.user),
                                    ),
                                  );
                                },
                                title: 'Message',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                widget.user.toMap().toString(),
                                style: Theme.of(context).textTheme.bodyText1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                spouse.toMap().toString(),
                                style: Theme.of(context).textTheme.bodyText1,
                              ),
                            ),
                            if (widget.user.uid !=
                                FirebaseAuth.instance.currentUser?.uid)
                              ListTile(
                                title: TextFormField(
                                  controller: textController,
                                  decoration: InputDecoration(
                                    label: const Text('Commands'),
                                    hintText: 'What do you want to do?',
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.send),
                                      onPressed: () async {
                                        final text = textController.text;
                                        FirestoreAPI.addPlayerCommand(
                                          await AuthService.currentAppUser(),
                                          widget.user,
                                          text,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            if (widget.user.uid !=
                                FirebaseAuth.instance.currentUser?.uid)
                              ListTile(
                                title: Text(
                                  'lick, slap, hug',
                                  style: Theme.of(context).textTheme.bodyText1,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.heart_broken),
                                  onPressed: () async {
                                    FirestoreAPI.divorce(
                                        await AuthService.currentAppUser(),
                                        widget.user);
                                  },
                                ),
                              ),
                            const Divider(),
                            if (widget.user.uid ==
                                FirebaseAuth.instance.currentUser?.uid) ...[
                              DigButton(widget.user),
                              ListTile(
                                title: Text('Marry'),
                                onTap: () async {
                                  final currentUser =
                                      await AuthService.currentAppUser();
                                  widget.user.marriedTo == null
                                      ? FirestoreAPI.marry(currentUser, spouse)
                                      : FirestoreAPI.divorce(
                                          currentUser, spouse);
                                },
                              ),
                            ],
                          ],
                        );
                      });
                }),
          ),
        );
      },
      error: (e, _) => Text(e.toString()),
      loading: () => const CircularProgressIndicator(),
    );
  }
}
