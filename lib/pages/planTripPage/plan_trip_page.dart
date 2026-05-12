import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:santa_clara/blocs/trip.dart';
import 'package:santa_clara/navigation/my_routes.dart';
import 'package:santa_clara/widgets/google_maps.dart';
import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';

import '../../widgets/full_width_button.dart';
import '../../widgets/horizontal_scroll_list.dart';
import '../../widgets/location_card.dart';
import '../../widgets/removable_image_card.dart';
import '../../widgets/section_label.dart';

class PlanTripPage extends StatelessWidget {
  const PlanTripPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocProvider(
      create: (context) => TripBloc(),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        drawer: const MainDrawer(),
        appBar: AppBar(title: const Text("Campsite Info"), actions: const [
            LoggedInUserAvatar(
              userAvatarSize: UserAvatarSize.small,
            )
          ]),
        body: BlocBuilder<TripBloc, TripState>(
          builder: (context, state) {
            final trip = state.trip;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('SELECT A TRIP'),
                  _buildTripDropdown(context, trip.name), 
                  const SizedBox(height: 20),

                  const SectionLabel('LOCATION PLANNED'),
                  HorizontalScrollList(
                    height: 100,
                    itemCount: 5,
                    itemBuilder: (context, index) => const LocationCard(
                      locationName: 'Location',
                      imageAsset: 'assets/car.png',
                    ),
                  ),
                  const SizedBox(height: 20),

                  const SectionLabel('ROUTE'),
                  SizedBox(
                    height: 300, 
                    child: CustomGoogleMap(
                      locations: const [LatLng(37.3496, -121.9390)],
                      extraMarkers: {
                        const Marker(markerId: MarkerId('scu'), position: LatLng(37.3496, -121.9390)),
                        const Marker(markerId: MarkerId('camp1'), position: LatLng(37.3510, -121.9410)),
                        const Marker(markerId: MarkerId('camp2'), position: LatLng(37.3480, -121.9350)),
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  FullWidthButton(
                    text: 'Add Location',
                    onPressed: () {
                      GoRouter.of(context).goNamed(MyRoutes.campsiteSelector.name);
                    },
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 20),

                  _buildDatePicker(context, 'START DATE', trip.startDate, true),
                  _buildDatePicker(context, 'END DATE', trip.endDate, false),
                  const SizedBox(height: 20),

                  const SectionLabel('YOUR IMAGES'),
                  HorizontalScrollList(
                    height: 100,
                    itemCount: 10,
                    itemBuilder: (context, index) => const RemovableImageCard(
                      imageAsset: 'assets/car.png',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FullWidthButton(
                    text: 'Add Photo',
                    onPressed: () {},
                    color: colorScheme.primary, 
                  ),
                  const SizedBox(height: 20),

                  const SectionLabel('SUPPLIES BROUGHT'),
                  HorizontalScrollList(
                    height: 100,
                    itemCount: 4,
                    itemBuilder: (context, index) => const RemovableImageCard(
                      imageAsset: 'assets/car.png',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FullWidthButton(
                    text: 'Add Supply',
                    onPressed: () {},
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 20),

                  const SectionLabel('TRIP NOTES'),
                  _buildNotesBox(context, trip.notes), 
                  const SizedBox(height: 20),

                  const SectionLabel('FRIENDS'),
                  _buildFriendsList(context),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: FullWidthButton(
                          text: 'Finished Trip',
                          color: colorScheme.primary,
                          onPressed: () {
                            GoRouter.of(context).goNamed(MyRoutes.profile.name);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FullWidthButton(
                          text: 'Delete Trip',
                          color: colorScheme.secondary,
                          onPressed: () {
                            GoRouter.of(context).goNamed(MyRoutes.profile.name);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

Widget _buildTripDropdown(BuildContext context, String currentTripName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface, 
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), // Optional: adds a subtle border
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentTripName,
          isExpanded: true,
          items: ['Trip Name 1', 'Trip Name 2']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) {},
        ),
      ),
    );
  }

  Widget _buildNotesBox(BuildContext context, String initialNotes) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        // Changed from surfaceVariant to surface for a white background
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), // Optional: adds a subtle border
      ),
      child: Scrollbar(
        child: TextField(
          controller: TextEditingController(text: initialNotes),
          maxLines: null,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Enter trip notes here...',
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, String label, DateTime date, bool isStart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        GestureDetector(
          onTap: () => _selectDate(context, isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_month, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFriendsList(BuildContext context) {
    return Row(
      children: [
        ...List.generate(5, (index) => Padding( // TODO: get friends from trip instead of hardcoding 5
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: const Icon(Icons.account_circle, size: 36),
            onPressed: () {
              // TODO: select specific friend
              GoRouter.of(context).goNamed(MyRoutes.profile.name);
            },
          ),
        )),
        
        IconButton(
          icon: Icon(
            Icons.add_circle, 
            color: Theme.of(context).focusColor, 
            size: 36
          ),
          onPressed: () {
            // TODO: go to version of page with selection options isntead
            GoRouter.of(context).goNamed(MyRoutes.profileFriends.name);
          },
        ),
      ],
    );
  }

  void _selectDate(BuildContext context, bool isStart) async {
    final colorScheme = Theme.of(context).colorScheme;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: colorScheme.copyWith(
              primary: colorScheme.secondary, // Uses light green for picker primary
              onPrimary: colorScheme.onSecondary,
              onSurface: colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {}
  }
}