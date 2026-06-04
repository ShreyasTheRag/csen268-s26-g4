import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:santa_clara/repositories/trip_image_repository.dart';
import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';

class TakePicturePage extends StatefulWidget {
  const TakePicturePage({super.key, required this.tripId});

  final String tripId;

  @override
  State<TakePicturePage> createState() => _TakePicturePageState();
}

class _TakePicturePageState extends State<TakePicturePage> {
  final TripImageRepository _imageRepository = TripImageRepository();
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _errorMessage;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (kIsWeb) {
      setState(() {
        _isInitializing = false;
        _errorMessage = null;
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'No camera found on this device.';
        });
        return;
      }
      await _setCamera(_cameraIndex);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Could not open camera: $e';
      });
    }
  }

  Future<void> _setCamera(int index) async {
    await _controller?.dispose();
    _cameraIndex = index;
    final camera = _cameras[_cameraIndex];
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _isInitializing = false;
      _errorMessage = null;
    });
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    setState(() => _isInitializing = true);
    final nextIndex = (_cameraIndex + 1) % _cameras.length;
    await _setCamera(nextIndex);
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) return;
    if (widget.tripId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No trip selected. Go back and try again.')),
      );
      return;
    }

    setState(() {
      _isCapturing = true;
      _statusMessage = 'Taking photo...';
    });

    try {
      String localPath;

      if (kIsWeb) {
        final picker = ImagePicker();
        final photo = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        if (photo == null) return;
        localPath = photo.path;
      } else {
        final controller = _controller;
        if (controller == null || !controller.value.isInitialized) {
          throw Exception('Camera is not ready');
        }
        final photo = await controller.takePicture();
        localPath = photo.path;
      }

      if (!mounted) return;
      setState(() => _statusMessage = 'Uploading photo...');

      final downloadUrl = await _imageRepository.uploadTripImage(
        tripId: widget.tripId,
        localPath: localPath,
      );

      if (mounted) {
        context.pop(downloadUrl);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save photo: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _statusMessage = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: const MainDrawer(),
      appBar: AppBar(
        title: const Text('Take a Picture'),
        actions: const [
          LoggedInUserAvatar(userAvatarSize: UserAvatarSize.small),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildPreview(colorScheme),
                Positioned(
                  top: 16,
                  left: 16,
                  child: _BackButton(
                    onPressed: () => context.pop(),
                    color: colorScheme.primary,
                  ),
                ),
                if (_isCapturing)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          if (_statusMessage != null) ...[
                            const SizedBox(height: 16),
                            Text(
                              _statusMessage!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _CameraControlsBar(
            colorScheme: colorScheme,
            onFlipCameraTap: kIsWeb ? null : _flipCamera,
            onShutterTap: _capturePhoto,
            shutterEnabled: !_isInitializing && _errorMessage == null,
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(ColorScheme colorScheme) {
    if (_isInitializing) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_camera_outlined,
                  size: 64, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              if (kIsWeb) ...[
                const SizedBox(height: 16),
                const Text(
                  'On web, use the shutter button to open the browser camera.',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (kIsWeb) {
      return Container(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.photo_camera_outlined,
            size: 80,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return Container(color: colorScheme.surfaceContainerHighest);
    }

    return CameraPreview(controller);
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({
    required this.onPressed,
    required this.color,
  });

  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Back',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraControlsBar extends StatelessWidget {
  const _CameraControlsBar({
    required this.colorScheme,
    required this.onShutterTap,
    required this.shutterEnabled,
    this.onFlipCameraTap,
  });

  final ColorScheme colorScheme;
  final VoidCallback onShutterTap;
  final VoidCallback? onFlipCameraTap;
  final bool shutterEnabled;

  @override
  Widget build(BuildContext context) {
    final Color barColor = colorScheme.primaryContainer;
    final Color buttonColor = colorScheme.primary;
    final Color onButtonColor = colorScheme.onPrimary;

    return Container(
      width: double.infinity,
      color: barColor,
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 52, height: 52),
          _ShutterButton(
            outerColor: buttonColor,
            innerColor: colorScheme.secondary,
            onPressed: shutterEnabled ? onShutterTap : null,
          ),
          _CircleControlButton(
            color: buttonColor,
            onPressed: onFlipCameraTap,
            child: Icon(
              Icons.cameraswitch,
              color: onFlipCameraTap != null ? onButtonColor : onButtonColor.withValues(alpha: 0.4),
              size: 26,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleControlButton extends StatelessWidget {
  const _CircleControlButton({
    required this.color,
    required this.onPressed,
    required this.child,
  });

  final Color color;
  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    required this.outerColor,
    required this.innerColor,
    required this.onPressed,
  });

  final Color outerColor;
  final Color innerColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed != null ? 1 : 0.5,
        child: Container(
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: outerColor,
            border: Border.all(color: outerColor.withValues(alpha: 0.6), width: 4),
          ),
          child: Center(
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: innerColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
