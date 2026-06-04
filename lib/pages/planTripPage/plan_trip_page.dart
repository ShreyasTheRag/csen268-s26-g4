import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:santa_clara/blocs/authentication/bloc/authentication_bloc.dart';
import 'package:santa_clara/blocs/trip_bloc.dart';
import 'package:santa_clara/models/campsite.dart';
import 'package:santa_clara/models/take_picture_args.dart';
import 'package:santa_clara/models/trip_model.dart';
import 'package:santa_clara/models/trip_reminder_option.dart';
import 'package:santa_clara/navigation/my_routes.dart';
import 'package:santa_clara/widgets/animated_reminder_chip.dart';
import 'package:santa_clara/widgets/attendee_avatar.dart';
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
  final TextEditingController _startTimeController = TextEditingController();
  final FocusNode _startTimeFocusNode = FocusNode();
  String? _startTimeFieldTripId;

  /// Cached so Bloc rebuilds (e.g. reminder chips) do not refetch campsites.
  late final Future<List<Campsite>> _campsitesFuture =
      Campsite.getNearbyCampsites();

  @override
  void dispose() {
    _startTimeController.dispose();
    _startTimeFocusNode.dispose();
    super.dispose();
  }

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

  Future<void> _openCamera(
    BuildContext context,
    String tripId, {
    bool forSupplies = false,
  }) async {
    final imageUrl = await GoRouter.of(context).pushNamed<String>(
      MyRoutes.takePicture.name,
      extra: TakePictureArgs(tripId: tripId, forSupplies: forSupplies),
    );
    if (imageUrl != null && context.mounted) {
      context.read<TripBloc>().add(
            AddTripImageUrlEvent(imageUrl, isSupply: forSupplies),
          );
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
              final friends = trip.attendees.toList();

              return FutureBuilder<List<Campsite>>(
                future: _campsitesFuture,
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
                                    matchingCampsite?.imgURLs[0] ?? 'assets/car.png',
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
                        _buildStartDateTime(context, trip.startDate, trip.id),
                        _buildDatePicker(
                          context,
                          'END DATE',
                          trip.endDate,
                          isStart: false,
                        ),
                        _buildReminderSelector(context, trip),
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
                              isSupply: true,
                            );
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
                              text: 'Add Supply',
                              onPressed: () =>
                                  _openCamera(context, trip.id, forSupplies: true),
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SectionLabel('TRIP NOTES'),
                        _buildNotesBox(context, trip.notes),
                        const SizedBox(height: 20),
                        const SectionLabel('ATTENDEES'),
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
    bool isSupply = false,
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
                  context.read<TripBloc>().add(
                        RemoveTripImageEvent(url, isSupply: isSupply),
                      );
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

  void _syncStartTimeField(DateTime startDate, String tripId) {
    if (_startTimeFieldTripId != tripId) {
      _startTimeFieldTripId = tripId;
      _startTimeController.text = _formatTime(startDate);
    } else if (!_startTimeFocusNode.hasFocus) {
      final formatted = _formatTime(startDate);
      if (_startTimeController.text != formatted) {
        _startTimeController.text = formatted;
      }
    }
  }

  void _applyTypedStartTime(BuildContext context, DateTime startDate) {
    final parsed = _parseTypedTime(_startTimeController.text, startDate);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Use a time like 9:00 AM, 9:00, or 21:30'),
        ),
      );
      _startTimeController.text = _formatTime(startDate);
      return;
    }
    _startTimeController.text = _formatTime(parsed);
    context.read<TripBloc>().add(
          UpdateTripDateEvent(date: parsed, isStart: true),
        );
  }

  Widget _buildStartDateTime(
    BuildContext context,
    DateTime startDate,
    String tripId,
  ) {
    _syncStartTimeField(startDate, tripId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('START'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildPickerTile(
                context,
                icon: Icons.calendar_month,
                label: _formatDate(startDate),
                onTap: () => _selectDate(
                  context,
                  current: startDate,
                  isStart: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _startTimeController,
                focusNode: _startTimeFocusNode,
                decoration: InputDecoration(
                  labelText: 'Start time',
                  hintText: '9:00 AM',
                  isDense: true,
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.schedule),
                    tooltip: 'Pick from clock',
                    onPressed: () => _selectStartTime(context, startDate),
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _applyTypedStartTime(context, startDate),
                onEditingComplete: () {
                  _applyTypedStartTime(context, startDate);
                  _startTimeFocusNode.unfocus();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Parses 9:00 AM, 9:30 PM, 9:00, or 21:30 against [date]'s calendar day.
  DateTime? _parseTypedTime(String input, DateTime date) {
    var text = input.trim().toUpperCase();
    if (text.isEmpty) return null;

    var isPm = false;
    var isAm = false;
    if (text.endsWith(' AM')) {
      isAm = true;
      text = text.substring(0, text.length - 3).trim();
    } else if (text.endsWith(' PM')) {
      isPm = true;
      text = text.substring(0, text.length - 3).trim();
    } else if (text.endsWith('AM')) {
      isAm = true;
      text = text.substring(0, text.length - 2).trim();
    } else if (text.endsWith('PM')) {
      isPm = true;
      text = text.substring(0, text.length - 2).trim();
    }

    final parts = text.split(':');
    if (parts.length != 2) return null;

    final hourPart = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hourPart == null || minute == null || minute < 0 || minute > 59) {
      return null;
    }

    int hour24;
    if (isPm || isAm) {
      if (hourPart < 1 || hourPart > 12) return null;
      hour24 = isPm
          ? (hourPart == 12 ? 12 : hourPart + 12)
          : (hourPart == 12 ? 0 : hourPart);
    } else {
      if (hourPart < 0 || hourPart > 23) return null;
      hour24 = hourPart;
    }

    return DateTime(date.year, date.month, date.day, hour24, minute);
  }

  Widget _buildDatePicker(
    BuildContext context,
    String label,
    DateTime date, {
    required bool isStart,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        _buildPickerTile(
          context,
          icon: Icons.calendar_month,
          label: _formatDate(date),
          onTap: () => _selectDate(
            context,
            current: date,
            isStart: isStart,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildPickerTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/'
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final period = hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$displayHour:$minute $period';
  }

  String _formatStartDateTime(DateTime startDate) {
    return '${_formatDate(startDate)} at ${_formatTime(startDate)}';
  }

  Widget _buildReminderSelector(BuildContext context, Trip trip) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('REMIND ME'),
        Text(
          'Before trip start (${_formatStartDateTime(trip.startDate)})',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: TripReminderOption.values.map((option) {
            final selected = trip.reminderOptions.contains(option);
            return AnimatedReminderChip(
              label: option.label,
              selected: selected,
              onSelected: (enabled) {
                final updated =
                    List<TripReminderOption>.from(trip.reminderOptions);
                if (enabled) {
                  if (!updated.contains(option)) updated.add(option);
                } else {
                  updated.remove(option);
                }
                context.read<TripBloc>().add(UpdateTripRemindersEvent(updated));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _selectDate(
    BuildContext context, {
    required DateTime current,
    required bool isStart,
  }) async {
    final colorScheme = Theme.of(context).colorScheme;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current,
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
      final merged = DateTime(
        picked.year,
        picked.month,
        picked.day,
        current.hour,
        current.minute,
      );
      context.read<TripBloc>().add(
            UpdateTripDateEvent(date: merged, isStart: isStart),
          );
    }
  }

  Future<void> _selectStartTime(
    BuildContext context,
    DateTime current,
  ) async {
    final colorScheme = Theme.of(context).colorScheme;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
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
      final merged = DateTime(
        current.year,
        current.month,
        current.day,
        picked.hour,
        picked.minute,
      );
      _startTimeController.text = _formatTime(merged);
      context.read<TripBloc>().add(
            UpdateTripDateEvent(date: merged, isStart: true),
          );
    }
  }

  Widget _buildFriendsList(BuildContext context, List<String> friendIds) {
    return Row(
      children: [
        ...friendIds.map(
          (id) => Padding(
            padding: const EdgeInsets.only(right: 12.0), // Extra spacing for round avatars
            child: AttendeeAvatar(
              userId: id,
              onTap: () {
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
