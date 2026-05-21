import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:santa_clara/models/trip_model.dart';

class TripRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getUserIdByEmail(String email) async {
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isEmpty) throw Exception('User not found');
    return query.docs.first.id;
  }

  Future<List<Trip>> fetchActiveTrips(String userId) async {
    final query = await _firestore
        .collection('trips')
        .where('attendees', arrayContains: userId) // <-- This looks inside the array field directly!
        .where('completed', isEqualTo: 0)
        .get();

    return query.docs.map((doc) => Trip.fromFirestore(doc)).toList();
  }

  Future<void> updateTripDate(String tripId, {required DateTime date, required bool isStart}) async {
    final field = isStart ? 'start_date' : 'end_date';
    await _firestore.collection('trips').doc(tripId).update({
      field: Timestamp.fromDate(date),
    });
  }

  Future<void> completeTrip(String tripId) async {
    await _firestore.collection('trips').doc(tripId).update({'completed': 1});
  }

  Future<void> deleteTrip(String tripId) async {
    await _firestore.collection('trips').doc(tripId).delete();
  }

  Future<Trip> createNewTrip(String tripName, String userId) async {
    final Map<String, dynamic> newTripData = {
      'trip_name': tripName,
      'attendees': [userId],
      'completed': 0,
      'start_date': Timestamp.fromDate(DateTime.now()),
      'end_date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
      'images': [],
      'supplies_images': [],
      'notes': '',
    };

    final docRef = await _firestore.collection('trips').add(newTripData);
    
    return Trip(
      id: docRef.id,
      name: tripName,
      attendees: [userId],
      completed: 0,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 3)),
      images: [],
      suppliesImages: [],
      notes: '',
    );
  }
}