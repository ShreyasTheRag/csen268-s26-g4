import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:santa_clara/models/campsite.dart';
import 'package:santa_clara/navigation/my_routes.dart';
import 'package:santa_clara/widgets/google_maps.dart';

class CampsiteLocatorPage extends StatefulWidget {
  const CampsiteLocatorPage({super.key});

  @override
  State<CampsiteLocatorPage> createState() => _CampsiteLocatorPageState();
}

class _CampsiteLocatorPageState extends State<CampsiteLocatorPage> {
  bool showOnlyStarred = false;
  Campsite? selectedCampsite;

  final List<Campsite> _allCampsites = [
    Campsite(id: '1', name: 'Location 1', position: const LatLng(37.3496, -121.9390)),
    Campsite(id: '2', name: 'Location 2', position: const LatLng(37.3480, -121.9320)),
    Campsite(id: '3', name: 'Location 3', position: const LatLng(37.3520, -121.9420)),
    Campsite(id: '4', name: 'Location 4', position: const LatLng(37.3550, -121.9350), isStarred: true),
    Campsite(id: '5', name: 'Location 5', position: const LatLng(37.3600, -121.9300)),
  ];

  @override
  Widget build(BuildContext context) {
    final displayedCampsites = showOnlyStarred 
        ? _allCampsites.where((c) => c.isStarred).toList() 
        : _allCampsites;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF386625),
        title: const Text('Campsite Locator', style: TextStyle(color: Colors.white)),
        leading: const Icon(Icons.menu, color: Colors.white),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.account_circle, color: Colors.white))],
      ),
      body: Stack(
        children: [
          // MAP LAYER
          CustomGoogleMap(
            locations: [const LatLng(37.3496, -121.9390)], 
            extraMarkers: displayedCampsites.map((c) => Marker(
              markerId: MarkerId(c.id),
              position: c.position,
              onTap: () => setState(() => selectedCampsite = c),
            )).toSet(),
          ),

          // SEARCH & FILTERS (Wrapped in PointerInterceptor)
          Positioned(
            top: 16, left: 16, right: 16,
            child: PointerInterceptor(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildFilterToggle(),
                ],
              ),
            ),
          ),

          // POPUP (Wrapped in PointerInterceptor)
          if (selectedCampsite != null)
            Positioned(
              bottom: 30, left: 16, right: 16,
              child: PointerInterceptor(
                child: _buildCampsitePopup(selectedCampsite!),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(8), 
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)]
      ),
      child: const TextField(
        decoration: InputDecoration(hintText: 'Search...', icon: Icon(Icons.search), border: InputBorder.none),
      ),
    );
  }

  Widget _buildFilterToggle() {
    return Row(
      children: [
        _toggleButton('All', !showOnlyStarred, () => setState(() => showOnlyStarred = false)),
        _toggleButton('Starred', showOnlyStarred, () => setState(() => showOnlyStarred = true)),
      ],
    );
  }

  Widget _toggleButton(String text, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF558B2F) : Colors.white,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Text(text, style: TextStyle(color: active ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCampsitePopup(Campsite campsite) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 180,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(flex: 4, child: Image.asset('assets/car.png', fit: BoxFit.cover, height: double.infinity)),
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LEFT ALIGNED Header: Star then Title
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => campsite.isStarred = !campsite.isStarred),
                              child: Icon(
                                campsite.isStarred ? Icons.star : Icons.star_border,
                                color: campsite.isStarred ? Colors.amber : Colors.grey.shade400,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                campsite.name, 
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vestibulum vel ipsum',
                          style: TextStyle(fontSize: 13, height: 1.3),
                          maxLines: 3,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Text('\$\$', style: TextStyle(fontSize: 18)),
                            const Spacer(),
                            const Text('4.2(26)★'),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                GoRouter.of(context).goNamed(IndexedRoutes.routes[6].name); // Go to campsite info pages
                                // TODO: pass selected location information to next page
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD9D9D9),
                                foregroundColor: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                              child: const Text('Learn More'),
                                                          ),
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
            // Close Button over the Image
            Positioned(
              top: 8, left: 8,
              child: GestureDetector(
                onTap: () => setState(() => selectedCampsite = null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 18, color: Colors.white),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF558B2F), 
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          GoRouter.of(context).goNamed(IndexedRoutes.routes[4].name); // Go to trip page
        },
        child: const Text('View Trip', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}