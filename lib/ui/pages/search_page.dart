import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:socialgame/player.dart';
import 'package:socialgame/services/firestore.dart';
import 'package:socialgame/ui/pages/profile_page.dart';
import 'package:socialgame/ui/widgets/base_app_bar.dart';

class SearchPage extends StatelessWidget {
  static const routeName = '/search';
  const SearchPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BaseAppBar(
        title: 'Search',
      ),
      body: FutureBuilder<List<Player>>(
          future: FirestoreAPI.getUsers(),
          builder: (context, snapshot) {
            final users = snapshot.data ?? [];

            return ListView.builder(
              itemBuilder: (_, i) {
                final user = users[i];
                return ListTile(
                  onTap: () => Navigator.of(context).pushNamed(
                      ProfilePage.routeName,
                      arguments: {'uid': user.uid}),
                  title: Text(user.displayName),
                );
              },
              itemCount: users.length,
            );
          }),
    );
  }
}
