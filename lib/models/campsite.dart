import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class Campsite {
  static List<Campsite>? _nc;
  final String id;
  final String name;
  final LatLng position;
  final double rating;
  final int reviews;
  final String price;
  final String description;
  final String imgURL;
  bool isStarred;

  Campsite({
    required this.id,
    required this.name,
    required this.position,
    required this.description,
    required this.imgURL,
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
    String imgURL = jsonObj['MEDIA'].length == 0 ? 'assets/car.png' : jsonObj['MEDIA'][0]['URL'];
    int nests = 0;
    String rawDescription = jsonObj['FacilityDescription'].split('');
    String description = '';
    for (var c in rawDescription.split('')) {
      if (c == '<') {
        nests += 1;
      } else if (c == '>') {
        nests -= 1;
      } else if (nests == 0) {
        description = '$description$c';
      }
    }
    return Campsite(
      id: jsonObj['FacilityID']?.toString() ?? '',
      // 💡 FIX: Force cast to string safely to avoid null/dynamic layout issues
      name: jsonObj['FacilityName']?.toString() ?? 'Unknown Dispersed Campsite',
      position: LatLng(lat, lng),
      description: jsonObj['FacilityDescription'],
      imgURL: imgURL,
      price: determinedPrice,
      rating: 0.0, 
      reviews: 0,
      isStarred: false, 
    );
  }

  static Future<List<Campsite>> getNearbyCampsites() async {
    if (_nc == null) {
      try {
        // 2. Use 'await' to halt execution right here until the network data lands
        final List<dynamic> rawRIDBData = await RIDBService.fetchNearbyCampgrounds();
        
        // 3. Map the data cleanly once it arrives
        List<Campsite> csl = rawRIDBData.map((jsonItem) {
          return Campsite.fromRIDB(jsonItem);
        }).toList();
        
        // 4. Now this print will show your actual campsites!
        print("Successfully mapped ${csl.length} campsites.");
        _nc = csl;
        
      } catch (error) {
        print("Error parsing campsites: $error");
        _nc = []; // Return an empty list if the database call fails
      }
    }
    return Future.delayed(Duration.zero, () => _nc!);
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
  static Future<List<dynamic>> fetchNearbyCampgrounds() async {
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
        
        print("SUCCESS! RECDATA parsed successfully. Items found: ${results.length}");
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