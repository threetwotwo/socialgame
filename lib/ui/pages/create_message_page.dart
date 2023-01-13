import 'package:flutter/material.dart';
import 'package:socialgame/player.dart';
import 'package:socialgame/services/auth.dart';
import 'package:socialgame/services/firestore.dart';
import 'package:socialgame/ui/widgets/base_app_bar.dart';

class CreateMessagePage extends StatefulWidget {
  final Player user;
  static const routeName = '/create_message';

  const CreateMessagePage({Key? key, required this.user}) : super(key: key);

  @override
  State<CreateMessagePage> createState() => _CreateMessagePageState();
}

class _CreateMessagePageState extends State<CreateMessagePage> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Player>(
      future: AuthService.currentAppUser(),
      builder: (context, snapshot) {
        final currentUser = snapshot.data;
        return Scaffold(
          appBar: BaseAppBar(
            title: 'Message',
            actions: [
              TextButton(
                onPressed: () {
                  if (currentUser == null) return;
                  FirestoreAPI.sendMessage(
                      currentUser, widget.user, controller.text);
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Send',
                  style: Theme.of(context).textTheme.button,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              ListTile(
                title: Text('Dear ${widget.user.displayName},'),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  // color: Colors.blue[100],
                  child: TextFormField(
                    controller: controller,
                    // maxLength: 365,
                    // textInputAction: TextInputAction.done,
                    minLines: 16,
                    maxLines: 88,

                    decoration: const InputDecoration(
                      hintText: 'What do you want to write?',
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListTile(
                    title:
                        Text('From,  \n${currentUser?.displayName ?? 'user'}')),
              ),
            ],
          ),
        );
      },
    );
  }
}
