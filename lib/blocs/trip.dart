import 'package:santa_clara/models/trip_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class TripEvent {}
class UpdateStartDate extends TripEvent { final DateTime date; UpdateStartDate(this.date); }
class UpdateNotes extends TripEvent { final String notes; UpdateNotes(this.notes); }
class AddTripImage extends TripEvent { final String imageAsset; AddTripImage(this.imageAsset); }
class RemoveTripImage extends TripEvent { final int index; RemoveTripImage(this.index); }

class TripState {
  final Trip trip;
  TripState(this.trip);
}

class TripBloc extends Bloc<TripEvent, TripState> {
  TripBloc() : super(TripState(Trip(
    name: "Trip Name 1",
    startDate: DateTime(2025, 4, 5),
    endDate: DateTime(2025, 4, 18),
  ))) {
    on<UpdateStartDate>((event, emit) {
      emit(TripState(state.trip.copyWith(start: event.date)));
    });
    on<UpdateNotes>((event, emit) {
      emit(TripState(state.trip.copyWith(notes: event.notes)));
    });
    on<AddTripImage>((event, emit) {
      final updatedImages = List<String>.from(state.trip.images)
        ..add(event.imageAsset);
      emit(TripState(state.trip.copyWith(images: updatedImages)));
    });
    on<RemoveTripImage>((event, emit) {
      if (event.index < 0 || event.index >= state.trip.images.length) return;
      final updatedImages = List<String>.from(state.trip.images)
        ..removeAt(event.index);
      emit(TripState(state.trip.copyWith(images: updatedImages)));
    });
  }
}