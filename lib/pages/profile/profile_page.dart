import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:santa_clara/blocs/authentication/bloc/authentication_bloc.dart';
import 'package:santa_clara/navigation/my_routes.dart';
import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';
import 'package:santa_clara/widgets/triad.dart';
import 'package:shimmer/shimmer.dart';

class ProfilePage extends StatelessWidget {
  // Parameter has been completely removed
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: const Text("Profile"), 
        actions: const [
          LoggedInUserAvatar(userAvatarSize: UserAvatarSize.small)
        ],
      ),
      body: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        builder: (context, authState) {
          if (authState is! AuthenticationSignedInState) {
            return const Center(child: Text("Please sign in to view your profile."));
          }

          final String userEmail = authState.user.email;

          // Query by email first
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: userEmail)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _ProfileShimmerLoading();
              }

              if (snapshot.hasError) {
                return const Center(child: Text("Error loading profile."));
              }

              // Fallback Logic: If no user matches the email, switch to the default_user stream
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc('default_user')
                      .snapshots(),
                  builder: (context, defaultSnapshot) {
                    if (defaultSnapshot.connectionState == ConnectionState.waiting) {
                      return const _ProfileShimmerLoading();
                    }
                    if (defaultSnapshot.hasError || !defaultSnapshot.hasData || !defaultSnapshot.data!.exists) {
                      return const Center(child: Text("Profile data not found."));
                    }

                    final defaultData = defaultSnapshot.data!.data()!;
                    return _ProfileContent(userData: defaultData);
                  },
                );
              }

              // Normal Behavior: Found a matching email document
              final userData = snapshot.data!.docs.first.data();
              return _ProfileContent(userData: userData);
            },
          );
        },
      ),
    );
  }
}

/// Extracted content widget to handle the UI presentation cleanly
class _ProfileContent extends StatelessWidget {
  final Map<String, dynamic> userData;

  const _ProfileContent({required this.userData});

  @override
  Widget build(BuildContext context) {
    final List tripsList = userData['trips'] ?? [];
    final List friendsList = userData['friends'] ?? [];
    final List locationsList = userData['locations_visited'] ?? [];
    final List equipmentImages = userData['equipment_images'] ?? [];
    final String? profileImageUrl = userData['profile_image'];
    final String? userHandle = userData['handle'];

    return Padding(
      padding: const EdgeInsets.all(1.0),
      child: SingleChildScrollView(
        child: Column(
          spacing: 10.0,
          children: [
            SizedBox(
              width: double.infinity,
              height: 150,
              child: LoggedInUserAvatar(
                userAvatarSize: UserAvatarSize.large,
                imageUrl: profileImageUrl,
                userHandle: userHandle
              ),
            ),
            Triad(
              keys: const ["Trips", "Friends", "Locations"],
              values: [
                tripsList.length.toString(),
                friendsList.length.toString(),
                locationsList.length.toString(),
              ],
              onSecondTap: () =>
                  GoRouter.of(context).goNamed(MyRoutes.profileFriends.name),
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
            )
          ],
        ),
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

/// Shimmer Layout designed to mimic the exact layout constraints of the true profile page
class _ProfileShimmerLoading extends StatelessWidget {
  const _ProfileShimmerLoading();

  @override
  Widget build(BuildContext context) {
    final shimmerColor = Colors.grey[300]!;
    final highlightColor = Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: shimmerColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            spacing: 25.0,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(3, (index) => Container(
                  width: 80,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                )),
              ),
              ...List.generate(3, (index) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10.0,
                children: [
                  Container(width: 120, height: 16, color: Colors.white),
                  Row(
                    spacing: 15.0,
                    children: List.generate(4, (index) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    )),
                  )
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }
}