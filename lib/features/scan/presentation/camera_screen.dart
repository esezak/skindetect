import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../data/image_processing.dart';
import 'processing_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isFlashOn = false;
  late AnimationController _shutterController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    _initCamera();

    _shutterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.9,
      upperBound: 1.0,
    );
    _shutterController.value = 1.0;
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _initializeControllerFuture = _controller!.initialize().then((_) {
        if (!mounted) return;
        _controller!.setFocusMode(FocusMode.auto);
        setState(() {});
      });
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _shutterController.dispose();
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      await _shutterController.reverse();
      await _shutterController.forward();

      final image = await _controller!.takePicture();
      if (!mounted) return;

      final Size previewSize = _controller!.value.previewSize ?? Size.zero;
      if (previewSize == Size.zero) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProcessingScreen(imagePath: image.path),
          ),
        );
        return;
      }

      final Size screenSize = MediaQuery.of(context).size;
      final double scanAreaSize = screenSize.width * 0.85;
      final Rect scanWindow = Rect.fromCenter(
        center: Offset(screenSize.width / 2, screenSize.height / 2),
        width: scanAreaSize,
        height: scanAreaSize,
      );

      final Rect normalized = normalizeScanWindowToImage(
        scanWindow: scanWindow,
        screenSize: screenSize,
        previewSize: previewSize,
      );

      final croppedPath = await _cropToGuide(
        image.path,
        normalized.left,
        normalized.top,
        normalized.width,
        normalized.height,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProcessingScreen(imagePath: croppedPath ?? image.path),
        ),
      );
    } catch (e) {
      debugPrint("Error taking picture: $e");
    }
  }

  Future<String?> _cropToGuide(String path, double left, double top, double width, double height) async {
    try {
      final bytes = await XFile(path).readAsBytes();
      final img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) return path;
      final img.Image cropped = cropNormalizedRect(
        decoded,
        left: left,
        top: top,
        width: width,
        height: height,
      );
      final jpg = img.encodeJpg(cropped, quality: 95);
      final file = File(path);
      await file.writeAsBytes(jpg, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('Crop failed: $e');
      return path;
    }
  }

  void _toggleFlash() {
    if (_controller == null) return;
    setState(() {
      _isFlashOn = !_isFlashOn;
      _controller!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double scanAreaSize = size.width * 0.85;

    // Define the exact rectangle for the scanning window
    final Rect scanWindow = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && _controller != null) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Camera Feed
                Center(child: CameraPreview(_controller!)),

                // The Dark Overlay with "Hole"
                CustomPaint(
                  painter: _ScannerOverlayPainter(
                    scanWindow: scanWindow,
                    borderRadius: 12,
                  ),
                ),

                // 3. The White Border Frame & Corners (Visuals only)
                Center(
                  child: Container(
                    height: scanAreaSize,
                    width: scanAreaSize,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withValues(alpha:0.5), width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        _buildCorner(Alignment.topLeft),
                        _buildCorner(Alignment.topRight),
                        _buildCorner(Alignment.bottomLeft),
                        _buildCorner(Alignment.bottomRight),
                      ],
                    ),
                  ),
                ),

                // Top Controls
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                        IconButton(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white, size: 28,
                          ),
                          onPressed: _toggleFlash,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Controls
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.only(top: 24, bottom: 48),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Align lesion within frame",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        GestureDetector(
                          onTap: _takePicture,
                          child: ScaleTransition(
                            scale: _shutterController,
                            child: Container(
                              height: 84, width: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 4),
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
        },
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    const double length = 20;
    const double thickness = 3;
    final primaryColor = Theme.of(context).primaryColor;

    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: length / 100,
        heightFactor: length / 100,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: alignment.y == -1 ? BorderSide(color: primaryColor, width: thickness) : BorderSide.none,
              bottom: alignment.y == 1 ? BorderSide(color: primaryColor, width: thickness) : BorderSide.none,
              left: alignment.x == -1 ? BorderSide(color: primaryColor, width: thickness) : BorderSide.none,
              right: alignment.x == 1 ? BorderSide(color: primaryColor, width: thickness) : BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}


class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final double borderRadius;

  _ScannerOverlayPainter({
    required this.scanWindow,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Define the Full Screen
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // Define the Cutout
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        scanWindow,
        Radius.circular(borderRadius),
      ));

    // Subtract the Hole from the Screen
    final backgroundPaint = Paint()
      ..color = Colors.black54 // Dark Overlay Color
      ..style = PaintingStyle.fill;

    final backgroundWithCutout = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    // Draw it
    canvas.drawPath(backgroundWithCutout, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}