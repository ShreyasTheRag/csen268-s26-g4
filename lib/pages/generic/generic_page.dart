import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';
import 'package:flutter/material.dart';

class GenericPage extends StatelessWidget {
  const GenericPage({super.key, required this.title, this.body});
  final String title;
  final Widget? body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: const [
        LoggedInUserAvatar(
          userAvatarSize: UserAvatarSize.small,
        )
      ]),
      body: Center(
        child: body ?? Text(title),
      ),
      drawer: const MainDrawer(),
    );
  }
}
