import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:santa_clara/models/campsite.dart';
import 'package:santa_clara/models/trip_model.dart';
import 'package:santa_clara/models/trip_reminder_option.dart';
import 'package:santa_clara/repositories/trip_image_repository.dart';
import 'package:santa_clara/repositories/trip_repository.dart';
import 'package:santa_clara/services/trip_notification_service.dart';

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

class UpdateTripRemindersEvent extends TripEvent {
  final List<TripReminderOption> options;
  UpdateTripRemindersEvent(this.options);
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

class AddTripImageUrlEvent extends TripEvent {
  final String imageUrl;
  final bool isSupply;
  AddTripImageUrlEvent(this.imageUrl, {this.isSupply = false});
}

class RemoveTripImageEvent extends TripEvent {
  final String imageUrl;
  final bool isSupply;
  RemoveTripImageEvent(this.imageUrl, {this.isSupply = false});
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
}

class SetLastViewedCampsite extends TripEvent {
  final Campsite campsite;
  SetLastViewedCampsite(this.campsite);
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
  final Campsite? lastViewedCampsite;

  TripState({
    this.status = TripStatus.initial,
    this.allTrips = const [],
    this.selectedTrip,
    this.currentUserId,
    this.errorMessage,
    this.lastViewedCampsite,
  });

  TripState copyWith({
    TripStatus? status,
    List<Trip>? allTrips,
    Trip? selectedTrip,
    String? currentUserId,
    String? errorMessage,
    Campsite? lastViewedCampsite,
  }) {
    return TripState(
      status: status ?? this.status,
      allTrips: allTrips ?? this.allTrips,
      selectedTrip: selectedTrip ?? this.selectedTrip,
      currentUserId: currentUserId ?? this.currentUserId,
      errorMessage: errorMessage ?? this.errorMessage,
      lastViewedCampsite: lastViewedCampsite ?? this.lastViewedCampsite,
    );
  }
}

// Bloc
class TripBloc extends Bloc<TripEvent, TripState> {
  final TripRepository _repository = TripRepository();
  final TripImageRepository _imageRepository = TripImageRepository();
  final TripNotificationService _notifications =
      TripNotificationService.instance;

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
        await _notifications.syncTrips(trips);
      } catch (e) {
        emit(state.copyWith(status: TripStatus.failure, errorMessage: e.toString()));
      }
    });

    on<UpdateTripRemindersEvent>((event, emit) async {
      if (state.selectedTrip == null) return;
      try {
        await _repository.updateTripReminders(
          state.selectedTrip!.id,
          event.options,
        );
        final updatedTrip = _copyTrip(
          state.selectedTrip!,
          reminderOptions: event.options,
        );
        emit(_withSelectedTrip((_) => updatedTrip));
        await _notifications.scheduleForTrip(updatedTrip);
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
        final updatedTrip = _copyTrip(
          state.selectedTrip!,
          startDate: event.isStart ? event.date : state.selectedTrip!.startDate,
          endDate: event.isStart ? state.selectedTrip!.endDate : event.date,
        );
        emit(_withSelectedTrip((_) => updatedTrip));
        if (event.isStart) {
          await _notifications.scheduleForTrip(updatedTrip);
        }
      } catch (e) {
        emit(state.copyWith(status: TripStatus.failure, errorMessage: e.toString()));
      }
    });

    on<FinishTripEvent>((event, emit) async {
      if (state.selectedTrip == null) return;
      try {
        final tripId = state.selectedTrip!.id;
        await _repository.completeTrip(tripId);
        await _notifications.cancelForTrip(tripId);
        emit(state.copyWith(status: TripStatus.successAction));
      } catch (e) {
        emit(state.copyWith(status: TripStatus.failure, errorMessage: e.toString()));
      }
    });

    on<DeleteTripEvent>((event, emit) async {
      if (state.selectedTrip == null) return;
      try {
        final tripId = state.selectedTrip!.id;
        await _repository.deleteTrip(tripId);
        await _notifications.cancelForTrip(tripId);
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
          selectedTrip: newTrip,
        ));
        await _notifications.scheduleForTrip(newTrip);
      } catch (e) {
        emit(state.copyWith(status: TripStatus.failure, errorMessage: e.toString()));
      }
    });

    on<UpdateTripNotesEvent>((event, emit) async {
      if (state.selectedTrip == null) return;
      try {
        await _repository.updateTripNotes(state.selectedTrip!.id, event.notes);
        emit(_withSelectedTrip((trip) => _copyTrip(trip, notes: event.notes)));
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
      if (event.isSupply) {
        if (state.selectedTrip!.suppliesImages.contains(event.imageUrl)) return;
        emit(_withSelectedTrip(
          (trip) => _copyTrip(
            trip,
            suppliesImages: [...trip.suppliesImages, event.imageUrl],
          ),
        ));
      } else {
        if (state.selectedTrip!.images.contains(event.imageUrl)) return;
        emit(_withSelectedTrip(
          (trip) => _copyTrip(trip, images: [...trip.images, event.imageUrl]),
        ));
      }
    });

    on<RemoveTripImageEvent>((event, emit) async {
      if (state.selectedTrip == null) return;
      try {
        await _imageRepository.removeTripImage(
          tripId: state.selectedTrip!.id,
          imageUrl: event.imageUrl,
          category: event.isSupply
              ? TripImageCategory.supplies
              : TripImageCategory.tripPhotos,
        );
        if (event.isSupply) {
          emit(_withSelectedTrip(
            (trip) => _copyTrip(
              trip,
              suppliesImages: trip.suppliesImages
                  .where((u) => u != event.imageUrl)
                  .toList(),
            ),
          ));
        } else {
          emit(_withSelectedTrip(
            (trip) => _copyTrip(
              trip,
              images: trip.images.where((u) => u != event.imageUrl).toList(),
            ),
          ));
        }
      } catch (e) {
        emit(state.copyWith(status: TripStatus.failure, errorMessage: e.toString()));
      }
    });

    on<AddLocationToTripEvent>((event, emit) async {
      if (state.selectedTrip == null) return;
      try {
        final updatedLocations = List<String>.from(state.selectedTrip!.locations)
          ..add(event.locationName);
        emit(_withSelectedTrip(
          (trip) => _copyTrip(trip, locations: updatedLocations),
        ));
      } catch (e) {
        emit(state.copyWith(status: TripStatus.failure, errorMessage: e.toString()));
      }
    });

    on<SetLastViewedCampsite>((event, emit) {
      emit(state.copyWith(lastViewedCampsite: event.campsite));
    });

    on<UpdateTripLocationsEvent>(_onUpdateTripLocations);
  }

  Future<void> _onUpdateTripLocations(
    UpdateTripLocationsEvent event,
    Emitter<TripState> emit,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('trips').doc(event.tripId).update({
        'locations': FieldValue.arrayUnion([event.locationName]),
      });

      final List<Trip> updatedTrips = state.allTrips.map<Trip>((trip) {
        if (trip.id == event.tripId) {
          final newLocations = List<String>.from(trip.locations);
          if (!newLocations.contains(event.locationName)) {
            newLocations.add(event.locationName);
          }
          return trip.copyWith(locations: newLocations);
        }
        return trip;
      }).toList();

      final Trip updatedSelectedTrip = updatedTrips.firstWhere(
        (trip) => trip.id == (state.selectedTrip?.id ?? event.tripId),
        orElse: () => updatedTrips.first,
      );

      emit(state.copyWith(
        status: TripStatus.loaded,
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

  TripState _withSelectedTrip(
    Trip Function(Trip trip) transform, {
    TripStatus? status,
  }) {
    final selected = state.selectedTrip!;
    final updatedTrip = transform(selected);
    final updatedTrips =
        state.allTrips.map((t) => t.id == selected.id ? updatedTrip : t).toList();
    return state.copyWith(
      status: status ?? state.status,
      allTrips: updatedTrips,
      selectedTrip: updatedTrip,
    );
  }

  Trip _copyTrip(
    Trip trip, {
    List<String>? images,
    List<String>? suppliesImages,
    List<String>? locations,
    String? notes,
    DateTime? startDate,
    DateTime? endDate,
    List<TripReminderOption>? reminderOptions,
  }) {
    return Trip(
      id: trip.id,
      name: trip.name,
      attendees: trip.attendees,
      completed: trip.completed,
      startDate: startDate ?? trip.startDate,
      endDate: endDate ?? trip.endDate,
      images: images ?? trip.images,
      suppliesImages: suppliesImages ?? trip.suppliesImages,
      notes: notes ?? trip.notes,
      locations: locations ?? trip.locations,
      reminderOptions: reminderOptions ?? trip.reminderOptions,
    );
  }
}
