import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:santa_clara/models/trip_model.dart';
import 'package:santa_clara/repositories/trip_image_repository.dart';
import 'package:santa_clara/repositories/trip_repository.dart';

// Events
abstract class TripEvent {}

class LoadUserTrips extends TripEvent {
  final String email;
  final String? uid;
  LoadUserTrips(this.email, {this.uid});
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

class UploadTripImageEvent extends TripEvent {
  final String localPath;
  UploadTripImageEvent(this.localPath);
}

/// Firestore/Storage upload already completed; sync local trip state.
class AddTripImageUrlEvent extends TripEvent {
  final String imageUrl;
  AddTripImageUrlEvent(this.imageUrl);
}

class RemoveTripImageEvent extends TripEvent {
  final String imageUrl;
  RemoveTripImageEvent(this.imageUrl);
}

// States
enum TripStatus {
  initial,
  loading,
  loaded,
  uploadingImage,
  successAction,
  failure,
}

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
  final TripImageRepository _imageRepository = TripImageRepository();

  TripBloc() : super(TripState()) {
    on<LoadUserTrips>((event, emit) async {
      emit(state.copyWith(status: TripStatus.loading));
      try {
        final userId =
            await _repository.getUserIdByEmail(event.email, uid: event.uid);
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
              images: t.images, suppliesImages: t.suppliesImages, notes: t.notes,
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

      emit(_withSelectedTrip(
        (trip) => _copyTrip(trip, notes: event.notes),
      ));
    } catch (e) {
      emit(state.copyWith(status: TripStatus.failure, errorMessage: e.toString()));
    }
  });

    on<UploadTripImageEvent>((event, emit) async {
      if (state.selectedTrip == null) return;
      emit(state.copyWith(status: TripStatus.uploadingImage, errorMessage: null));
      try {
        final url = await _imageRepository.uploadTripImage(
          tripId: state.selectedTrip!.id,
          localPath: event.localPath,
        );
        emit(_withSelectedTrip(
          (trip) => _copyTrip(trip, images: [...trip.images, url]),
          status: TripStatus.loaded,
        ));
      } catch (e) {
        emit(state.copyWith(
          status: TripStatus.failure,
          errorMessage: 'Failed to upload photo: $e',
        ));
      }
    });

    on<AddTripImageUrlEvent>((event, emit) {
      if (state.selectedTrip == null) return;
      if (state.selectedTrip!.images.contains(event.imageUrl)) return;
      emit(_withSelectedTrip(
        (trip) => _copyTrip(trip, images: [...trip.images, event.imageUrl]),
      ));
    });

    on<RemoveTripImageEvent>((event, emit) async {
      if (state.selectedTrip == null) return;
      try {
        await _imageRepository.removeTripImage(
          tripId: state.selectedTrip!.id,
          imageUrl: event.imageUrl,
        );
        emit(_withSelectedTrip(
          (trip) => _copyTrip(
            trip,
            images: trip.images.where((u) => u != event.imageUrl).toList(),
          ),
        ));
      } catch (e) {
        emit(state.copyWith(status: TripStatus.failure, errorMessage: e.toString()));
      }
    });
  }

  TripState _withSelectedTrip(
    Trip Function(Trip trip) transform, {
    TripStatus? status,
  }) {
    final selected = state.selectedTrip!;
    final updatedTrip = transform(selected);
    final updatedTrips = state.allTrips
        .map((t) => t.id == selected.id ? updatedTrip : t)
        .toList();
    return state.copyWith(
      status: status ?? state.status,
      allTrips: updatedTrips,
      selectedTrip: updatedTrip,
    );
  }

  Trip _copyTrip(
    Trip trip, {
    List<String>? images,
    String? notes,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Trip(
      id: trip.id,
      name: trip.name,
      attendees: trip.attendees,
      completed: trip.completed,
      startDate: startDate ?? trip.startDate,
      endDate: endDate ?? trip.endDate,
      images: images ?? trip.images,
      suppliesImages: trip.suppliesImages,
      notes: notes ?? trip.notes,
    );
  }
}