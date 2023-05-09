import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:socialgame/player.dart';
import 'package:socialgame/services/firestore.dart';
import 'package:socialgame/ui/pages/profile_page.dart';
import 'package:socialgame/ui/widgets/avatar.dart';
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
      body: Column(
        children: [
          ListTile(
            title: SearchTextField(
              fieldValue: (String value) {},
            ),
          ),
          ListTile(
            title: Text('Friends'),
          ),
          Expanded(
            child: FutureBuilder<List<Player>>(
                future: FirestoreAPI.getFriends(),
                builder: (context, snapshot) {
                  final friends = snapshot.data ?? [];

                  return ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (_, i) {
                      print('@@@SearchPage.build $friends');
                      final friend = friends[i];
                      return ListTile(
                        onTap: () => Navigator.of(context).pushNamed(
                          ProfilePage.routeName,
                          arguments: {'uid': friend.uid},
                        ),
                        minLeadingWidth: 0,
                        leading: Avatar(
                          user: friend,
                          radius: 16,
                          fontSize: 16,
                        ),
                        title: Text(friend.displayName),
                      );
                    },
                    itemCount: friends.length,
                  );
                }),
          ),
          // ListTile(
          //   title: Text('People'),
          // ),
          // Expanded(
          //   child: ListView.builder(
          //     itemBuilder: (_, i) {
          //       final user = users[i];
          //       return ListTile(
          //         onTap: () => Navigator.of(context).pushNamed(
          //             ProfilePage.routeName,
          //             arguments: {'uid': user.uid}),
          //         title: Text(user.displayName),
          //       );
          //     },
          //     itemCount: users.length,
          //   ),
          // ),
        ],
      ),
    );
  }
}

class SearchTextField extends StatelessWidget {
  const SearchTextField({
    super.key,
    required this.fieldValue,
  });

  final ValueChanged<String> fieldValue;

  @override
  Widget build(BuildContext context) {
    return CupertinoSearchTextField(
      onChanged: (String value) {
        fieldValue('The text has changed to: $value');
      },
      onSubmitted: (String value) {
        fieldValue('Submitted text: $value');
      },
    );
  }
}
