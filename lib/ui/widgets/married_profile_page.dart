import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socialgame/player.dart';
import 'package:socialgame/services/auth.dart';
import 'package:socialgame/services/firestore.dart';
import 'package:socialgame/ui/widgets/base_app_bar.dart';
import 'package:socialgame/ui/widgets/dig_button.dart';

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
    final isOwner = widget.user.uid == FirebaseAuth.instance.currentUser?.uid;

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
            child: ListView(
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
                          style: Theme.of(context).textTheme.headline4,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.grey,
                        radius: 48,
                        child: Text(
                          spouse.displayName[0].toUpperCase(),
                          style: Theme.of(context).textTheme.headline4,
                        ),
                      ),
                    ],
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
                if (widget.user.uid != FirebaseAuth.instance.currentUser?.uid)
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
                if (widget.user.uid != FirebaseAuth.instance.currentUser?.uid)
                  ListTile(
                    title: Text(
                      'lick, slap, hug',
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.heart_broken),
                      onPressed: () async {
                        FirestoreAPI.divorce(
                            await AuthService.currentAppUser(), widget.user);
                      },
                    ),
                  ),
                const Divider(),
                if (widget.user.uid ==
                    FirebaseAuth.instance.currentUser?.uid) ...[
                  ListTile(
                    title: MaterialButton(
                      color: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      onPressed: () async {
                        FirestoreAPI.addCoins(
                          user1: widget.user,
                          user2: spouse,
                          coins: await FirestoreAPI.getCoinRate(),
                        );

                        FirestoreAPI.createDigSession(
                          widget.user,
                          [widget.user.uid, spouse.uid],
                        );
                      },
                      child: const Text('⛏ Dig ⛏'),
                    ),
                  ),
                  DigButton(widget.user),
                ],
              ],
            ),
          ),
        );
      },
      error: (e, _) => Text(e.toString()),
      loading: () => const CircularProgressIndicator(),
    );
  }
}
