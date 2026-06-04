import 'dart:convert';
import 'package:http/http.dart' as http;

class Vehicle {
  final String year;
  final String make;
  final String model;
  final String driveType;   // AWD, 4WD, FWD, RWD
  final String vehicleType; // Passenger Car, Multipurpose Passenger Vehicle (MPV), Truck

  Vehicle({
    required this.year,
    required this.make,
    required this.model,
    required this.driveType,
    required this.vehicleType,
  });

  List<Map<String, String>> getRecommendedAccessories() {
    List<Map<String, String>> accessories = [];

    // All vehicles get a standard recommendation
    accessories.add({
      'name': 'Trunk Storage Organizer',
      'reason': 'Keeps camping equipment, tools, and cooking utensils organized in your cargo area.'
    });

    // Adventure-ready drivetrain logic
    if (driveType.contains('4WD') || driveType.contains('AWD')) {
      accessories.add({
        'name': 'All-Terrain Tires',
        'reason': 'Crucial for navigating rocky fire roads and loose gravel leading to dispersed sites.'
      });
      accessories.add({
        'name': 'Heavy-Duty Recovery Boards',
        'reason': 'Gives you an easy escape option if your rig gets stuck in soft sand or unexpected mud.'
      });
    }

    // Space/Sleeping capability configuration based on vehicle type
    final typeLower = vehicleType.toLowerCase();
    if (typeLower.contains('multipurpose') || typeLower.contains('truck') || typeLower.contains('suv')) {
      accessories.add({
        'name': 'Custom SUV Air Mattress',
        'reason': 'Allows you to turn your folded-flat cargo bay into a comfortable car-camping setup.'
      });
      accessories.add({
        'name': 'Magnetic Window Mesh Screens',
        'reason': 'Snaps onto your window frame to allow airflow overnight while keeping bugs out.'
      });
    } else {
      // Compact sedan storage upgrade
      accessories.add({
        'name': 'Waterproof Roof Cargo Bag',
        'reason': 'Frees up critical interior legroom by moving bulky sleeping bags and tents to the roof.'
      });
    }

    return accessories;
  }
}
sealed class VehicleService {
  static Future<Vehicle?> fetchVehicleByVIN(String vin) async {
    // 1. Format the VIN token safely
    final cleanVin = Uri.encodeComponent(vin.toUpperCase().replaceAll(' ', ''));
    
    // 2. Query the exact endpoint that worked for you
    final Uri url = Uri.parse(
      'https://vpic.nhtsa.dot.gov/api/vehicles/DecodeVinValues/$cleanVin?format=json'
    );

    print("Sending live VIN parse request to: $url");

    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        final List<dynamic> results = decodedData['Results'] ?? [];

        if (results.isNotEmpty) {
          final data = results[0];

          // Check the ErrorCode exactly as NHTSA formats it
          final String errorCode = data['ErrorCode']?.toString() ?? '-1';
          if (errorCode != "0") {
            print("NHTSA Decoding Warning: ${data['ErrorText']}");
            return null;
          }

          // 3. Map directly to your working JSON keys
          return Vehicle(
            year: data['ModelYear']?.toString() ?? 'Unknown Year',
            make: data['Make']?.toString() ?? 'Unknown Make',
            model: data['Model']?.toString() ?? 'Unknown Model',
            driveType: data['DriveType']?.toString() ?? 'FWD', 
            vehicleType: data['BodyClass']?.toString() ?? 'SUV',
          );
        }
      }
    } catch (e) {
      print('Failed to parse vehicle stream: $e');
    }
    return null;
  }
}