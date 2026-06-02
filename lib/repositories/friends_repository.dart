import 'package:cloud_firestore/cloud_firestore.dart';

class FriendListItem {
  final String id;
  final String name;
  final String handle;
  final String avatarUrl;

  const FriendListItem({
    required this.id,
    required this.name,
    required this.handle,
    required this.avatarUrl,
  });

  factory FriendListItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendListItem(
      id: doc.id,
      name: data['name'] ?? '',
      handle: data['handle'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
    );
  }
}

class FriendRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all users who are NOT currently friends
  Future<List<FriendListItem>> fetchDiscoverableUsers(String currentUserId, List<String> currentFriends) async {
    final querySnapshot = await _firestore.collection('users').get();
    
    return querySnapshot.docs
        .where((doc) => doc.id != currentUserId && !currentFriends.contains(doc.id))
        .map((doc) => FriendListItem.fromFirestore(doc))
        .toList();
  }

  // Find incoming requests: users whose 'pending_invites' contains the current user's ID
  Future<List<FriendListItem>> fetchIncomingInvites(String currentUserId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .where('pending_invites', arrayContains: currentUserId)
        .get();

    return querySnapshot.docs.map((doc) => FriendListItem.fromFirestore(doc)).toList();
  }

  // Send a request: Add target user to current user's pending_invites list
  Future<void> sendFriendRequest(String currentUserId, String targetUserId) async {
    await _firestore.collection('users').doc(currentUserId).update({
      'pending_invites': FieldValue.arrayUnion([targetUserId])
    });
  }

  // Accept Request: Add each other to 'friends', remove from requestor's 'pending_invites'
  Future<void> acceptFriendRequest(String currentUserId, String requestorId) async {
    final batch = _firestore.batch();

    batch.update(_firestore.collection('users').doc(currentUserId), {
      'friends': FieldValue.arrayUnion([requestorId])
    });

    batch.update(_firestore.collection('users').doc(requestorId), {
      'friends': FieldValue.arrayUnion([currentUserId]),
      'pending_invites': FieldValue.arrayRemove([currentUserId])
    });

    await batch.commit();
  }

  // Decline Request: Just remove current user from requestor's pending list
  Future<void> declineFriendRequest(String currentUserId, String requestorId) async {
    await _firestore.collection('users').doc(requestorId).update({
      'pending_invites': FieldValue.arrayRemove([currentUserId])
    });
  }
}