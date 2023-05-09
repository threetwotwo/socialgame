import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:socialgame/player.dart';
import 'package:socialgame/services/firestore.dart';
import 'package:socialgame/ui/pages/profile_page.dart';
import 'package:socialgame/ui/widgets/base_app_bar.dart';
import 'package:socialgame/utils/timeago.dart';

class EventDetailPage extends StatelessWidget {
  static const routeName = '/event';
  const EventDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map;

    final createdAt = (args['created_at'] as Timestamp).toDate();
    final title = args['title'];
    final uid1 = args['user_1'];
    final uid2 = args['user_2'];

    return Scaffold(
      appBar: const BaseAppBar(
        title: 'event',
      ),
      body: ListView(
        children: [
          ListTile(title: Text(title)),
          ListTile(title: Text('${timeAgo(createdAt)} ago')),
          if (uid1 != null)
            ListTile(
              onTap: () => Navigator.of(context)
                  .pushNamed(ProfilePage.routeName, arguments: {'uid': uid1}),
              title: Text('user 1:'),
              subtitle: FutureBuilder<Player?>(
                  future: FirestoreAPI.getUser(uid1),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    if (user == null) return SizedBox();
                    return Text(user.displayName);
                  }),
            ),
          if (uid2 != null)
            FutureBuilder<Player?>(
              future: FirestoreAPI.getUser(uid2),
              builder: (context, snapshot) {
                final user = snapshot.data;
                if (user == null) return SizedBox();

                return ListTile(
                  onTap: () => Navigator.of(context).pushNamed(
                      ProfilePage.routeName,
                      arguments: {'uid': uid2}),
                  title: Text('user 2:'),
                  subtitle: Text(user.displayName),
                );
              },
            ),
        ],
      ),
    );
  }
}
