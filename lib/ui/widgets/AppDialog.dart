import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AppDialog extends StatelessWidget {
  // final String title;
  const AppDialog({Key? key}) : super(key: key);

  static show(BuildContext context, String title) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          actions: [],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
