# SkinDetect

Local, offline skin condition detection built with Flutter. Capture or pick an image, align it inside a guide rectangle, and get on-device predictions with a TensorFlow Lite model. Enhance accuracy by answering a short questionnaire, and review all scans in History.

> Important: This app is a research/prototype tool and does not provide medical advice. Always consult a healthcare professional.

## Features
- Camera capture with on-screen guide rectangle and auto-crop to the guide area
- Preprocessing to 416×416 (square) for the TFLite model
- On‑device inference with `tflite_flutter` (no network required)
- Questionnaire fusion (AI + answers) via a scoring engine
- History of previous scans with images and results (local, via Hive)
- Currently supported platform: Android (other TensorFlow Lite-capable platforms may be supported with additional setup)

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
- Flutter SDK (stable), compatible with Dart (see `pubspec.yaml`)
- Android Studio/VS Code as you prefer
- Android SDK and an emulator or a physical device

### Install dependencies
```powershell
flutter --version
flutter pub get
```

### Run the app (Android)
```powershell
# Optional: verify setup
flutter doctor
flutter devices

# Run on Android (debug)
flutter run
```

## Platform notes

### Android
- Permissions are declared in `android/app/src/main/AndroidManifest.xml` (Camera and Storage). Ensure `minSdkVersion` is at least 26 in `android/app/build.gradle`.
- Physical devices work best for camera + flash. Emulators may have limited camera features.

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

## Privacy & disclaimer
- All processing is done locally on-device. Images and results are stored locally using Hive.
- This app is not intended to diagnose, treat, or cure any disease. It is for educational/research purposes only.

## Contributing
1. Fork and create a feature branch
2. Keep changes small and well‑scoped
3. Run `flutter analyze` and `flutter test`
4. Open a PR with a clear description and screenshots when UI changes

## License
None

# User Guide and Code Repository

## Code Repository
- GitHub repository link: https://github.com/esezak/skindetect
- Short description: A Flutter mobile app that analyzes skin images using an on-device TensorFlow Lite model, combines AI scores with a short questionnaire, and presents condition likelihoods.
- Programming language(s) and main libraries:
  - Dart (Flutter)
  - Core packages (see `pubspec.yaml` for versions): camera, image_picker, hive, tflite_flutter
- Repository structure (brief):
  - `lib/` — app source (UI, features, services)
  - `assets/` — TFLite model and app assets
  - `android/`, `ios/`, `web/`, `windows/` — platform scaffolding
  - `test/` — unit tests


---

## Developer Guide for Windows

This section explains how a user can run and use the application on Windows.

### 1. System Requirements
- Operating system: Windows 10/11
- Required software:
  - Flutter SDK (stable channel)
  - Android Studio with Android SDK and platform-tools
  - An Android device (USB debugging enabled) or Android emulator
- Libraries/frameworks: Managed via Flutter; see `pubspec.yaml` for exact dependency versions.

### 2. Installation
- Clone the repository and install dependencies (Windows PowerShell):

```powershell
# Clone the repository
git clone https://github.com/esezak/skindetect.git
cd skindetect

# Fetch Dart/Flutter dependencies
flutter pub get
```

### 3. Running the Application
- Run on an Android device or emulator (debug):

```powershell
# Optional: ensure Flutter and devices are recognized
flutter doctor
flutter devices

# Run in debug mode on the selected Android device/emulator
flutter run
```

- Build a debug APK (no release keys required):

```powershell
# Build a debug APK
flutter build apk --debug

# The APK will be available under: build\app\outputs\apk\debug\app-debug.apk
```

- Alternatively, download the APK from GitHub Releases:
  - Visit the repository Releases page and download the provided APK.

### 4. Input and Output
- Input:
  - Capture a skin image via camera or select one from the gallery.
  - Answer a short questionnaire to refine results.
- Output:
  - A ranked list of skin conditions with percentages.
  - Saved history entry that can be revisited and updated after answering questions.

### 5. Example Usage
1. Open the app on your Android device/emulator.
2. Tap “Take a picture” or “Select From Gallery” to provide an image.
3. Review the initial results.
4. Tap “Answer Questions to Improve Accuracy” and complete the questionnaire.
5. The results update and are saved to history.

### 6. Notes and Limitations
- Platform support:
  - Currently, only the Android version is supported.
  - It is possible to make the app work on other platforms that support TensorFlow Lite (e.g., iOS, desktop) with additional setup.
- Permissions: Camera and storage permissions are required for capture and saving results.
