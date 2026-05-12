import 'package:santa_clara/models/trip_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class TripEvent {}
class UpdateStartDate extends TripEvent { final DateTime date; UpdateStartDate(this.date); }
class UpdateNotes extends TripEvent { final String notes; UpdateNotes(this.notes); }

class TripState {
  final Trip trip;
  TripState(this.trip);
}

class TripBloc extends Bloc<TripEvent, TripState> {
  TripBloc() : super(TripState(Trip(
    name: "Trip Name 1", 
    startDate: DateTime(2025, 4, 5), 
    endDate: DateTime(2025, 4, 18)
  ))) {
    on<UpdateStartDate>((event, emit) {
      emit(TripState(state.trip.copyWith(start: event.date)));
    });
    on<UpdateNotes>((event, emit) {
      emit(TripState(state.trip.copyWith(notes: event.notes)));
    });
  }
}