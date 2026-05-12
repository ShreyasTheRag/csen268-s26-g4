import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class CustomGoogleMap extends StatefulWidget {
  final List<LatLng> locations; 
  final double initialZoom;

  const CustomGoogleMap({
    super.key,
    required this.locations,
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
    final Set<Marker> markers = widget.locations.asMap().entries.map((entry) {
      int idx = entry.key;
      LatLng position = entry.value;

      return Marker(
        markerId: MarkerId('marker_$idx'),
        position: position,
        icon: BitmapDescriptor.defaultMarker,
      );
    }).toSet();

    return GoogleMap(
      onMapCreated: (controller) => mapController = controller,
      // Focus the camera on the first item in the list
      initialCameraPosition: CameraPosition(
        target: widget.locations.isNotEmpty 
            ? widget.locations.first 
            : const LatLng(0, 0),
        zoom: widget.initialZoom,
      ),
      markers: markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
    );
  }
}