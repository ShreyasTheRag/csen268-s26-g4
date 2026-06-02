import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:santa_clara/blocs/authentication/bloc/authentication_bloc.dart';

import 'package:santa_clara/blocs/trip_bloc.dart';
import 'package:santa_clara/models/trip_model.dart'; 
import 'package:santa_clara/navigation/my_routes.dart';
import 'package:santa_clara/widgets/google_maps.dart';
import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';

import '../../widgets/full_width_button.dart';
import '../../widgets/horizontal_scroll_list.dart';
import '../../widgets/location_card.dart';
import '../../widgets/section_label.dart';

class PlanTripPage extends StatelessWidget {
  const PlanTripPage({super.key});

  // Dialog Helper prompt to create a new trip
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
                  // Dispatch creation event to the original context Bloc
                  BlocProvider.of<TripBloc>(context).add(
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<AuthenticationBloc, AuthenticationState>(
      builder: (context, authState) {
        if (authState is! AuthenticationSignedInState) {
          return Scaffold(
            backgroundColor: colorScheme.surface,
            drawer: const MainDrawer(),
            appBar: AppBar(title: const Text("Plan a Trip")),
            body: const Center(
              child: Text("Please sign in to view and plan your trips."),
            ),
          );
        }

        final String loggedInUserEmail = authState.user.email;

        return BlocProvider(
          create: (context) => TripBloc()..add(LoadUserTrips(loggedInUserEmail)),
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            drawer: const MainDrawer(),
            appBar: AppBar(
              title: const Text("Plan a Trip"),
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
                    SnackBar(content: Text(tripState.errorMessage ?? 'An error occurred.')),
                  );
                }
              },
              builder: (context, tripState) {
                if (tripState.status == TripStatus.loading || tripState.status == TripStatus.initial) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (tripState.allTrips.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("No active planned trips found."),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showCreateTripDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text("Create a Trip"),
                        )
                      ],
                    ),
                  );
                }

                final trip = tripState.selectedTrip!;
                final friends = trip.attendees.where((id) => id != tripState.currentUserId).toList();

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
                              foregroundColor: colorScheme.onPrimary, // Ensures the '+' icon has good contrast
                            ),
                          ),
                        ],
                      ),
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
                        itemCount: trip.images.isEmpty ? 1 : trip.images.length,
                        itemBuilder: (context, index) {
                          if (trip.images.isEmpty) {
                            return const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No images yet")));
                          }
                          return _buildNetworkImageCard(trip.images[index]);
                        },
                      ),
                      const SizedBox(height: 12),
                      FullWidthButton(
                        text: 'Add Photo',
                        onPressed: () {
                          GoRouter.of(context).pushNamed(MyRoutes.takePicture.name);
                        },
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 20),

                      const SectionLabel('SUPPLIES BROUGHT'),
                      HorizontalScrollList(
                        height: 100,
                        itemCount: trip.suppliesImages.isEmpty ? 1 : trip.suppliesImages.length,
                        itemBuilder: (context, index) {
                          if (trip.suppliesImages.isEmpty) {
                            return const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No supplies listed")));
                          }
                          return _buildNetworkImageCard(trip.suppliesImages[index]);
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
                                BlocProvider.of<TripBloc>(context).add(FinishTripEvent());
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FullWidthButton(
                              text: 'Delete Trip',
                              color: colorScheme.secondary,
                              onPressed: () {
                                BlocProvider.of<TripBloc>(context).add(DeleteTripEvent());
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
      },
    );
  }

  // Unified dynamic widget rendering for Cloud Storage network images cleanly
  Widget _buildNetworkImageCard(String url) {
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
          Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Center(child: Icon(Icons.broken_image, color: Colors.red));
            },
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                // Handle image removal if needed
              },
              child: Container(
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTripDropdown(BuildContext context, TripState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Trip>(
          value: state.selectedTrip,
          isExpanded: true,
          items: state.allTrips
              .map((trip) => DropdownMenuItem<Trip>(
                    value: trip,
                    child: Text(trip.name),
                  ))
              .toList(),
          onChanged: (Trip? newTrip) {
            if (newTrip != null) {
              BlocProvider.of<TripBloc>(context).add(SelectTrip(newTrip));
            }
          },
        ),
      ),
    );
  }

  Widget _buildNotesBox(BuildContext context, String initialNotes) {
    final TextEditingController controller = TextEditingController(text: initialNotes);
    final FocusNode focusNode = FocusNode();

    // Listen for when user clicks away from the notes box to trigger a auto-save
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        BlocProvider.of<TripBloc>(context).add(
          UpdateTripNotesEvent(controller.text),
        );
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
      child: Scrollbar(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: null,
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Enter trip notes here...',
          ),
          onEditingComplete: () {
            focusNode.unfocus(); 
          },
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
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

  Widget _buildFriendsList(BuildContext context, List<String> friendIds) {
    return Row(
      children: [
        ...friendIds.map((id) => Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: const Icon(Icons.account_circle, size: 36),
                tooltip: id,
                onPressed: () {
                  GoRouter.of(context).goNamed(MyRoutes.profile.name);
                },
              ),
            )),
        IconButton(
          icon: Icon(Icons.add_circle, color: Theme.of(context).focusColor, size: 36),
          onPressed: () {
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
              primary: colorScheme.secondary,
              onPrimary: colorScheme.onSecondary,
              onSurface: colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      BlocProvider.of<TripBloc>(context).add(
        UpdateTripDateEvent(date: picked, isStart: isStart),
      );
    }
  }
}