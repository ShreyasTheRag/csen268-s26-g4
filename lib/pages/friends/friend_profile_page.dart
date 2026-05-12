import 'package:flutter/material.dart';
import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';
import 'package:santa_clara/widgets/triad.dart';

class FriendProfilePage extends StatelessWidget {
  const FriendProfilePage({
    required this.friendId,
    required this.name,
    required this.handle,
    required this.avatarUrl,
    super.key,
  });

  final String friendId;
  final String name;
  final String handle;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: const Text("Profile"),
        actions: const [
          LoggedInUserAvatar(userAvatarSize: UserAvatarSize.small),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(1.0),
        child: Column(
          spacing: 10.0,
          children: [
            SizedBox(
              width: double.infinity,
              height: 150,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHigh,
                    backgroundImage:
                        avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? const Icon(Icons.person_outline, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 6),
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(handle),
                ],
              ),
            ),
            const Triad(
              keys: ["Trips", "Friends", "Locations"],
              values: ['4', '12', '9'],
              width: 100,
              height: 60,
            ),
            const _ListOfPersonalDetails(type: "Trips"),
            const _ListOfPersonalDetails(type: "Locations Visited"),
            const _ListOfPersonalDetails(type: "Equipement Willing To Share"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Friend ID: $friendId",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            )
          ],
        ),
      ),
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
        color: Theme.of(context).colorScheme.primaryContainer);
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
              ))
        ],
      ),
    );
  }
}
