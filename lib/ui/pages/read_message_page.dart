import 'package:flutter/material.dart';
import 'package:socialgame/ui/widgets/base_app_bar.dart';

class ReadMessagePage extends StatelessWidget {
  static const routeName = '/read_message';

  const ReadMessagePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map;

    print('ReadMessagePage.build $args');

    final sender = args['sender'] ?? {};
    final recipient = args['recipient'] ?? {};

    return Scaffold(
      appBar: BaseAppBar(
        title: 'Message',
      ),
      body: Column(
        // crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            title: Text('Dear ${recipient['display_name'] ?? ''},'),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              // color: Colors.blue[100],
              child: Text(
                // maxLength: 365,
                // textInputAction: TextInputAction.done,
                args['message'],
                maxLines: 88,
                textAlign: TextAlign.start,
                // decoration: const InputDecoration(
                //   hintText: 'What do you want to write?',
                // ),
              ),
            ),
          ),
          Expanded(
            child: ListTile(
                title: Text('From,\n${sender['display_name'] ?? 'user'}')),
          ),
        ],
      ),
    );
  }
}
