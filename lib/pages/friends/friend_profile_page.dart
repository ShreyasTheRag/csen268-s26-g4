import 'package:cloud_firestore/cloud_firestore.dart';
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
      // Listen to the specific friend's document using friendId
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(friendId).snapshots(),
        builder: (context, snapshot) {
          // Initialize fallback local values
          List tripsList = [];
          List friendsList = [];
          List locationsList = [];
          List equipmentImages = [];
          String displayName = name;
          String displayHandle = handle;
          String displayAvatar = avatarUrl;

          // If database data is successfully fetched, replace fallbacks with real database values
          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data()!;
            tripsList = userData['trips'] ?? [];
            friendsList = userData['friends'] ?? [];
            locationsList = userData['locations_visited'] ?? [];
            equipmentImages = userData['equipment_images'] ?? [];
            displayName = userData['name'] ?? name;
            displayHandle = userData['handle'] ?? handle;
            displayAvatar = userData['profile_image'] ?? avatarUrl;
          }

          return SingleChildScrollView(
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
                        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                        backgroundImage: displayAvatar.isNotEmpty ? NetworkImage(displayAvatar) : null,
                        child: displayAvatar.isEmpty
                            ? const Icon(Icons.person_outline, size: 40)
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(displayHandle),
                    ],
                  ),
                ),
                Triad(
                  keys: const ["Trips", "Friends", "Locations"],
                  values: [
                    tripsList.length.toString(),
                    friendsList.length.toString(),
                    locationsList.length.toString(),
                  ],
                ),
                _ListOfPersonalDetails(
                  type: "Trips",
                  items: tripsList,
                ),
                _ListOfPersonalDetails(
                  type: "Locations Visited",
                  items: locationsList,
                ),
                _ListOfPersonalDetails(
                  type: "Equipment Willing To Share",
                  items: equipmentImages,
                  isImage: true,
                ),
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
          );
        },
      ),
    );
  }
}

class _ListOfPersonalDetails extends StatelessWidget {
  final String type;
  final List items;
  final bool isImage;

  const _ListOfPersonalDetails({
    required this.type,
    required this.items,
    this.isImage = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8.0),
            Text("No $type added yet.", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 15.0,
              children: items.map((item) {
                return Container(
                  width: 80.0,
                  height: 80.0,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isImage
                      ? Image.network(
                          item.toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.broken_image, size: 30),
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Text(
                              item.toString(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}