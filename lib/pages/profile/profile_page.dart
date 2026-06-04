import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import 'package:santa_clara/blocs/authentication/bloc/authentication_bloc.dart';
import 'package:santa_clara/models/campsite.dart';
import 'package:santa_clara/navigation/my_routes.dart';
import 'package:santa_clara/widgets/full_width_button.dart';
import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';

class UserProfileRepository {
  Future<void> uploadProfileImage({required String userId, required String localPath}) async {}
  Future<void> addEquipmentImage({required String userId, required String localPath}) async {}
  Future<void> removeEquipmentImage({required String userId, required String imageUrl}) async {}
  Future<void> updateProfileText({required String userId, required String name, required String handle}) async {}
}

class TripImageThumbnail extends StatelessWidget {
  final String imageSource;
  const TripImageThumbnail({super.key, required this.imageSource});
  static void showPreview(BuildContext context, String url) {}
  @override
  Widget build(BuildContext context) {
    return Image.network(imageSource, fit: BoxFit.cover);
  }
}

class Triad extends StatelessWidget {
  final List<String> keys;
  final List<String> values;
  final VoidCallback onSecondTap;
  const Triad({super.key, required this.keys, required this.values, required this.onSecondTap});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          BlocBuilder<AuthenticationBloc, AuthenticationState>(
            builder: (context, authState) {
              if (authState is! AuthenticationSignedInState) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
                tooltip: _isEditing ? 'Cancel editing' : 'Edit profile',
                onPressed: () => setState(() => _isEditing = !_isEditing),
              );
            },
          ),
          const LoggedInUserAvatar(userAvatarSize: UserAvatarSize.small),
        ],
      ),
      body: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        builder: (context, authState) {
          if (authState is! AuthenticationSignedInState) {
            return const Center(
              child: Text('Please sign in to view your profile.'),
            );
          }

          final String userEmail = authState.user.email;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('email', isEqualTo: userEmail)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _ProfileShimmerLoading();
              }

              if (snapshot.hasError) {
                return const Center(child: Text('Error loading profile.'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc('default_user')
                      .snapshots(),
                  builder: (context, defaultSnapshot) {
                    if (defaultSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const _ProfileShimmerLoading();
                    }
                    if (defaultSnapshot.hasError ||
                        !defaultSnapshot.hasData ||
                        !defaultSnapshot.data!.exists) {
                      return const Center(
                        child: Text('Profile data not found.'),
                      );
                    }

                    return _EditableProfileContent(
                      userId: defaultSnapshot.data!.id,
                      userEmail: userEmail,
                      userData: defaultSnapshot.data!.data()!,
                      isEditing: _isEditing,
                      onEditingDone: () => setState(() => _isEditing = false),
                    );
                  },
                );
              }

              final userDoc = snapshot.data!.docs.first;
              return _EditableProfileContent(
                userId: userDoc.id,
                userEmail: userEmail,
                userData: userDoc.data(),
                isEditing: _isEditing,
                onEditingDone: () => setState(() => _isEditing = false),
              );
            },
          );
        },
      ),
    );
  }
}

class _EditableProfileContent extends StatefulWidget {
  const _EditableProfileContent({
    required this.userId,
    required this.userEmail,
    required this.userData,
    required this.isEditing,
    required this.onEditingDone,
  });

  final String userId;
  final String userEmail;
  final Map<String, dynamic> userData;
  final bool isEditing;
  final VoidCallback onEditingDone;

  @override
  State<_EditableProfileContent> createState() =>
      _EditableProfileContentState();
}

class _EditableProfileContentState extends State<_EditableProfileContent> {
  final UserProfileRepository _repository = UserProfileRepository();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _nameController;
  late TextEditingController _handleController;
  bool _isUploading = false;
  String? _localProfilePreviewPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _handleController = TextEditingController();
    _applyUserDataToControllers();
  }

  @override
  void didUpdateWidget(covariant _EditableProfileContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userData != widget.userData && !_isUploading) {
      _applyUserDataToControllers();
    }
    if (!widget.isEditing && oldWidget.isEditing) {
      _applyUserDataToControllers();
    }
  }

  void _applyUserDataToControllers() {
    _nameController.text = widget.userData['name']?.toString() ?? '';
    _handleController.text =
        (widget.userData['handle']?.toString() ?? '').replaceFirst('@', '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  List<String> get _equipmentImages =>
      List<String>.from(widget.userData['equipment_images'] ?? []);

  String? get _profileImageUrl {
    final raw = widget.userData['profile_image']?.toString();
    if (raw == null || raw.trim().isEmpty) return null;
    return raw;
  }

  Future<ImageSource?> _pickImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo library'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage({required bool forProfile}) async {
    final source = await _pickImageSource();
    if (source == null || !mounted) return;

    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: forProfile ? 800 : 1200,
        maxHeight: forProfile ? 800 : 1200,
        imageQuality: forProfile ? 70 : 80,
      );
      if (picked == null || !mounted) return;

      setState(() {
        _isUploading = true;
        if (forProfile && !kIsWeb) {
          _localProfilePreviewPath = picked.path;
        }
      });

      if (forProfile) {
        await _repository.uploadProfileImage(
          userId: widget.userId,
          localPath: picked.path,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated')),
          );
        }
      } else {
        await _repository.addEquipmentImage(
          userId: widget.userId,
          localPath: picked.path,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Equipment photo added')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _localProfilePreviewPath = null;
        });
      }
    }
  }

  Future<void> _saveTextFields() async {
    try {
      await _repository.updateProfileText(
        userId: widget.userId,
        name: _nameController.text,
        handle: _handleController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved')),
        );
        widget.onEditingDone();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    }
  }

  Future<void> _removeEquipment(String imageUrl) async {
    try {
      await _repository.removeEquipmentImage(
        userId: widget.userId,
        imageUrl: imageUrl,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not remove image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsList = widget.userData['friends'] ?? [];
    final displayName = widget.userData['name']?.toString();
    final String userHandle = widget.userData['handle']?.toString() ?? '';
    final String queryUserId = widget.userId.trim();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('trips')
          .where('attendees', arrayContains: queryUserId)
          .snapshots(),
      builder: (context, tripsSnapshot) {
        List<QueryDocumentSnapshot<Map<String, dynamic>>> completedTrips = [];
        Set<String> locationsVisitedSet = {};

        if (tripsSnapshot.hasData) {
          for (var doc in tripsSnapshot.data!.docs) {
            final data = doc.data();
            final bool isFinished = data['completed'] == 1;
            if (isFinished) {
              completedTrips.add(doc);
              final locs = data['locations'];
              if (locs is List) {
                for (var l in locs) {
                  final cleanedLocation = l.toString().trim();
                  if (cleanedLocation.isNotEmpty) {
                    locationsVisitedSet.add(cleanedLocation);
                  }
                }
              }
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(1.0),
          child: Column(
            spacing: 10.0,
            children: [
              SizedBox(
                width: double.infinity,
                height: widget.isEditing ? 200 : 150,
                child: _buildAvatarSection(
                  userHandle: userHandle,
                  displayName: displayName,
                ),
              ),
              if (widget.isEditing) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _handleController,
                    decoration: const InputDecoration(
                      labelText: 'Handle',
                      prefixText: '@',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: FullWidthButton(
                    text: 'Save name & handle',
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: _saveTextFields,
                  ),
                ),
              ],
              Triad(
                keys: const ['Trips', 'Friends', 'Locations'],
                values: [
                  completedTrips.length.toString(),
                  friendsList.length.toString(),
                  locationsVisitedSet.length.toString(),
                ],
                onSecondTap: () =>
                    GoRouter.of(context).goNamed(MyRoutes.profileFriends.name),
              ),
              
              _buildCompletedTripsSection(completedTrips),
              _buildLocationsVisitedSection(locationsVisitedSet.toList()),
              
              _EquipmentSection(
                images: _equipmentImages,
                isEditing: widget.isEditing,
                onAdd: () => _pickImage(forProfile: false),
                onRemove: _removeEquipment,
                onTapImage: (url) => TripImageThumbnail.showPreview(context, url),
              ),
              if (widget.isEditing) const SizedBox(height: 24),
            ],
          ),
        );
      }
    );
  }

  Widget _buildCompletedTripsSection(List<QueryDocumentSnapshot<Map<String, dynamic>>> trips) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Completed Trips', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          if (trips.isEmpty)
            Text('No completed trips found.', style: TextStyle(color: Colors.grey[600], fontSize: 12))
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tripDoc in trips) ...[
                    _buildTripCard(tripDoc.data()),
                    const SizedBox(width: 15),
                  ]
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> tripData) {
    final String name = tripData['trip_name'] ?? tripData['name'] ?? 'Unnamed Trip'; // Handle database field variations
    final List images = tripData['images'] ?? [];
    
    // 💡 FIX: Clean up trailing whitespaces from the URL string coming from the database snapshot
    final String? firstImage = images.isNotEmpty ? images.first?.toString().trim() : null;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: (firstImage == null || firstImage.isEmpty) ? Colors.green : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: (firstImage != null && firstImage.isNotEmpty)
          ? Image.network(
              firstImage, 
              fit: BoxFit.cover, 
              errorBuilder: (c, e, s) => _buildFallbackText(name),
            )
          : _buildFallbackText(name),
    );
  }

  Widget _buildLocationsVisitedSection(List<String> locationNames) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Locations Visited', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8.0),
          if (locationNames.isEmpty)
            Text('No visited locations added yet.', style: TextStyle(color: Colors.grey[600], fontSize: 12))
          else
            FutureBuilder<List<Campsite>>(
              future: Campsite.getNearbyCampsites(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: SizedBox(
                      width: 24, 
                      height: 24, 
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final staticCampsites = snapshot.data ?? [];
                
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final locName in locationNames) ...[
                        _buildLocationCard(locName, staticCampsites),
                        const SizedBox(width: 15),
                      ]
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(String locationName, List<Campsite> matchingPool) {
    final match = matchingPool.where((c) => c.name.trim().toLowerCase() == locationName.trim().toLowerCase());
    final String? mappedImage = match.isNotEmpty ? match.first.imgURLs.first : null;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: mappedImage == null ? Colors.green : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: mappedImage != null
          ? Image.network(mappedImage, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildFallbackText(locationName))
          : _buildFallbackText(locationName),
    );
  }

  Widget _buildFallbackText(String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(
          title,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildAvatarSection({
    String? userHandle,
    String? displayName,
  }) {
    const radius = 40.0;
    final hasRemoteImage =
        _profileImageUrl != null && _profileImageUrl!.trim().isNotEmpty;
    final hasLocalPreview = _localProfilePreviewPath != null && !kIsWeb;

    Widget avatar = hasLocalPreview
        ? ClipOval(
            child: SizedBox(
              width: radius * 2,
              height: radius * 2,
              child: Image.file(
                File(_localProfilePreviewPath!),
                fit: BoxFit.cover,
              ),
            ),
          )
        : hasRemoteImage
            ? ClipOval(
                child: SizedBox(
                  width: radius * 2,
                  height: radius * 2,
                  child: TripImageThumbnail(imageSource: _profileImageUrl!),
                ),
              )
            : CircleAvatar(
                radius: radius,
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.person_outline,
                  size: radius,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              );

    if (widget.isEditing) {
      avatar = GestureDetector(
        onTap: () => _pickImage(forProfile: true),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            avatar,
            Positioned(
              right: -4,
              bottom: -4,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      );
    } else if (!hasRemoteImage && !hasLocalPreview) {
      avatar = LoggedInUserAvatar(
        userAvatarSize: UserAvatarSize.large,
        userHandle: userHandle,
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        avatar,
        if (_isUploading) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(minHeight: 3),
          Text(
            'Uploading photo…',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 8),
        if (!widget.isEditing && hasRemoteImage && !hasLocalPreview) ...[
          if (displayName != null && displayName.isNotEmpty)
            Text(
              displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          if (userHandle != null && userHandle.isNotEmpty) Text(userHandle),
        ],
        if (widget.isEditing)
          TextButton(
            onPressed: () => _pickImage(forProfile: true),
            child: const Text('Change profile photo'),
          ),
      ],
    );
  }
}

class _EquipmentSection extends StatelessWidget {
  const _EquipmentSection({
    required this.images,
    required this.isEditing,
    required this.onAdd,
    required this.onRemove,
    required this.onTapImage,
  });

  final List<String> images;
  final bool isEditing;
  final VoidCallback onAdd;
  final Future<void> Function(String url) onRemove;
  final void Function(String url) onTapImage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Equipment Willing To Share',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (isEditing) ...[
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add'),
            ),
          ],
          const SizedBox(height: 8),
          if (images.isEmpty)
            Text(
              isEditing
                  ? 'Tap Add to share gear photos with friends.'
                  : 'No equipment photos yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            )
          else
            Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  for (final url in images)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _EquipmentImageTile(
                        imageUrl: url,
                        isEditing: isEditing,
                        onTap: () => onTapImage(url),
                        onRemove: () => onRemove(url),
                      ),
                    ),
                  if (isEditing)
                    GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.primary),
                        ),
                        child: Icon(Icons.add, color: colorScheme.primary, size: 32),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EquipmentImageTile extends StatelessWidget {
  const _EquipmentImageTile({
    required this.imageUrl,
    required this.isEditing,
    required this.onTap,
    required this.onRemove,
  });

  final String imageUrl;
  final bool isEditing;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: TripImageThumbnail(imageSource: imageUrl),
            ),
          ),
          if (isEditing)
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: onRemove,
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
}

class _ProfileShimmerLoading extends StatelessWidget {
  const _ProfileShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            spacing: 25,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  3,
                  (_) => Container(
                    width: 80,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}