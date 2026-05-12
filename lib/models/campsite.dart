import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    this.rating = 4.2,
    this.reviews = 26,
    this.price = '\$\$',
    this.isStarred = false,
  });
}