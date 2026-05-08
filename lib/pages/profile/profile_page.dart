import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        drawer: const MainDrawer(),
        appBar: AppBar(title: const Text("Profile"), actions: const [
          LoggedInUserAvatar(
            userAvatarSize: UserAvatarSize.small,
          )
        ]),
        body: const Center(child: Text("Profile")));
  }
}
