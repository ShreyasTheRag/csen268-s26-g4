import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:santa_clara/navigation/my_routes.dart';
import 'package:santa_clara/widgets/google_maps.dart';
import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const MainDrawer(),
      appBar: AppBar(title: const Text("Campsite Info"), actions: const [
          LoggedInUserAvatar(
            userAvatarSize: UserAvatarSize.small,
          )
        ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            const SizedBox(height: 20),

            HorizontalScrollList(
              height: 100,
              itemCount: 5,
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('assets/car.png', width: 100, height: 100, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),

            _buildStatsRow(),
            const SizedBox(height: 20),

            const SectionLabel('DESCRIPTION'),
            const Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud',
              style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
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
            const Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud',
              style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 24),

            FullWidthButton(
              text: 'Add Location To Trip',
              onPressed: () { 
                // TODO: add logic to save location and have that info transfer over to next screen
                GoRouter.of(context).goNamed(MyRoutes.planTrip.name);
              },
              color: colorScheme.primary,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/car.png'),
          fit: BoxFit.cover,
        ),
      ),
      alignment: Alignment.bottomLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => isFavorited = !isFavorited),
              child: Icon(
                Icons.star,
                color: isFavorited ? Colors.amber : Colors.white70,
                size: 28,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Location Name',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Light green background
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('DISTANCE', '50m'),
          _buildVerticalDivider(),
          _buildStatItem('DIFFICULTY', '3/5'),
          _buildVerticalDivider(),
          _buildStatItem('RATING', '2/5'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.black26);
  }
}