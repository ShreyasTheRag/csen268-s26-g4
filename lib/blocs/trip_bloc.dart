import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:santa_clara/models/trip_model.dart';
import 'package:santa_clara/repositories/trip_repository.dart';

// Events
abstract class TripEvent {}

class LoadUserTrips extends TripEvent {
  final String email;
  LoadUserTrips(this.email);
}

class SelectTrip extends TripEvent {
  final Trip selectedTrip;
  SelectTrip(this.selectedTrip);
}

class UpdateTripDateEvent extends TripEvent {
  final DateTime date;
  final bool isStart;
  UpdateTripDateEvent({required this.date, required this.isStart});
}

class FinishTripEvent extends TripEvent {}
class DeleteTripEvent extends TripEvent {}

class CreateNewTripEvent extends TripEvent {
  final String name;
  CreateNewTripEvent(this.name);
}

class UpdateTripNotesEvent extends TripEvent {
  final String notes;
  UpdateTripNotesEvent(this.notes);
}

class AddLocationToTripEvent extends TripEvent {
  final String locationName;
  AddLocationToTripEvent({required this.locationName});
}

class UpdateTripLocationsEvent extends TripEvent {
  final String tripId;
  final String locationName;

  UpdateTripLocationsEvent({
    required this.tripId,
    required this.locationName,
  });

  List<Object?> get props => [tripId, locationName];
}

// States
enum TripStatus { initial, loading, loaded, successAction, failure }

class TripState {
  final TripStatus status;
  final List<Trip> allTrips;
  final Trip? selectedTrip;
  final String? currentUserId;
  final String? errorMessage;

  TripState({
    this.status = TripStatus.initial,
    this.allTrips = const [],
    this.selectedTrip,
    this.currentUserId,
    this.errorMessage,
  });

  TripState copyWith({
    TripStatus? status,
    List<Trip>? allTrips,
    Trip? selectedTrip,
    String? currentUserId,
    String? errorMessage,
  }) {
    return TripState(
      status: status ?? this.status,
      allTrips: allTrips ?? this.allTrips,
      selectedTrip: selectedTrip ?? this.selectedTrip,
      currentUserId: currentUserId ?? this.currentUserId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Bloc
class TripBloc extends Bloc<TripEvent, TripState> {
  final TripRepository _repository = TripRepository();

  TripBloc() : super(TripState()) {
    on<LoadUserTrips>((event, emit) async {
      emit(state.copyWith(status: TripStatus.loading));
      try {
        final userId = await _repository.getUserIdByEmail(event.email);
        final trips = await _repository.fetchActiveTrips(userId);
        emit(state.copyWith(
          status: TripStatus.loaded,
          allTrips: trips,
          selectedTrip: trips.isNotEmpty ? trips.first : null,
          currentUserId: userId,
        ));
      } catch (e) {
        emit(state.copyWith(status: TripStatus.failure, errorMessage: e.toString()));
      }
    });

    on<SelectTrip>((event, emit) {
      emit(state.copyWith(selectedTrip: event.selectedTrip));
    });

    on<UpdateTripDateEvent>((event, emit) async {
      if (state.selectedTrip == null) return;
      try {
        await _repository.updateTripDate(
          state.selectedTrip!.id,
          date: event.date,
          isStart: event.isStart,
        );
        // Refresh local list state
        final updatedTrips = state.allTrips.map((t) {
          if (t.id == state.selectedTrip!.id) {
            return Trip(
              id: t.id, name: t.name, attendees: t.attendees, completed: t.completed,
              startDate: event.isStart ? event.date : t.startDate,
              endDate: event.isStart ? t.endDate : event.date,
              images: t.images, suppliesImages: t.suppliesImages, notes: t.notes, locations: t.locations,
            );
          }
          return t;
        }).toList();

        emit(state.copyWith(
          allTrips: updatedTrips,
          selectedTrip: updatedTrips.firstWhere((t) => t.id == state.selectedTrip!.id),
        ));
      } catch (e) {
        emit(state.copyWith(status: TripStatus.failure, errorMessage: e.toString()));
      }
    });

    on<FinishTripEvent>((event, emit) async {
      if (state.selectedTrip == null) return;
      try {
        await _repository.completeTrip(state.selectedTrip!.id);
        emit(state.copyWith(status: TripStatus.successAction));
      } catch (e) {
        emit(state.copyWith(status: TripStatus.failure, errorMessage: e.toString()));
      }
    });

    on<DeleteTripEvent>((event, emit) async {
      if (state.selectedTrip == null) return;
      try {
        await _repository.deleteTrip(state.selectedTrip!.id);
        emit(state.copyWith(status: TripStatus.successAction));
      } catch (e) {
        emit(state.copyWith(status: TripStatus.failure, errorMessage: e.toString()));
      }
    });

    on<CreateNewTripEvent>((event, emit) async {
      if (state.currentUserId == null) return;
      emit(state.copyWith(status: TripStatus.loading));
      try {
        final newTrip = await _repository.createNewTrip(event.name, state.currentUserId!);
        final updatedList = List<Trip>.from(state.allTrips)..add(newTrip);
        
        emit(state.copyWith(
          status: TripStatus.loaded,
          allTrips: updatedList,
          selectedTrip: newTrip, // Instantly swap selection to the new trip
        ));
      } catch (e) {
        emit(state.copyWith(status: TripStatus.failure, errorMessage: e.toString()));
      }
    });

  on<UpdateTripNotesEvent>((event, emit) async {
    if (state.selectedTrip == null) return;
    try {
      await _repository.updateTripNotes(state.selectedTrip!.id, event.notes);

      // update local state copy
      final updatedTrips = state.allTrips.map((t) {
        if (t.id == state.selectedTrip!.id) {
          return Trip(
            id: t.id, name: t.name, attendees: t.attendees, completed: t.completed,
            startDate: t.startDate, endDate: t.endDate,
            images: t.images, suppliesImages: t.suppliesImages, 
            notes: event.notes, locations: t.locations,
          );
        }
        return t;
      }).toList();

      emit(state.copyWith(
        allTrips: updatedTrips,
        selectedTrip: updatedTrips.firstWhere((t) => t.id == state.selectedTrip!.id),
      ));
    } catch (e) {
      emit(state.copyWith(status: TripStatus.failure, errorMessage: e.toString()));
    }
  });

  on<AddLocationToTripEvent>((event, emit) async {
    if (state.selectedTrip == null) return;
    try {
      final updatedLocations = List<String>.from(state.selectedTrip!.locations)..add(event.locationName);

      final updatedTrips = state.allTrips.map((t) {
        if (t.id == state.selectedTrip!.id) {
          return Trip(
            id: t.id, name: t.name, attendees: t.attendees, completed: t.completed,
            startDate: t.startDate, endDate: t.endDate,
            images: t.images, suppliesImages: t.suppliesImages, notes: t.notes,
            locations: updatedLocations, // Only update the string list
          );
        }
        return t;
      }).toList();

      emit(state.copyWith(
        allTrips: updatedTrips,
        selectedTrip: updatedTrips.firstWhere((t) => t.id == state.selectedTrip!.id),
      ));
    } catch (e) {
      emit(state.copyWith(status: TripStatus.failure, errorMessage: e.toString()));
    }
  });

  Future<void> _onUpdateTripLocations(
    UpdateTripLocationsEvent event,
    Emitter<TripState> emit,
  ) async {
    try {
      // Persist the update to Firebase Firestore atomically
      await FirebaseFirestore.instance
          .collection('trips')
          .doc(event.tripId)
          .update({
        'locations': FieldValue.arrayUnion([event.locationName]),
      });

      // explicitly cast .map to return a <Trip> object type to unlock .copyWith
      final List<Trip> updatedTrips = state.allTrips.map<Trip>((dynamic item) {
        final trip = item as Trip;
        
        if (trip.id == event.tripId) {
          final newLocations = List<String>.from(trip.locations);
          if (!newLocations.contains(event.locationName)) {
            newLocations.add(event.locationName);
          }
          return trip.copyWith(locations: newLocations);
        }
        return trip;
      }).toList();

      // typpe is guaranteed as Trip now, so trip.id will resolve perfectly
      final Trip updatedSelectedTrip = updatedTrips.firstWhere(
        (Trip trip) => trip.id == (state.selectedTrip?.id ?? event.tripId),
        orElse: () => updatedTrips.first,
      );

      // emit the updated state back out to listening pages
      emit(state.copyWith(
        status: TripStatus.successAction, 
        allTrips: updatedTrips,
        selectedTrip: updatedSelectedTrip,
      ));
      
    } catch (e) {
      emit(state.copyWith(
        status: TripStatus.failure,
        errorMessage: 'Could not append campsite location: ${e.toString()}',
      ));
    }
  }

  on<UpdateTripLocationsEvent>(_onUpdateTripLocations);

  }
}