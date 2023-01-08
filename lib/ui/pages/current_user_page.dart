import 'package:flutter/material.dart';
import 'package:socialgame/player.dart';
import 'package:socialgame/services/firestore.dart';

class CurrentUserPage extends StatelessWidget {
  final Player user;
  const CurrentUserPage(this.user, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          trailing: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.email),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            user.toMap().toString(),
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ),
        const Divider(),
        ListTile(
          title: MaterialButton(
            color: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            onPressed: () async => {
              FirestoreAPI.addCoins(
                user1: user,
                coins: await FirestoreAPI.getCoinRate(),
              )
            },
            child: const Text('⛏ Dig ⛏'),
          ),
        )
      ],
    );
  }
}
