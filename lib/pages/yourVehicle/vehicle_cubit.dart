import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:santa_clara/models/vehicle.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:santa_clara/models/vehicle.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

// 1. Define the States
abstract class VehicleState {}
class VehicleLoading extends VehicleState {}
class NoVehicleSaved extends VehicleState {}
class VehicleLoaded extends VehicleState {
  final Vehicle vehicle;
  VehicleLoaded(this.vehicle);
}
class VehicleError extends VehicleState {
  final String message;
  VehicleError(this.message);
}

// 2. Define the Cubit Architecture
class VehicleCubit extends Cubit<VehicleState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String userId; 

  VehicleCubit() : super(VehicleLoading()) {
    auth.User? authUser = auth.FirebaseAuth.instance.currentUser;
    userId = authUser!.uid;
    checkSavedVehicle();
  }

  // Reads the current user's document from Firestore
  Future<void> checkSavedVehicle() async {
    try {
      emit(VehicleLoading());
      
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data()!;
        final vehicleData = userData['vehicle'] as Map<String, dynamic>?;
        
        if (vehicleData != null && vehicleData['vin'] != null) {
          final vehicleSpecs = await VehicleService.fetchVehicleByVIN(vehicleData['vin']);
          
          if (vehicleSpecs != null) {
            emit(VehicleLoaded(vehicleSpecs));
            return;
          }
        }
      }
      emit(NoVehicleSaved());
    } catch (e) {
      emit(VehicleError("Failed to check user vehicle profile: $e"));
    }
  }

  // Appends the VIN directly to the existing root User document
  Future<void> saveVehicle(String vin) async {
    try {
      emit(VehicleLoading());
      
      final vehicleSpecs = await VehicleService.fetchVehicleByVIN(vin);
      
      if (vehicleSpecs != null) {
        final cleanVin = vin.toUpperCase().replaceAll(' ', '');

        // merge: true keeps name, email, etc., completely safe!
        await _firestore.collection('Users').doc(userId).set({
          'vehicle': {
            'vin': cleanVin,
            'lastUpdated': FieldValue.serverTimestamp(),
          }
        }, SetOptions(merge: true));

        emit(VehicleLoaded(vehicleSpecs));
      } else {
        emit(VehicleError("NHTSA database could not decode that VIN. Please check your inputs."));
      }
    } catch (e) {
      emit(VehicleError("Failed to update user profile in Firestore: $e"));
    }
  }
}