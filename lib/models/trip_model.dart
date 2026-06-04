import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String name;
  final List<String> attendees;
  final int completed;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> images;
  final List<String> suppliesImages;
  final String notes;
  final List<String> locations;

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
    required this.locations,
  });

  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      name: data['trip_name'] ?? '',
      attendees: List<String>.from(data['attendees'] ?? []),
      completed: (data['completed'] as num?)?.toInt() ?? 0,
      startDate: (data['start_date'] as Timestamp).toDate(),
      endDate: (data['end_date'] as Timestamp).toDate(),
      images: List<String>.from(data['images'] ?? []),
      suppliesImages: List<String>.from(data['supplies_images'] ?? []),
      notes: data['notes'] ?? '',
      locations: List<String>.from(data['locations'] ?? []),
    );
  }

  Trip copyWith({
      String? id,
      String? name,
      int? completed,
      List<String>? locations,
      DateTime? startDate,
      DateTime? endDate,
      List<String>? attendees,
      String? notes,
      List<String>? images,
      List<String>? suppliesImages,
    }) {
      return Trip(
        id: id ?? this.id,
        name: name ?? this.name,
        locations: locations ?? this.locations,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        attendees: attendees ?? this.attendees,
        notes: notes ?? this.notes,
        images: images ?? this.images,
        suppliesImages: suppliesImages ?? this.suppliesImages,
        completed: completed ?? 0,
      );
    }
}