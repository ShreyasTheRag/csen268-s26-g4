import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Displays a trip photo from a network URL, base64 data URL, or local file path.
class TripImageThumbnail extends StatelessWidget {
  const TripImageThumbnail({
    super.key,
    required this.imageSource,
    this.fit = BoxFit.cover,
  });

  final String imageSource;
  final BoxFit fit;

  static void showPreview(BuildContext context, String imageSource) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              SizedBox(
                width: size.width - 32,
                height: size.height * 0.75,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: Center(
                    child: TripImageThumbnail(
                      imageSource: imageSource,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageSource.startsWith('data:')) {
      return _buildDataUrlImage(imageSource);
    }
    if (imageSource.startsWith('http://') || imageSource.startsWith('https://')) {
      return Image.network(
        imageSource,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _errorIcon(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      );
    }
    if (!kIsWeb && imageSource.startsWith('/')) {
      return Image.file(
        File(imageSource),
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _errorIcon(),
      );
    }
    return _errorIcon();
  }

  Widget _buildDataUrlImage(String dataUrl) {
    try {
      final commaIndex = dataUrl.indexOf(',');
      if (commaIndex == -1) return _errorIcon();

      final bytes = base64Decode(dataUrl.substring(commaIndex + 1));
      if (bytes.isEmpty) return _errorIcon();

      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _errorIcon(),
      );
    } catch (_) {
      return _errorIcon();
    }
  }

  Widget _errorIcon() {
    return const Center(
      child: Icon(Icons.broken_image, color: Colors.red, size: 28),
    );
  }
}
