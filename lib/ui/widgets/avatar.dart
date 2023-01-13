import 'package:flutter/material.dart';
import 'package:socialgame/player.dart';

class Avatar extends StatelessWidget {
  final Player user;
  final double? radius;
  final double? fontSize;
  const Avatar({Key? key, required this.user, this.radius, this.fontSize})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Colors.grey,
      radius: radius ?? 48,
      child: Text(
        user.displayName[0].toUpperCase(),
        style:
            Theme.of(context).textTheme.headline4?.copyWith(fontSize: fontSize),
      ),
    );
  }
}
