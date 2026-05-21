import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Ensure Bloc is imported
import 'package:go_router/go_router.dart';
import 'package:santa_clara/blocs/authentication/bloc/authentication_bloc.dart';
import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';

enum _FriendsTab { viewFriends, findFriends }

class FriendListItem {
  const FriendListItem({
    required this.id,
    required this.name,
    required this.handle,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String handle;
  final String avatarUrl;
}

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  _FriendsTab _selectedTab = _FriendsTab.viewFriends;

  // Static mock states for invites - TODO: update
  final List<FriendListItem> _pendingInvites = <FriendListItem>[
    const FriendListItem(id: "p1", name: "Ashley Moore", handle: "@ashley", avatarUrl: ""),
    const FriendListItem(id: "p2", name: "Chris Taylor", handle: "@chris", avatarUrl: ""),
  ];

  final List<FriendListItem> _incomingInvites = <FriendListItem>[
    const FriendListItem(id: "i1", name: "Amanda Lewis", handle: "@amanda", avatarUrl: ""),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: const Text("Friends"),
        actions: const [
          LoggedInUserAvatar(userAvatarSize: UserAvatarSize.small),
        ],
      ),
      body: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        builder: (context, authState) {
          if (authState is! AuthenticationSignedInState) {
            return const Center(child: Text("Please sign in to view your friends."));
          }

          final String currentUserEmail = authState.user.email;

          // Get the current logged-in user document by email
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: currentUserEmail)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (userSnapshot.hasError || !userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text("User profile not found."));
              }

              final userData = userSnapshot.data!.docs.first.data();
              final List friendIds = userData['friends'] ?? [];

              if (friendIds.isEmpty) {
                return _buildLayout(context, <FriendListItem>[]);
              }

              // relational lookup
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where(FieldPath.documentId, whereIn: friendIds)
                    .snapshots(),
                builder: (context, profilesSnapshot) {
                  if (profilesSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final List<FriendListItem> dynamicFriendsList = [];

                  if (profilesSnapshot.hasData) {
                    for (var doc in profilesSnapshot.data!.docs) {
                      final data = doc.data();
                      final String? name = data['name'];
                      final String? handle = data['handle'];
                      final String? avatarUrl = data['profile_image'];

                      // Skip records with missing parameters
                      if (name != null && name.trim().isNotEmpty &&
                          handle != null && handle.trim().isNotEmpty) {
                        dynamicFriendsList.add(
                          FriendListItem(
                            id: doc.id,
                            name: name,
                            handle: handle,
                            avatarUrl: avatarUrl ?? "",
                          ),
                        );
                      }
                    }
                  }

                  return _buildLayout(context, dynamicFriendsList);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLayout(BuildContext context, List<FriendListItem> friendsList) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildTabButtons(context),
        const SizedBox(height: 12),
        Expanded(
          child: _selectedTab == _FriendsTab.viewFriends
              ? _buildViewFriendsList(friendsList)
              : _buildFindFriendsView(),
        ),
      ],
    );
  }

  Widget _buildTabButtons(BuildContext context) {
    final Color selectedColor = Theme.of(context).colorScheme.primary;
    final Color selectedTextColor = Theme.of(context).colorScheme.onPrimary;
    final Color unselectedColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final Color unselectedTextColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _selectedTab == _FriendsTab.viewFriends ? selectedColor : unselectedColor,
                  foregroundColor: _selectedTab == _FriendsTab.viewFriends ? selectedTextColor : unselectedTextColor,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                onPressed: () {
                  setState(() => _selectedTab = _FriendsTab.viewFriends);
                },
                child: const Text("View Friends"),
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 40,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _selectedTab == _FriendsTab.findFriends ? selectedColor : unselectedColor,
                  foregroundColor: _selectedTab == _FriendsTab.findFriends ? selectedTextColor : unselectedTextColor,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                onPressed: () {
                  setState(() => _selectedTab = _FriendsTab.findFriends);
                },
                child: const Text("Find Friends"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewFriendsList(List<FriendListItem> friendsList) {
    if (friendsList.isEmpty) {
      return const Center(
        child: Text("You haven't added any friends yet."),
      );
    }

    return ListView.builder(
      itemCount: friendsList.length,
      itemBuilder: (context, index) {
        return _FriendCard(
          friend: friendsList[index],
          onTap: () => _openFriendProfile(friendsList[index]),
        );
      },
    );
  }

  Widget _buildFindFriendsView() {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Text(
            "ADD FRIENDS",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28 / 1.75),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _SearchInput(),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Text(
            "PENDING INVITES",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28 / 1.75),
          ),
        ),
        for (final FriendListItem friend in _pendingInvites)
          _FriendCard(friend: friend, onTap: () => _openFriendProfile(friend)),
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Text(
            "ACCEPT/DECLINE INVITES",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28 / 1.75),
          ),
        ),
        for (final FriendListItem friend in _incomingInvites)
          _FriendCard(
            friend: friend,
            onTap: () => _openFriendProfile(friend),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionCircleButton(
                  icon: Icons.check,
                  onPressed: () => _acceptInvite(friend),
                ),
                const SizedBox(width: 10),
                _ActionCircleButton(
                  icon: Icons.close,
                  onPressed: () => _declineInvite(friend),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _openFriendProfile(FriendListItem friend) {
    context.goNamed(
      "friendProfile",
      pathParameters: {"friendId": friend.id},
      queryParameters: {
        "name": friend.name,
        "handle": friend.handle,
        "avatarUrl": friend.avatarUrl,
      },
    );
  }

  void _acceptInvite(FriendListItem friend) {
    setState(() {
      _incomingInvites.removeWhere((invite) => invite.id == friend.id);
      _selectedTab = _FriendsTab.viewFriends;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${friend.name} added to friends.")),
    );
  }

  void _declineInvite(FriendListItem friend) {
    setState(() {
      _incomingInvites.removeWhere((invite) => invite.id == friend.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Declined ${friend.name}'s friend request.")),
    );
  }
}

class _SearchInput extends StatelessWidget {
  const _SearchInput();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: "Search...",
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        prefixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.onTap,
    this.trailing,
  });

  final FriendListItem friend;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
            bottom: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              backgroundImage: friend.avatarUrl.isNotEmpty ? NetworkImage(friend.avatarUrl) : null,
              child: friend.avatarUrl.isEmpty ? const Icon(Icons.person_outline, size: 30) : null,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 28 / 1.75,
                    ),
                  ),
                  Text(
                    friend.handle,
                    style: const TextStyle(fontSize: 22 / 1.75),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _ActionCircleButton extends StatelessWidget {
  const _ActionCircleButton({
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
        ),
        onPressed: onPressed,
        child: Icon(icon, size: 22),
      ),
    );
  }
}