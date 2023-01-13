import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:socialgame/player.dart';
import 'package:socialgame/services/firestore.dart';
import 'package:socialgame/ui/pages/read_message_page.dart';
import 'package:socialgame/ui/widgets/avatar.dart';
import 'package:socialgame/ui/widgets/base_app_bar.dart';

class MessagesPage extends StatelessWidget {
  static final routeName = '/messages';
  const MessagesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(title: 'Messages'),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirestoreAPI.getMessagesForRecipient(
            FirebaseAuth.instance.currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          final messages = snapshot.data ?? [];
          return messages.isEmpty
              ? Center(child: Text('No messages'))
              : ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final message = messages[i];
                    final Map<String, dynamic> sender = message['sender'];

                    return ListTile(
                      minLeadingWidth: 0,
                      onTap: () => Navigator.of(context).pushNamed(
                        ReadMessagePage.routeName,
                        arguments: message,
                      ),
                      leading: Avatar(
                        radius: 18,
                        fontSize: 18,
                        user: Player.fromJson(sender),
                      ),
                      title: Text(sender['display_name']),
                      subtitle: Text(
                        message['message'],
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                );
        },
      ),
      // body: ListView(
      //   children: [
      //     ListTile(
      //       // leading: Avatar(user:  AuthService.currentAppUser(),),
      //       title: Text('Jen'),
      //       subtitle: Text(
      //         'This is the message body' * 9,
      //         maxLines: 1,
      //         overflow: TextOverflow.ellipsis,
      //       ),
      //     ),
      //     ListTile(
      //       title: Text('Bob'),
      //       subtitle: Text('Hi, will you marry me?'),
      //     ),
      //   ],
      // ),
    );
  }
}
