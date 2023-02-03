import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:socialgame/ui/widgets/base_app_bar.dart';

class EventDetailPage extends StatelessWidget {
  static const routeName = '/event';
  const EventDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map;

    final createdAt = args['created_at'];
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
          ListTile(title: Text(createdAt.toString())),
          if (uid1 != null) ListTile(title: Text(uid1)),
          if (uid2 != null) ListTile(title: Text(uid2)),
        ],
      ),
    );
  }
}
