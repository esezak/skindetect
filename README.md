# SkinDetect

Local, offline skin condition detection built with Flutter. Capture or pick an image, align it inside a guide rectangle, and get on-device predictions with a TensorFlow Lite model. Enhance accuracy by answering a short questionnaire, and review all scans in History.

> Important: This app is a research/prototype tool and does not provide medical advice. Always consult a healthcare professional.

## Features
- Camera capture with on-screen guide rectangle and auto-crop to the guide area
- Preprocessing to 416×416 (square) for the TFLite model
- On‑device inference with `tflite_flutter` (no network required)
- Questionnaire fusion (AI + answers) via a scoring engine
- History of previous scans with images and results (local, via Hive)
- Works on Android and Windows; iOS and Web status depends on platform support and entitlements

## How it works (pipeline)
1. User takes a photo in the camera view and aligns the lesion within the rounded guide frame.
2. The captured image is cropped to the guide window using normalized coordinates that map the camera preview (cover fit) to the raw image dimensions. See `lib/features/scan/data/image_processing.dart`:
   - `normalizeScanWindowToImage(...)` computes the normalized rect (0..1).
   - `cropNormalizedRect(...)` crops the decoded image to that area.
3. The cropped image is resized to 416×416 using a center‑crop cover strategy: `resizeToSquare(...)`.
4. The preprocessed image is fed to a TFLite `Interpreter` with input `[1, 416, 416, 3]` in `ClassifierService`.
5. Raw scores are saved; the questionnaire optionally adjusts final scores. Both raw and final results are persisted in History.

Key files:
- Cropping & resizing: `lib/features/scan/data/image_processing.dart`
- Model inference: `lib/features/scan/data/classifier_service.dart`
- Camera UI & guide: `lib/features/scan/presentation/camera_screen.dart`
- Results screen & actions: `lib/features/results/presentation/results_screen.dart`
- Questionnaire: `lib/features/questions/*` (loads from `assets/questions.json`)
- History (Hive): `lib/features/history/*`
- Shared utils: `lib/core/utils/utils.dart` (e.g., `cleanKey` formatter)

Model asset:
- `assets/skin_model.tflite`

If you swap the model, update at least:
- `MODEL_PATH`, `INPUT_SIZE`, and `LABELS` in `ClassifierService`
- Any preprocessing assumptions in `image_processing.dart`

## Getting started

### Prerequisites
- Flutter SDK (stable), compatible with Dart `^3.10.0` (see `pubspec.yaml`)
- Android Studio/Xcode/VS Code as you prefer
- For Android: Android SDK and an emulator or a physical device
- For Windows desktop: Windows toolchain enabled (`flutter config --enable-windows-desktop`)

### Install dependencies
```powershell
flutter --version
flutter pub get
```

### Run the app
- Android (recommended for camera testing):
```powershell
flutter run -d android
```
- Windows (desktop):
```powershell
flutter run -d windows
```
- iOS (requires a Mac + proper signing; see iOS notes below):
```bash
flutter run -d ios
```

## Platform notes

### Android
- Permissions are declared in `android/app/src/main/AndroidManifest.xml` (Camera and Storage). Ensure `minSdkVersion` is at least 26 in `android/app/build.gradle`.
- Physical devices work best for camera + flash. Emulators may have limited camera features.

### iOS
Add the following keys to `ios/Runner/Info.plist` if you plan to run on iOS:
```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required to capture skin images for analysis.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Saving processed images to your library requires permission.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Selecting an image from your photo library requires permission.</string>
```
TFLite on iOS requires proper bundling; `tflite_flutter` supports iOS, but device runtime setup, bitcode, and architectures must be correct.

### Windows
Windows desktop is supported when native assets are available. Ensure your Visual Studio toolchain is installed (Desktop development with C++).

### Web
This project includes a `web/` folder, but `tflite_flutter` does not run on the web. Running on web would require a different inference backend (e.g., TF.js) and is out of scope for this repo.

## Running tests
Unit tests cover image preprocessing and classification paths:
```powershell
flutter test
```
Relevant tests:
- `test/image_processing_test.dart`
- `test/classifier_service_test.dart`

## App usage walkthrough
1. Launch the app and tap “Take a picture”.
2. Align the lesion inside the guide rectangle; tap the shutter.
3. The app automatically crops to the guide and preprocesses to 416×416.
4. View the results and optionally answer the questionnaire to refine them.
5. Review previous scans in History; you can delete a scan or open its details.

## Architecture overview
High-level structure:
```
lib/
  core/
    utils/           # Reusable helpers (e.g., cleanKey)
  features/
    home/
    scan/            # Camera UI, preprocessing, TFLite
      data/
        classifier_service.dart
        image_processing.dart
      presentation/
        camera_screen.dart
        processing_screen.dart
        image_picker_utils.dart
    results/
      presentation/results_screen.dart
    questions/
      data/question_service.dart
      logic/
      presentation/
    history/
      data/         # Hive models and repository
      presentation/ # History list UI
```

Key patterns:
- Thin UI with “data” services for heavy lifting
- Pure Dart image ops (`package:image`) for crop/resize
- Local persistence via Hive

## Troubleshooting
- Black or stretched preview: ensure `CameraPreview` is using cover fit and mapping is done via `normalizeScanWindowToImage`.
- Shape mismatch in TFLite: verify input tensor is resized to `[1, 416, 416, 3]` and `allocateTensors()` is called (already handled in `ClassifierService`).
- iOS build fails due to permissions: add the Info.plist keys listed above.
- Android storage write issues on Android 10+: external write permission is restricted; this app stores images internally via `path_provider` in History operations.
- Flash not toggling: physical device required; many emulators don’t support torch mode.

## Privacy & disclaimer
- All processing is done locally on-device. Images and results are stored locally using Hive.
- This app is not intended to diagnose, treat, or cure any disease. It is for educational/research purposes only.

## Contributing
1. Fork and create a feature branch
2. Keep changes small and well‑scoped
3. Run `flutter analyze` and `flutter test`
4. Open a PR with a clear description and screenshots when UI changes

## License
Add your license of choice (MIT/Apache-2.0) in a `LICENSE` file.
