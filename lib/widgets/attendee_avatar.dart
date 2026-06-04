import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendeeAvatar extends StatelessWidget {
  final String userId;
  final VoidCallback onTap;

  const AttendeeAvatar({
    super.key,
    required this.userId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String? profileImageUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          final rawUrl = data?['profile_image']?.toString().trim();
          if (rawUrl != null && rawUrl.isNotEmpty) {
            profileImageUrl = rawUrl;
          }
        }

        // Default Icon Fallback Style
        final Widget fallbackIcon = Icon(
          Icons.account_circle,
          size: 40,
          color: theme.colorScheme.onSurfaceVariant,
        );

        return Tooltip(
          message: userId,
          child: GestureDetector(
            onTap: onTap,
            child: CircleAvatar(
              radius: 18, 
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              // 💡 FIX: clipBehavior removed from CircleAvatar. ClipOval handles the clipping instead.
              child: profileImageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        profileImageUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => fallbackIcon,
                      ),
                    )
                  : fallbackIcon,
            ),
          ),
        );
      },
    );
  }
}