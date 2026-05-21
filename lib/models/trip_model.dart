import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String name;
  final List<String> attendees;
  final int completed; // 0 for false, 1 for true based on DB image
  final DateTime startDate;
  final DateTime endDate;
  final List<String> images;
  final List<String> suppliesImages;
  final String notes;

  Trip({
    required this.id,
    required this.name,
    required this.attendees,
    required this.completed,
    required this.startDate,
    required this.endDate,
    required this.images,
    required this.suppliesImages,
    required this.notes,
  });

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      name: data['trip_name'] ?? '',
      attendees: List<String>.from(data['attendees'] ?? []),
      completed: data['completed'] ?? 0,
      startDate: (data['start_date'] as Timestamp).toDate(),
      endDate: (data['end_date'] as Timestamp).toDate(),
      images: List<String>.from(data['images'] ?? []),
      suppliesImages: List<String>.from(data['supplies_images'] ?? []),
      notes: data['notes'] ?? '',
    );
  }
}