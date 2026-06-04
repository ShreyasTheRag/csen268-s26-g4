import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:santa_clara/blocs/authentication/bloc/authentication_bloc.dart';
import 'package:santa_clara/blocs/trip_bloc.dart'; 
import 'package:santa_clara/models/campsite.dart';
import 'package:santa_clara/models/trip_model.dart';

import 'package:santa_clara/navigation/my_routes.dart';
import 'package:santa_clara/widgets/add_things_button.dart';
import 'package:santa_clara/widgets/body_text.dart';
import 'package:santa_clara/widgets/google_maps.dart';
import 'package:santa_clara/widgets/hero_section.dart';
import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';
import 'package:santa_clara/widgets/photo_gallery.dart';
import '../../widgets/section_label.dart';

class CampsiteInfoPage extends StatefulWidget {
  const CampsiteInfoPage({super.key});

  @override
  State<CampsiteInfoPage> createState() => _CampsiteInfoPageState();
}

class _CampsiteInfoPageState extends State<CampsiteInfoPage> {
  bool isFavorited = false;

  @override
  Widget build(BuildContext context) {
    final authState = BlocProvider.of<AuthenticationBloc>(context).state;
    TripBloc? tripBloc;
    
    try {
      tripBloc = BlocProvider.of<TripBloc>(context);
    } catch (_) {
      tripBloc = null;
    }

    if (tripBloc == null || authState is! AuthenticationSignedInState) {
      return Scaffold(
        appBar: AppBar(title: const Text("Campsite Info")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (tripBloc.state.status == TripStatus.initial) {
      tripBloc.add(LoadUserTrips(authState.user.email));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: const Text("Campsite Info"), 
        actions: const [
          LoggedInUserAvatar(userAvatarSize: UserAvatarSize.small)
        ],
      ),
      body: BlocBuilder<TripBloc, TripState>(
        builder: (context, tripState) {
          if (tripState.status == TripStatus.loading || tripState.status == TripStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          final Campsite? currentCampsite = tripState.lastViewedCampsite;

          if (currentCampsite == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.travel_explore, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      "Select a campsite from the campsite selector page",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeroSection(
                  title: currentCampsite.name, 
                  imageURI: currentCampsite.imgURLs[0], 
                  imageIsWeb: true,
                ),
                const SizedBox(height: 20),

                PhotoGallery(urls: currentCampsite.imgURLs),
                const SizedBox(height: 20),

                const SectionLabel('DESCRIPTION'),
                BodyText(text: currentCampsite.description),
                const SizedBox(height: 20),

                const SectionLabel('LOCATION'),
                SizedBox(
                  height: 300, 
                  child: CustomGoogleMap(
                    locations: [currentCampsite.position],
                    extraMarkers: {
                      Marker(
                        markerId: MarkerId(currentCampsite.name),
                        position: currentCampsite.position,
                      ),
                    },
                  ),
                ),
                const SizedBox(height: 24),

                AddThingsButton(
                  title: 'Add Location To Trip', 
                  action: () async { 
                    Trip? targetTrip = tripState.selectedTrip;
                    
                    if (targetTrip == null && tripState.allTrips.isNotEmpty) {
                      targetTrip = tripState.allTrips.first;
                    }

                    if (targetTrip != null) {
                      try {
                        await FirebaseFirestore.instance
                            .collection('trips')
                            .doc(targetTrip.id)
                            .update({
                          'locations': FieldValue.arrayUnion([currentCampsite.name]),
                        });
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Database Error: ${e.toString()}")),
                          );
                        }
                        return; 
                      }

                      if (context.mounted) {
                        // Dispatch event to update local Bloc state data arrays
                        BlocProvider.of<TripBloc>(context).add(
                          UpdateTripLocationsEvent(
                            tripId: targetTrip.id, 
                            locationName: currentCampsite.name,
                          ),
                        );

                        // Ensure local selection references the updated record
                        BlocProvider.of<TripBloc>(context).add(SelectTrip(targetTrip));
                        
                        GoRouter.of(context).goNamed(MyRoutes.planTrip.name);
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("No active trip found. Please create a trip on the planning tab first!"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}