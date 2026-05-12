import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class CustomGoogleMap extends StatefulWidget {
  final List<LatLng> locations;
  final Set<Marker> extraMarkers;
  final double initialZoom;

  const CustomGoogleMap({
    super.key,
    required this.locations,
    this.extraMarkers = const {},
    this.initialZoom = 14.0,
  });

  @override
  State<CustomGoogleMap> createState() => _CustomGoogleMapState();
}

class _CustomGoogleMapState extends State<CustomGoogleMap> {
  late GoogleMapController mapController;

  @override
  void initState() {
    super.initState();
    _handleLocationPermission();
  }

  Future<void> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      onMapCreated: (controller) => mapController = controller,
      initialCameraPosition: CameraPosition(
        // Dynamic: Target the first location in the list provided by the caller
        target: widget.locations.isNotEmpty 
            ? widget.locations.first 
            : const LatLng(0, 0),
        zoom: widget.initialZoom,
      ),
      // Only display markers explicitly passed via extraMarkers 
      // This prevents "dumb" markers from blocking "smart" interactive markers
      markers: widget.extraMarkers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}