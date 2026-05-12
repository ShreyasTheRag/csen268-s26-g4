import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  final List<FriendListItem> _friends = <FriendListItem>[
    const FriendListItem(
      id: "f1",
      name: "John Smith",
      handle: "@john",
      avatarUrl: "",
    ),
    const FriendListItem(
      id: "f2",
      name: "Emily Davis",
      handle: "@emily",
      avatarUrl: "",
    ),
    const FriendListItem(
      id: "f3",
      name: "Michael Brown",
      handle: "@michael",
      avatarUrl: "",
    ),
    const FriendListItem(
      id: "f4",
      name: "Sarah Wilson",
      handle: "@sarah",
      avatarUrl: "",
    ),
    const FriendListItem(
      id: "f5",
      name: "David Lee",
      handle: "@david",
      avatarUrl: "",
    ),
  ];

  final List<FriendListItem> _pendingInvites = <FriendListItem>[
    const FriendListItem(
      id: "p1",
      name: "Ashley Moore",
      handle: "@ashley",
      avatarUrl: "",
    ),
    const FriendListItem(
      id: "p2",
      name: "Chris Taylor",
      handle: "@chris",
      avatarUrl: "",
    ),
    const FriendListItem(
      id: "p3",
      name: "Jessica Martin",
      handle: "@jessica",
      avatarUrl: "",
    ),
    const FriendListItem(
      id: "p4",
      name: "Ryan Clark",
      handle: "@ryan",
      avatarUrl: "",
    ),
  ];

  final List<FriendListItem> _incomingInvites = <FriendListItem>[
    const FriendListItem(
      id: "i1",
      name: "Amanda Lewis",
      handle: "@amanda",
      avatarUrl: "",
    ),
    const FriendListItem(
      id: "i2",
      name: "Brian Walker",
      handle: "@brian",
      avatarUrl: "",
    ),
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
      body: Column(
        children: [
          const SizedBox(height: 16),
          _buildTabButtons(context),
          const SizedBox(height: 12),
          Expanded(
            child: _selectedTab == _FriendsTab.viewFriends
                ? _buildViewFriendsList()
                : _buildFindFriendsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButtons(BuildContext context) {
    final Color selectedColor = Theme.of(context).colorScheme.primary;
    final Color selectedTextColor = Theme.of(context).colorScheme.onPrimary;
    final Color unselectedColor =
        Theme.of(context).colorScheme.surfaceContainerHighest;
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
                  backgroundColor: _selectedTab == _FriendsTab.viewFriends
                      ? selectedColor
                      : unselectedColor,
                  foregroundColor: _selectedTab == _FriendsTab.viewFriends
                      ? selectedTextColor
                      : unselectedTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
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
                  backgroundColor: _selectedTab == _FriendsTab.findFriends
                      ? selectedColor
                      : unselectedColor,
                  foregroundColor: _selectedTab == _FriendsTab.findFriends
                      ? selectedTextColor
                      : unselectedTextColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
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

  Widget _buildViewFriendsList() {
    return ListView.builder(
      itemCount: _friends.length,
      itemBuilder: (context, index) {
        return _FriendCard(
          friend: _friends[index],
          onTap: () => _openFriendProfile(_friends[index]),
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
      _friends.insert(0, friend);
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
            bottom:
                BorderSide(color: Theme.of(context).colorScheme.primary, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
              backgroundImage: friend.avatarUrl.isNotEmpty
                  ? NetworkImage(friend.avatarUrl)
                  : null,
              child: friend.avatarUrl.isEmpty
                  ? const Icon(Icons.person_outline, size: 30)
                  : null,
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
