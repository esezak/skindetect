import 'dart:ui';
import 'package:image/image.dart' as img;

/// Resize an image to a square of [targetSize] using a cover strategy and center-crop.
img.Image resizeToSquare(img.Image source, int targetSize) {
  // If already square, just resize directly.
  if (source.width == source.height) {
    return img.copyResize(source, width: targetSize, height: targetSize);
  }

  // Determine scale to cover the square while preserving aspect ratio.
  final double scale = source.width > source.height
      ? targetSize / source.height
      : targetSize / source.width;
  final int resizedWidth = (source.width * scale).round();
  final int resizedHeight = (source.height * scale).round();

  final img.Image resized = img.copyResize(source, width: resizedWidth, height: resizedHeight);

  // Center-crop to the square.
  final int xOffset = ((resizedWidth - targetSize) / 2).round();
  final int yOffset = ((resizedHeight - targetSize) / 2).round();

  return img.copyCrop(resized, x: xOffset, y: yOffset, width: targetSize, height: targetSize);
}

/// Crop the source image to the given rectangle in source pixel coordinates.
img.Image cropImage(img.Image source, {required int left, required int top, required int width, required int height}) {
  final int safeLeft = left.clamp(0, source.width - 1);
  final int safeTop = top.clamp(0, source.height - 1);
  final int safeWidth = width.clamp(1, source.width - safeLeft);
  final int safeHeight = height.clamp(1, source.height - safeTop);
  return img.copyCrop(source, x: safeLeft, y: safeTop, width: safeWidth, height: safeHeight);
}

/// Convert a normalized rectangle (0..1) to pixel coordinates in the source image.
img.Image cropNormalizedRect(img.Image source, {required double left, required double top, required double width, required double height}) {
  final int pxLeft = (left * source.width).round();
  final int pxTop = (top * source.height).round();
  final int pxWidth = (width * source.width).round();
  final int pxHeight = (height * source.height).round();
  return cropImage(source, left: pxLeft, top: pxTop, width: pxWidth, height: pxHeight);
}

/// Map the on-screen scan window to normalized image coordinates (0..1) using the CameraPreview cover fit.
Rect normalizeScanWindowToImage({required Rect scanWindow, required Size screenSize, required Size previewSize}) {
  // Camera gives landscape preview sizes; swap to portrait for mapping.
  final double previewPortraitWidth = previewSize.height;
  final double previewPortraitHeight = previewSize.width;
  final double previewAspect = previewPortraitWidth / previewPortraitHeight;
  final double screenAspect = screenSize.width / screenSize.height;

  double displayWidth;
  double displayHeight;
  double offsetX = 0;
  double offsetY = 0;

  if (previewAspect > screenAspect) {
    final double scale = screenSize.height / previewPortraitHeight;
    displayWidth = previewPortraitWidth * scale;
    displayHeight = screenSize.height;
    offsetX = (displayWidth - screenSize.width) / 2;
  } else {
    final double scale = screenSize.width / previewPortraitWidth;
    displayWidth = screenSize.width;
    displayHeight = previewPortraitHeight * scale;
    offsetY = (displayHeight - screenSize.height) / 2;
  }

  final double left = (scanWindow.left + offsetX) / displayWidth;
  final double top = (scanWindow.top + offsetY) / displayHeight;
  final double width = scanWindow.width / displayWidth;
  final double height = scanWindow.height / displayHeight;

  return Rect.fromLTWH(
    left.clamp(0.0, 1.0),
    top.clamp(0.0, 1.0),
    width.clamp(0.0, 1.0),
    height.clamp(0.0, 1.0),
  );
}
