import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:santa_clara/blocs/authentication/bloc/authentication_bloc.dart';
import 'package:santa_clara/blocs/trip_bloc.dart';
import 'package:santa_clara/models/campsite.dart';
import 'package:santa_clara/models/trip_model.dart';
import 'package:santa_clara/navigation/my_routes.dart';
import 'package:santa_clara/widgets/google_maps.dart';
import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';
import 'package:santa_clara/widgets/trip_image_thumbnail.dart';

import '../../widgets/full_width_button.dart';
import '../../widgets/horizontal_scroll_list.dart';
import '../../widgets/location_card.dart';
import '../../widgets/section_label.dart';

class PlanTripPage extends StatefulWidget {
  const PlanTripPage({super.key});

  @override
  State<PlanTripPage> createState() => _PlanTripPageState();
}

class _PlanTripPageState extends State<PlanTripPage> {
  bool _tripsLoaded = false;

  void _showCreateTripDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create New Trip'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter trip name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  context.read<TripBloc>().add(
                        CreateNewTripEvent(controller.text.trim()),
                      );
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openCamera(BuildContext context, String tripId) async {
    final imageUrl = await GoRouter.of(context).pushNamed<String>(
      MyRoutes.takePicture.name,
      extra: tripId,
    );
    if (imageUrl != null && context.mounted) {
      context.read<TripBloc>().add(AddTripImageUrlEvent(imageUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, authState) {
        if (authState is! AuthenticationSignedInState) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            drawer: const MainDrawer(),
            appBar: AppBar(title: const Text('Plan a Trip')),
            body: const Center(
              child: Text('Please sign in to view and plan your trips.'),
            ),
          );
        }

        if (!_tripsLoaded) {
          _tripsLoaded = true;
          context.read<TripBloc>().add(
                LoadUserTrips(
                  authState.user.email,
                  uid: authState.user.uid,
                ),
              );
        }

        return Scaffold(
          backgroundColor: colorScheme.surface,
          drawer: const MainDrawer(),
          appBar: AppBar(
            title: const Text('Plan a Trip'),
            actions: const [
              LoggedInUserAvatar(userAvatarSize: UserAvatarSize.small),
            ],
          ),
          body: BlocConsumer<TripBloc, TripState>(
            listener: (context, tripState) {
              if (tripState.status == TripStatus.successAction) {
                GoRouter.of(context).goNamed(MyRoutes.profile.name);
              } else if (tripState.status == TripStatus.failure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(tripState.errorMessage ?? 'An error occurred.'),
                  ),
                );
              } else if (tripState.status == TripStatus.uploadingImage) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Uploading photo...')),
                );
              }
            },
            builder: (context, tripState) {
              if (tripState.status == TripStatus.loading ||
                  tripState.status == TripStatus.initial) {
                return const Center(child: CircularProgressIndicator());
              }

              if (tripState.allTrips.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No active planned trips found.'),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateTripDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Create a Trip'),
                      ),
                    ],
                  ),
                );
              }

              final trip = tripState.selectedTrip ?? tripState.allTrips.first;
              final friends = trip.attendees
                  .where((id) => id != tripState.currentUserId)
                  .toList();

              return FutureBuilder<List<Campsite>>(
                future: Campsite.getNearbyCampsites(),
                builder: (context, campsiteSnapshot) {
                  if (campsiteSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<Campsite> matchingCampsites = [];
                  if (campsiteSnapshot.hasData && campsiteSnapshot.data != null) {
                    matchingCampsites = campsiteSnapshot.data!
                        .whereType<Campsite>()
                        .where((c) => trip.locations.contains(c.name))
                        .toList();
                  }

                  final Set<Marker> routeMarkers = matchingCampsites.map((campsite) {
                    return Marker(
                      markerId: MarkerId(campsite.id),
                      position: campsite.position,
                      infoWindow: InfoWindow(title: campsite.name),
                    );
                  }).toSet();

                  final LatLng mapCenter = matchingCampsites.isNotEmpty
                      ? matchingCampsites.first.position
                      : const LatLng(37.3496, -121.9390);

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel('SELECT A TRIP'),
                        Row(
                          children: [
                            Expanded(child: _buildTripDropdown(context, tripState)),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              onPressed: () => _showCreateTripDialog(context),
                              icon: const Icon(Icons.add),
                              style: IconButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const SectionLabel('LOCATION PLANNED'),
                        if (trip.locations.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No locations added to this trip yet.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        else
                          HorizontalScrollList(
                            height: 100,
                            itemCount: trip.locations.length,
                            itemBuilder: (context, index) {
                              final String locName = trip.locations[index];
                              final matches = matchingCampsites
                                  .where((c) => c.name == locName);
                              final Campsite? matchingCampsite =
                                  matches.isNotEmpty ? matches.first : null;

                              return LocationCard(
                                locationName: locName,
                                imageAsset:
                                    matchingCampsite?.imgURL ?? 'assets/car.png',
                                imageIsWeb: matchingCampsite != null,
                              );
                            },
                          ),
                        const SizedBox(height: 20),
                        const SectionLabel('ROUTE'),
                        SizedBox(
                          height: 300,
                          child: CustomGoogleMap(
                            locations: [mapCenter],
                            extraMarkers: routeMarkers,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FullWidthButton(
                          text: 'Add Location',
                          onPressed: () {
                            GoRouter.of(context)
                                .pushNamed(MyRoutes.campsiteSelector.name);
                          },
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 20),
                        _buildDatePicker(context, 'START DATE', trip.startDate, true),
                        _buildDatePicker(context, 'END DATE', trip.endDate, false),
                        const SizedBox(height: 20),
                        const SectionLabel('YOUR IMAGES'),
                        if (tripState.status == TripStatus.uploadingImage)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: LinearProgressIndicator(),
                          ),
                        HorizontalScrollList(
                          height: 100,
                          itemCount: trip.images.isEmpty ? 1 : trip.images.length,
                          itemBuilder: (context, index) {
                            if (trip.images.isEmpty) {
                              return const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No images yet'),
                                ),
                              );
                            }
                            return _buildImageCard(context, trip.images[index]);
                          },
                        ),
                        const SizedBox(height: 12),
                        IgnorePointer(
                          ignoring: tripState.status == TripStatus.uploadingImage,
                          child: Opacity(
                            opacity:
                                tripState.status == TripStatus.uploadingImage
                                    ? 0.5
                                    : 1,
                            child: FullWidthButton(
                              text: 'Add Photo',
                              onPressed: () => _openCamera(context, trip.id),
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SectionLabel('SUPPLIES BROUGHT'),
                        HorizontalScrollList(
                          height: 100,
                          itemCount:
                              trip.suppliesImages.isEmpty ? 1 : trip.suppliesImages.length,
                          itemBuilder: (context, index) {
                            if (trip.suppliesImages.isEmpty) {
                              return const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No supplies listed'),
                                ),
                              );
                            }
                            return _buildImageCard(
                              context,
                              trip.suppliesImages[index],
                              removable: false,
                            );
                          },
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
                        _buildFriendsList(context, friends),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: FullWidthButton(
                                text: 'Finished Trip',
                                color: colorScheme.primary,
                                onPressed: () {
                                  context.read<TripBloc>().add(FinishTripEvent());
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: FullWidthButton(
                                text: 'Delete Trip',
                                color: colorScheme.secondary,
                                onPressed: () {
                                  context.read<TripBloc>().add(DeleteTripEvent());
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
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildImageCard(
    BuildContext context,
    String url, {
    bool removable = true,
  }) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => TripImageThumbnail.showPreview(context, url),
            child: TripImageThumbnail(imageSource: url),
          ),
          if (removable)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () {
                  context.read<TripBloc>().add(RemoveTripImageEvent(url));
                },
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripDropdown(BuildContext context, TripState state) {
    final currentTrip =
        state.selectedTrip ?? (state.allTrips.isNotEmpty ? state.allTrips.first : null);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Trip>(
          value: currentTrip,
          isExpanded: true,
          items: state.allTrips
              .map((t) => DropdownMenuItem<Trip>(value: t, child: Text(t.name)))
              .toList(),
          onChanged: (Trip? newTrip) {
            if (newTrip != null) {
              context.read<TripBloc>().add(SelectTrip(newTrip));
            }
          },
        ),
      ),
    );
  }

  Widget _buildNotesBox(BuildContext context, String initialNotes) {
    final TextEditingController controller =
        TextEditingController(text: initialNotes);
    final FocusNode focusNode = FocusNode();

    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        context.read<TripBloc>().add(UpdateTripNotesEvent(controller.text));
      }
    });

    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLines: null,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Enter trip notes here...',
        ),
      ),
    );
  }

  Widget _buildDatePicker(
    BuildContext context,
    String label,
    DateTime date,
    bool isStart,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        GestureDetector(
          onTap: () => _selectDate(context, isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
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
              primary: colorScheme.secondary,
              onPrimary: colorScheme.onSecondary,
              onSurface: colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && context.mounted) {
      context.read<TripBloc>().add(
            UpdateTripDateEvent(date: picked, isStart: isStart),
          );
    }
  }

  Widget _buildFriendsList(BuildContext context, List<String> friendIds) {
    return Row(
      children: [
        ...friendIds.map(
          (id) => Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.account_circle, size: 36),
              tooltip: id,
              onPressed: () {
                GoRouter.of(context).goNamed(MyRoutes.profile.name);
              },
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.add_circle, color: Theme.of(context).focusColor, size: 36),
          onPressed: () {
            GoRouter.of(context).goNamed(MyRoutes.profileFriends.name);
          },
        ),
      ],
    );
  }
}
