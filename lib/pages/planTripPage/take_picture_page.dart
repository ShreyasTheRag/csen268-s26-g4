import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:santa_clara/widgets/logged_in_user_avatar.dart';
import 'package:santa_clara/widgets/main_drawer.dart';

class TakePicturePage extends StatefulWidget {
  const TakePicturePage({super.key});

  @override
  State<TakePicturePage> createState() => _TakePicturePageState();
}

class _TakePicturePageState extends State<TakePicturePage> {
  String _zoomLabel = '1x';

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
                _CameraPreviewPlaceholder(colorScheme: colorScheme),
                Positioned(
                  top: 16,
                  left: 16,
                  child: _BackButton(
                    onPressed: () => context.pop(),
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          _CameraControlsBar(
            colorScheme: colorScheme,
            zoomLabel: _zoomLabel,
            onZoomTap: () {
              setState(() {
                _zoomLabel = _zoomLabel == '1x' ? '2x' : '1x';
              });
            },
            onShutterTap: () => context.pop(),
            onFlipCameraTap: () {},
          ),
        ],
      ),
    );
  }
}

class _CameraPreviewPlaceholder extends StatelessWidget {
  const _CameraPreviewPlaceholder({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
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
    required this.zoomLabel,
    required this.onZoomTap,
    required this.onShutterTap,
    required this.onFlipCameraTap,
  });

  final ColorScheme colorScheme;
  final String zoomLabel;
  final VoidCallback onZoomTap;
  final VoidCallback onShutterTap;
  final VoidCallback onFlipCameraTap;

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
          _CircleControlButton(
            color: buttonColor,
            onPressed: onZoomTap,
            child: Text(
              zoomLabel,
              style: TextStyle(
                color: onButtonColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          _ShutterButton(
            outerColor: buttonColor,
            innerColor: colorScheme.secondary,
            onPressed: onShutterTap,
          ),
          _CircleControlButton(
            color: buttonColor,
            onPressed: onFlipCameraTap,
            child: Icon(
              Icons.cameraswitch,
              color: onButtonColor,
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
  final VoidCallback onPressed;
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
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
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
    );
  }
}
