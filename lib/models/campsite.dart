import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class Campsite {
  final String id;
  final String name;
  final LatLng position;
  final double rating;
  final int reviews;
  final String price;
  bool isStarred;

  Campsite({
    required this.id,
    required this.name,
    required this.position,
    this.rating = 0.0,
    this.reviews = 0,
    this.price = '\$\$',
    this.isStarred = false,
  });

  factory Campsite.fromRIDB(Map<String, dynamic> jsonObj) {
    double lat = (jsonObj['FacilityLatitude'] as num?)?.toDouble() ?? 0.0;
    double lng = (jsonObj['FacilityLongitude'] as num?)?.toDouble() ?? 0.0;
    String determinedPrice = '\$\$';
    if (jsonObj['FacilityDescription']?.toString().toLowerCase().contains('free') == true) {
      determinedPrice = 'Free';
    }
    return Campsite(
      id: jsonObj['FacilityID']?.toString() ?? '',
      name: jsonObj['FacilityName'] ?? 'Unknown Dispersed Campsite',
      position: LatLng(lat, lng),
      price: determinedPrice,
      // rating and reviews default to 0.0 / 0 since RIDB lacks a native review count.
      // This maps perfectly to Treksetter's internal database once users start rating them!
      rating: 0.0, 
      reviews: 0,
      isStarred: false, // Default state when pulling fresh data from network
    );
  }

  static Future<List<Campsite>> getNearbyCampsites(double lat, double lon, double radius) async {
    try {
      // 2. Use 'await' to halt execution right here until the network data lands
      final List<dynamic> rawRIDBData = await RIDBService.fetchNearbyCampgrounds(lat, lon, radius);
      
      // 3. Map the data cleanly once it arrives
      List<Campsite> csl = rawRIDBData.map((jsonItem) {
        return Campsite.fromRIDB(jsonItem);
      }).toList();
      
      // 4. Now this print will show your actual campsites!
      print("Successfully mapped ${csl.length} campsites.");
      return csl;
      
    } catch (error) {
      print("Error parsing campsites: $error");
      return []; // Return an empty list if the database call fails
    }
  }
}

sealed class RIDBService {
  static const String _proxyUrl = '';
  static const String _baseUrl = 'https://ridb.recreation.gov/api/v1';
  static const String _apiKey = '68438d6e-7d20-4716-8cd2-e8830b4ee87f';

  static Future<List<dynamic>> fetchCampgrounds(String query) async {
    final Uri url = Uri.parse('$_proxyUrl$_baseUrl/facilities?query=$query&state=CA&activity=CAMPING');
    try {
      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'apikey': _apiKey,
        }
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['RECDATA'] ?? [];
      } else {
        print('RIDB Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load data from RIDB');
      }
    } catch (e) {
      print('Network exception: $e');
      rethrow;
    }
  }
  static Future<List<dynamic>> fetchNearbyCampgrounds(double lat, double lon, double radiusInMiles) async {
    // 1. Build a completely clean, raw URL string with absolutely no nested quotes
    const String targetUrl = 'https://ridb.recreation.gov/api/v1/facilities?state=CA&activity=CAMPING&limit=50';
    
    // 2. Wrap it cleanly in the proxy parser
    final Uri url = Uri.parse(targetUrl);

    print("Sending Request to: $url");

    try {
      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'apikey': _apiKey, // Ensure this matches your lowercase '68438d6e...' string above
        },
      );

      print("Response Status Code: ${response.statusCode}");
      //print("Raw Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedData = json.decode(response.body);
        final List<dynamic> results = decodedData['RECDATA'] ?? [];
        
        print("🚨 SUCCESS! RECDATA parsed successfully. Items found: ${results.length}");
        return results;
      } else {
        print("Server returned a non-200 error code.");
        return [];
      }
    } catch (e) {
      print('Network exception occurred: $e');
      return [];
    }
  }
}