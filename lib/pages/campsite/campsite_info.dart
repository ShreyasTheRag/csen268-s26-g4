import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:santa_clara/navigation/my_routes.dart';
import 'package:santa_clara/widgets/add_things_button.dart';
import 'package:santa_clara/widgets/body_text.dart';
import 'package:santa_clara/widgets/google_maps.dart';
import 'package:santa_clara/widgets/hero_section.dart';
import 'package:santa_clara/widgets/photo_gallery.dart';
import 'package:santa_clara/widgets/triad.dart';
import '../../widgets/full_width_button.dart';
import '../../widgets/horizontal_scroll_list.dart';
import '../../widgets/section_label.dart';

class CampsiteInfoPage extends StatefulWidget {
  const CampsiteInfoPage({super.key});

  @override
  State<CampsiteInfoPage> createState() => _CampsiteInfoPageState();
}

class _CampsiteInfoPageState extends State<CampsiteInfoPage> {
  bool isFavorited = false;
  // TODO: update campsite info based on which location was selected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF335C1F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Campsite Info', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeroSection(title: "Location Name"),
            const SizedBox(height: 20),

            const PhotoGallery(),
            const SizedBox(height: 20),

            const Triad(keys: ["DISTANCE", "DIFFICULTY", "RATING"], values: ["50m", "3 / 5", "2 / 5"]), // Replace with Triad
            const SizedBox(height: 20),

            const SectionLabel('DESCRIPTION'),
            const BodyText(
              text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud',
            ),
            const SizedBox(height: 20),

            const SectionLabel('LOCATION'),
            SizedBox( // Removed const from here
              height: 300, 
              child: CustomGoogleMap(
                locations: const [LatLng(37.3496, -121.9390)],
                extraMarkers: {
                  const Marker(
                    markerId: MarkerId('scu'),
                    position: LatLng(37.3496, -121.9390),
                  ),
                },
              ),
            ),
            const SizedBox(height: 20),

            const SectionLabel('SUPPLIES NEEDED'),
            const BodyText(
              text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud',
            ),
            const SizedBox(height: 24),

            AddThingsButton(title: 'Add Location To Trip', action: () => GoRouter.of(context).goNamed(IndexedRoutes.routes[4].name)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}