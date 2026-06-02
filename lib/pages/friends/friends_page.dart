import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:santa_clara/blocs/authentication/bloc/authentication_bloc.dart';
import 'package:santa_clara/repositories/friends_repository.dart';
import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';

enum _FriendsTab { viewFriends, findFriends }

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  _FriendsTab _selectedTab = _FriendsTab.viewFriends;

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

          // Step 1: Real-time listener for the logged-in user document
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

              final userDoc = userSnapshot.data!.docs.first;
              final String currentUserId = userDoc.id;
              final Map<String, dynamic> userData = userDoc.data();

              final List<dynamic> rawFriends = userData['friends'] ?? [];
              final List<dynamic> rawPendingInvites = userData['pending_invites'] ?? [];

              final List<String> friendIds = rawFriends.map((e) => e.toString()).toList();
              final List<String> pendingInvites = rawPendingInvites.map((e) => e.toString()).toList();

              // Step 2: Stream incoming requests (users where 'pending_invites' array contains currentUserId)
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('pending_invites', arrayContains: currentUserId)
                    .snapshots(),
                builder: (context, incomingSnapshot) {
                  if (incomingSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final List<FriendListItem> incomingList = [];
                  if (incomingSnapshot.hasData) {
                    for (var doc in incomingSnapshot.data!.docs) {
                      incomingList.add(_parseUserDoc(doc));
                    }
                  }

                  // Step 3: Stream global discovery users list (strangers who aren't friends yet)
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('users').snapshots(),
                    builder: (context, globalSnapshot) {
                      if (globalSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final List<FriendListItem> viewFriendsList = [];
                      final List<FriendListItem> discoverUsersList = [];
                      final List<FriendListItem> outgoingPendingList = [];

                      if (globalSnapshot.hasData) {
                        for (var doc in globalSnapshot.data!.docs) {
                          if (doc.id == currentUserId) continue; // Skip myself

                          final item = _parseUserDoc(doc);

                          if (friendIds.contains(doc.id)) {
                            viewFriendsList.add(item);
                          } else {
                            discoverUsersList.add(item);
                            if (pendingInvites.contains(doc.id)) {
                              outgoingPendingList.add(item);
                            }
                          }
                        }
                      }

                      return _buildLayout(
                        context: context,
                        currentUserId: currentUserId,
                        friendsList: viewFriendsList,
                        discoverList: discoverUsersList,
                        outgoingPendingList: outgoingPendingList,
                        incomingList: incomingList,
                        myPendingIds: pendingInvites,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  FriendListItem _parseUserDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return FriendListItem(
      id: doc.id,
      name: data['name'] ?? 'Unknown User',
      handle: data['handle'] ?? '@unknown',
      avatarUrl: data['profile_image'] ?? data['avatarUrl'] ?? '',
    );
  }

  Widget _buildLayout({
    required BuildContext context,
    required String currentUserId,
    required List<FriendListItem> friendsList,
    required List<FriendListItem> discoverList,
    required List<FriendListItem> outgoingPendingList,
    required List<FriendListItem> incomingList,
    required List<String> myPendingIds,
  }) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildTabButtons(context),
        const SizedBox(height: 12),
        Expanded(
          child: _selectedTab == _FriendsTab.viewFriends
              ? _buildViewFriendsList(friendsList)
              : _buildFindFriendsView(
                  context: context,
                  currentUserId: currentUserId,
                  discoverList: discoverList,
                  outgoingPendingList: outgoingPendingList,
                  incomingList: incomingList,
                  myPendingIds: myPendingIds,
                ),
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
                onPressed: () => setState(() => _selectedTab = _FriendsTab.viewFriends),
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
                onPressed: () => setState(() => _selectedTab = _FriendsTab.findFriends),
                child: const Text("Request"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewFriendsList(List<FriendListItem> friendsList) {
    if (friendsList.isEmpty) {
      return const Center(child: Text("You haven't added any friends yet."));
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

  Widget _buildFindFriendsView({
    required BuildContext context,
    required String currentUserId,
    required List<FriendListItem> discoverList,
    required List<FriendListItem> outgoingPendingList,
    required List<FriendListItem> incomingList,
    required List<String> myPendingIds,
  }) {
    const double singleCardHeight = 88.0; // Uniform card height bounding line limits

    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Text(
            "ADD FRIENDS",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28 / 1.75),
          ),
        ),

        Container(
          constraints: const BoxConstraints(
            maxHeight: singleCardHeight * 3,
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: Theme.of(context).colorScheme.outlineVariant, width: 0.5),
            ),
          ),
          child: discoverList.isEmpty
              ? const Center(child: Text("No new users to discover."))
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: discoverList.length,
                  itemExtent: singleCardHeight,
                  itemBuilder: (context, index) {
                    final targetUser = discoverList[index];
                    final bool isPending = myPendingIds.contains(targetUser.id);

                    return _FriendCard(
                      friend: targetUser,
                      onTap: () => _openFriendProfile(targetUser),
                      trailing: ElevatedButton(
                        onPressed: isPending
                            ? null
                            : () => _sendFriendRequest(currentUserId, targetUser),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPending ? Colors.grey : const Color(0xFF4A6B53),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: Text(
                          isPending ? 'PENDING' : 'Request',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  },
                ),
        ),

        if (outgoingPendingList.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Text(
              "PENDING INVITES",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28 / 1.75),
            ),
          ),
          for (final FriendListItem friend in outgoingPendingList)
            _FriendCard(friend: friend, onTap: () => _openFriendProfile(friend)),
        ],

        const Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
          child: Text(
            "ACCEPT/DECLINE INVITES",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28 / 1.75),
          ),
        ),
        if (incomingList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text("No incoming friend requests.", style: TextStyle(color: Colors.grey)),
          )
        else
          for (final FriendListItem friend in incomingList)
            _FriendCard(
              friend: friend,
              onTap: () => _openFriendProfile(friend),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionCircleButton(
                    icon: Icons.check,
                    onPressed: () => _acceptInvite(currentUserId, friend),
                  ),
                  const SizedBox(width: 10),
                  _ActionCircleButton(
                    icon: Icons.close,
                    onPressed: () => _declineInvite(currentUserId, friend),
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

  Future<void> _sendFriendRequest(String currentUserId, FriendListItem targetUser) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
        'pending_invites': FieldValue.arrayUnion([targetUser.id])
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Invite sent to ${targetUser.name}!")),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e);
    }
  }

  Future<void> _acceptInvite(String currentUserId, FriendListItem friend) async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final currentDocRef = FirebaseFirestore.instance.collection('users').doc(currentUserId);
      final requestorDocRef = FirebaseFirestore.instance.collection('users').doc(friend.id);

      // Add to each other's active friends fields
      batch.update(currentDocRef, {
        'friends': FieldValue.arrayUnion([friend.id])
      });
      batch.update(requestorDocRef, {
        'friends': FieldValue.arrayUnion([currentUserId]),
        'pending_invites': FieldValue.arrayRemove([currentUserId])
      });

      await batch.commit();

      setState(() => _selectedTab = _FriendsTab.viewFriends);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${friend.name} added to friends.")),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e);
    }
  }

  Future<void> _declineInvite(String currentUserId, FriendListItem friend) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(friend.id).update({
        'pending_invites': FieldValue.arrayRemove([currentUserId])
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Declined ${friend.name}'s friend request.")),
        );
      }
    } catch (e) {
      _showErrorSnackBar(e);
    }
  }

  void _showErrorSnackBar(dynamic error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Operation failed: $error")),
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
        height: 88, // Enforced explicit size mapping calculations
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 0.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              backgroundImage: friend.avatarUrl.isNotEmpty ? NetworkImage(friend.avatarUrl) : null,
              child: friend.avatarUrl.isEmpty ? const Icon(Icons.person_outline, size: 26) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    friend.handle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
      width: 38,
      height: 38,
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          padding: EdgeInsets.zero,
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        onPressed: onPressed,
        child: Icon(icon, size: 20),
      ),
    );
  }
}