import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:santa_clara/blocs/trip_bloc.dart';
import 'package:santa_clara/models/campsite.dart';
import 'package:santa_clara/navigation/my_routes.dart';
import 'package:santa_clara/widgets/google_maps.dart';
import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';

class CampsiteLocatorPage extends StatefulWidget {
  const CampsiteLocatorPage({super.key});

  @override
  State<CampsiteLocatorPage> createState() => _CampsiteLocatorPageState();
}

class _CampsiteLocatorPageState extends State<CampsiteLocatorPage> {
  bool showOnlyStarred = false;
  Campsite? selectedCampsite;
  List<Campsite>? fetchedCampsites;
  late Future<List<Campsite>> campsiteList;

  @override
  void initState() {
    super.initState();
    campsiteList = Campsite.getNearbyCampsites();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return FutureBuilder<List<Campsite>>(
      future: campsiteList,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
          return Scaffold(
            drawer: const MainDrawer(),
            appBar: AppBar(
              title: const Text("Campsite Locator"), 
              actions: const [
                LoggedInUserAvatar(userAvatarSize: UserAvatarSize.small)
              ],
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (fetchedCampsites == null) {
          fetchedCampsites = snapshot.data!;
        }

        final displayedCampsites = showOnlyStarred 
            ? fetchedCampsites!.where((c) => c.isStarred).toList() 
            : fetchedCampsites!;
        
        return Scaffold(
          drawer: const MainDrawer(),
          appBar: AppBar(
            title: const Text("Campsite Locator"), 
            actions: const [
              LoggedInUserAvatar(userAvatarSize: UserAvatarSize.small),
            ],
          ),
          body: Stack(
            children: [
              // MAP LAYER
              CustomGoogleMap(
                locations: const [LatLng(37.3496, -121.9390)], 
                extraMarkers: displayedCampsites.map((c) => Marker(
                  markerId: MarkerId(c.id),
                  position: c.position,
                  onTap: () => setState(() => selectedCampsite = c),
                )).toSet(),
              ),

              // SEARCH & FILTERS 
              Positioned(
                top: 16, left: 16, right: 16,
                child: PointerInterceptor(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 12),
                      _buildFilterToggle(colorScheme),
                    ],
                  ),
                ),
              ),

              // POPUP
              if (selectedCampsite != null)
                Positioned(
                  bottom: 30, left: 16, right: 16,
                  child: PointerInterceptor(
                    child: _buildCampsitePopup(selectedCampsite!),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _buildBottomAction(colorScheme),
        );
      }
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

  Widget _buildFilterToggle(dynamic colorScheme) {
    return Row(
      children: [
        _toggleButton('All', !showOnlyStarred, () => setState(() => showOnlyStarred = false), colorScheme),
        _toggleButton('Starred', showOnlyStarred, () => setState(() => showOnlyStarred = true), colorScheme),
      ],
    );
  }

  Widget _toggleButton(String text, bool active, VoidCallback onTap, dynamic colorScheme) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: active ? colorScheme.primary : Colors.white,
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
                Expanded(
                  flex: 4,
                  child: (selectedCampsite!.imgURLs.length == 1 && selectedCampsite!.imgURLs[0] == 'assets/car.png') ? Image.asset('assets/car.png', fit: BoxFit.cover, height: double.infinity) : Image.network(selectedCampsite!.imgURLs[0], fit: BoxFit.cover, height: double.infinity)
                ),
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                        const Spacer(),
                        Row(
                          children: [
                            const Spacer(),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                BlocProvider.of<TripBloc>(context).add(SetLastViewedCampsite(selectedCampsite!));
                                GoRouter.of(context).goNamed(MyRoutes.campsiteInfo.name);
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

  Widget _buildBottomAction(dynamic colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary, 
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          GoRouter.of(context).goNamed(MyRoutes.planTrip.name);
        },
        child: const Text('View Trip', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}