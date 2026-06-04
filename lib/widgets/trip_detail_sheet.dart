import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:santa_clara/blocs/trip_bloc.dart';
import 'package:santa_clara/models/campsite.dart';
import 'package:santa_clara/navigation/my_routes.dart';
import 'package:santa_clara/pages/profile/profile_page.dart';
import 'package:santa_clara/widgets/google_maps.dart';

class TripDetailSheet extends StatelessWidget {
  final Map<String, dynamic> tripData;
  const TripDetailSheet({required this.tripData});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;
    final String tripName = tripData['trip_name'] ?? tripData['name'] ?? 'Trip';
    final List<String> images = List<String>.from(tripData['images'] ?? [])
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final List<String> locations = List<String>.from(tripData['locations'] ?? [])
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return SizedBox(
      height: screenHeight * 0.75,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(tripName, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            // Images
            if (images.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 120,
                      child: TripImageThumbnail(imageSource: images[index]),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Map
            FutureBuilder<List<Campsite>>(
              future: Campsite.getNearbyCampsites(),
              builder: (context, snapshot) {
                final allCampsites = snapshot.data ?? [];
                final matchingCampsites = allCampsites.where((c) => locations.contains(c.name)).toList();
                final Set<Marker> routeMarkers = matchingCampsites.map((c) => Marker(
                  markerId: MarkerId(c.id),
                  position: c.position,
                  infoWindow: InfoWindow(title: c.name),
                )).toSet();

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 180,
                      child: CustomGoogleMap(
                        locations: matchingCampsites.isNotEmpty ? [matchingCampsites.first.position] : [],
                        extraMarkers: routeMarkers,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            // Locations
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text('Locations', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            // Replace Expanded+ListView with a Column
            FutureBuilder<List<Campsite>>(
              future: Campsite.getNearbyCampsites(),
              builder: (context, snapshot) {
                final allCampsites = snapshot.data ?? [];
                return Column(
                  children: locations.map((locName) {
                    final match = allCampsites.where(
                      (c) => c.name.trim().toLowerCase() == locName.toLowerCase(),
                    );
                    final campsite = match.isNotEmpty ? match.first : null;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: Icon(Icons.location_on_outlined, color: colorScheme.primary),
                      title: Text(locName),
                      trailing: campsite != null ? Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant) : null,
                      onTap: campsite == null ? null : () {
                        Navigator.pop(context);
                        BlocProvider.of<TripBloc>(context).add(SetLastViewedCampsite(campsite));
                        GoRouter.of(context).goNamed(MyRoutes.campsiteInfo.name);
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}