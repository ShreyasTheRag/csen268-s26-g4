import 'package:go_router/go_router.dart';
import 'package:santa_clara/navigation/my_routes.dart';
import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';
import 'package:flutter/material.dart';
import 'package:santa_clara/widgets/triad.dart';

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
        body: Padding(
          padding: const EdgeInsets.all(1.0),
          child: SingleChildScrollView(
            child: Column(
              spacing: 10.0,
              children: [
                const SizedBox(
                  width: double.infinity,
                  height: 150,
                  child: LoggedInUserAvatar(
                    userAvatarSize: UserAvatarSize.large,
                  ),
                ),
                Triad(
                  keys: const ["Trips", "Friends", "Locations"],
                  values: const ['0', '1', '2'],
                  onSecondTap: () =>
                      GoRouter.of(context).goNamed(MyRoutes.profileFriends.name),
                ),
                const _ListOfPersonalDetails(type: "Trips"),
                const _ListOfPersonalDetails(type: "Locations Visited"),
                const _ListOfPersonalDetails(
                    type: "Equipement Willing To Share")
              ]
            )
          )
        )
      );
  }
}

class _ListOfPersonalDetails extends StatelessWidget {
  final String type;

  const _ListOfPersonalDetails({required this.type});

  @override
  Widget build(BuildContext context) {
    Container c = Container(
      width: 80.0,
      height: 80.0,
      color: Theme.of(context).colorScheme.primaryContainer
    );
    return Padding(
      padding: const EdgeInsetsGeometry.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 15.0,
              children: [c, c, c, c],
            )
          )
        ]
      )
    );
  }
}