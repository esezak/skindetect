import 'package:flutter/material.dart';
import '../../scan/presentation/camera_screen.dart';
import '../../scan/presentation/image_picker_utils.dart';
import '../../history/presentation/history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // specific theme data for this screen if needed,
    // otherwise it inherits from the main app theme.
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
          title: const Text('Skin Detect'),
          centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header / Welcome Text
              Text(
                'Start your analysis',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // "Take a picture" Button
              _HomeButton(
                icon: Icons.camera_alt_rounded,
                label: 'Take a picture',
                color: colorScheme.primary,
                onTextColor: colorScheme.onPrimary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CameraScreen()),
                  );
                },
              ),
              const SizedBox(height: 16),

              // "Select From Gallery" Button
              _HomeButton(
                icon: Icons.photo_library_rounded,
                label: 'Select From Gallery',
                color: colorScheme.secondaryContainer,
                onTextColor: colorScheme.onSecondaryContainer,
                onPressed: () {
                  ImagePickerUtils.pickImageFromGallery(context);
                },
              ),

              const Spacer(),
              const Divider(),
              const SizedBox(height: 16),

              // "See Previous Scans" Button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HistoryScreen()),
                  );
                },
                icon: const Icon(Icons.history_rounded),
                label: const Text('See Previous Scans'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: colorScheme.outline),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable Button Widget to keep code clean
class _HomeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color onTextColor;
  final VoidCallback onPressed;

  const _HomeButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTextColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 28),
      label: Text(
        label,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: onTextColor,
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}