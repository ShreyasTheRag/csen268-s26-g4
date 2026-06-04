import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:santa_clara/models/campsite.dart';
import 'package:santa_clara/navigation/my_routes.dart';
import 'package:santa_clara/widgets/add_things_button.dart';
import 'package:santa_clara/widgets/body_text.dart';
import 'package:santa_clara/widgets/google_maps.dart';
import 'package:santa_clara/widgets/hero_section.dart';
import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';
import 'package:santa_clara/widgets/photo_gallery.dart';
import 'package:santa_clara/widgets/triad.dart';
import '../../widgets/section_label.dart';

class CampsiteInfoPage extends StatefulWidget {
  final Campsite? campsite;

  const CampsiteInfoPage({super.key, required this.campsite});

  @override
  State<CampsiteInfoPage> createState() => _CampsiteInfoPageState(campsite);
}

class _CampsiteInfoPageState extends State<CampsiteInfoPage> {
  Campsite? campsite;
  bool isFavorited = false;
  // TODO: update campsite info based on which location was selected

  _CampsiteInfoPageState(this.campsite);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const MainDrawer(),
      appBar: AppBar(title: const Text("Campsite Info"), actions: const [
          LoggedInUserAvatar(
            userAvatarSize: UserAvatarSize.small,
          )
        ]),
      body: campsite == null ? const Center(child: Text("No campsite selected"))
      : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeroSection(title: campsite!.name, imageURI: campsite!.imgURLs[0], imageIsWeb: true),
            const SizedBox(height: 20),

            PhotoGallery(urls: campsite!.imgURLs),
            const SizedBox(height: 20),

            const SectionLabel('DESCRIPTION'),
            BodyText(
              text: campsite!.description,
            ),
            const SizedBox(height: 20),

            const SectionLabel('LOCATION'),
            SizedBox( // Removed const from here
              height: 300, 
              child: CustomGoogleMap(
                locations: [campsite!.position],
                extraMarkers: {
                  Marker(
                    markerId: MarkerId(campsite!.name),
                    position: campsite!.position,
                  ),
                },
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 24),

            AddThingsButton(title: 'Add Location To Trip', action: () => GoRouter.of(context).goNamed(IndexedRoutes.routes[4].name)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}