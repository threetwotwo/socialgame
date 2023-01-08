import 'package:flutter/material.dart';
import 'package:socialgame/services/firestore.dart';
import 'package:socialgame/ui/widgets/base_app_bar.dart';

class CommandListPage extends StatelessWidget {
  static final routeName = '/commands';
  const CommandListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(
        title: 'Commands',
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: FirestoreAPI.getCommands(),
          builder: (context, snapshot) {
            final commands = snapshot.data ?? [];

            return ListView.builder(
              itemCount: commands.length,
              itemBuilder: (_, i) {
                final command = commands[i];
                final name = command['name'];
                final emoji = command['emoji'];
                final description = command['description'];
                return CommandListItem(
                  command: command,
                  title: name,
                  emoji: emoji,
                  description: description,
                );
              },
            );
            // return SafeArea(
            //   child: ListView(
            //     children: const [
            //       CommandListItem(
            //         title: 'hug',
            //         description: 'A gentle hug for a friend',
            //         emoji: '🫂',
            //       ),
            //       CommandListItem(
            //         title: 'lick',
            //         description: 'A playful lick',
            //         emoji: '👅',
            //       ),
            //     ],
            //   ),
            // );
          }),
    );
  }
}

class CommandListItem extends StatelessWidget {
  final String title;
  final String? description;
  final String? emoji;
  final Map<String, dynamic> command;

  const CommandListItem({
    Key? key,
    required this.command,
    required this.title,
    this.description,
    this.emoji,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minLeadingWidth: 0,
      isThreeLine: true,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyText1?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      subtitle: Text(description ?? ''),
      leading: Text(emoji ?? ''),
    );
  }
}
