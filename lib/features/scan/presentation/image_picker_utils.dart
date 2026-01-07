import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// Import the processing screen so we can navigate to it
import 'processing_screen.dart';

class ImagePickerUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Opens the system gallery and immediately processes the selected image.
  static Future<void> pickImageFromGallery(BuildContext context) async {
    try {
      // Trigger the native gallery picker
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        debugPrint("Gallery Image Picked: ${image.path}");

        if (!context.mounted) return;

        // Navigate to Processing Screen
        // This reuses the same logic as the Camera
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProcessingScreen(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }
}