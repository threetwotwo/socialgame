import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socialgame/player.dart';
import 'package:socialgame/services/firestore.dart';
import 'package:socialgame/ui/widgets/AppDialog.dart';

///Button for digging for coins
///1. creates a dig session (cannot create if one already exists)
///2. upon expiration, user can collect coins
class DigButton extends ConsumerWidget {
  final Player user;
  const DigButton(this.user, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final digSessionStream =
        ref.watch(FirestoreAPI.digSessionStreamProvider(user.uid));
    return digSessionStream.when(
      data: (value) {
        final session = value;
        print('hello!!! $session');
        final DateTime? endTime =
            (session?['end_time'] ?? Timestamp.now()).toDate();
        //if session is null, player can dig
        final coins = session?['coins'] ?? 0;

        return ListTile(
          title: MaterialButton(
            color: Colors.deepPurpleAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            onPressed: () async {
              if (session == null) {
                FirestoreAPI.createDigSession(user, [user.uid]);
              } else {
                if (endTime!.millisecondsSinceEpoch <
                    DateTime.now().millisecondsSinceEpoch) {
                  FirestoreAPI.completeDigSession(user, session).then(
                      (_) => AppDialog.show(context, 'Got $coins coin(s)!'));
                }
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('⛏'),
                ),
                session == null
                    ? const Text('Dig for coins')
                    : CountdownTimer(
                        endTime: endTime?.millisecondsSinceEpoch,
                        endWidget: const Text('Collect coins'),
                      ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('⛏'),
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

class BakeButton extends ConsumerWidget {
  final Player user;
  const BakeButton(this.user, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final digSessionStream =
        ref.watch(FirestoreAPI.bakeSessionStreamProvider(user.uid));
    return digSessionStream.when(
      data: (value) {
        final session = value;
        print('BakeButton!!! $session');
        final DateTime? endTime =
            (session?['end_time'] ?? Timestamp.now()).toDate();
        //if session is null, player can dig
        final cookies = session?['cookies'] ?? 0;

        return ListTile(
          title: MaterialButton(
            color: Colors.deepPurpleAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            onPressed: () async {
              if (session == null) {
                FirestoreAPI.bakeCookie();
              } else {
                if (endTime!.millisecondsSinceEpoch <
                    DateTime.now().millisecondsSinceEpoch) {
                  FirestoreAPI.completeBakeSession(user, session).then((_) =>
                      AppDialog.show(context, 'Got $cookies cookie(s)!'));
                }
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('🍪'),
                ),
                session == null
                    ? const Text('Bake cookies')
                    : CountdownTimer(
                        endTime: endTime?.millisecondsSinceEpoch,
                        endWidget: const Text('Collect cookies'),
                      ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('🍪'),
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
