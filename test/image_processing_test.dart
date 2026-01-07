import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:skindetect/features/scan/data/image_processing.dart';

void main() {
  test('resizeToSquare makes a 416x416 image', () {
    final original = img.Image(width: 640, height: 480);
    final resized = resizeToSquare(original, 416);
    expect(resized.width, 416);
    expect(resized.height, 416);
  });

  test('cropNormalizedRect crops correct region', () {
    final original = img.Image(width: 100, height: 200);
    final cropped = cropNormalizedRect(original, left: 0.25, top: 0.25, width: 0.5, height: 0.5);
    expect(cropped.width, 50);
    expect(cropped.height, 100);
  });

  test('normalizeScanWindowToImage maps center square on portrait screen', () {
    final screen = const Size(1080, 1920);
    final preview = const Size(1920, 1080); // landscape camera
    final double scanSide = screen.width * 0.85;
    final Rect scanWindow = Rect.fromCenter(
      center: Offset(screen.width / 2, screen.height / 2),
      width: scanSide,
      height: scanSide,
    );

    final Rect norm = normalizeScanWindowToImage(
      scanWindow: scanWindow,
      screenSize: screen,
      previewSize: preview,
    );

    // Expect centered normalized rect;
    expect(norm.left, closeTo(0.075, 0.05));
    expect(norm.top, closeTo(0.26, 0.05));
    expect(norm.width, closeTo(0.85, 0.05));
    expect(norm.height, closeTo(0.48, 0.05));
  });
}
