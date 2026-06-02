import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:santa_clara/blocs/authentication/bloc/authentication_bloc.dart';
import 'package:santa_clara/blocs/trip_bloc.dart'; 
import 'package:santa_clara/models/campsite.dart';
import 'package:santa_clara/models/trip_model.dart';
// import 'package:shimmer/shimmer.dart';

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
  final Campsite campsite;

  const CampsiteInfoPage({super.key, required this.campsite});

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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeroSection(
                  title: widget.campsite.name, 
                  imageURI: widget.campsite.imgURL, 
                  imageIsWeb: true,
                ),
                const SizedBox(height: 20),

                const PhotoGallery(),
                const SizedBox(height: 20),

                const SectionLabel('DESCRIPTION'),
                BodyText(text: widget.campsite.description),
                const SizedBox(height: 20),

                const SectionLabel('LOCATION'),
                SizedBox(
                  height: 300, 
                  child: CustomGoogleMap(
                    locations: [widget.campsite.position],
                    extraMarkers: {
                      Marker(
                        markerId: MarkerId(widget.campsite.name),
                        position: widget.campsite.position,
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
                          'locations': FieldValue.arrayUnion([widget.campsite.name]),
                        });
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Database Error: ${e.toString()}")),
                          );
                        }
                        return; 
                      }

                      // Dispatch event to update local Bloc state layout
                      if (context.mounted) {
                        BlocProvider.of<TripBloc>(context).add(
                          UpdateTripLocationsEvent(
                            tripId: targetTrip.id, 
                            locationName: widget.campsite.name,
                          ),
                        );

                        // Force-refresh selected trip state locally
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