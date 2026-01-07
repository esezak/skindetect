import 'dart:io';
import 'package:flutter/material.dart';
import '../../results/presentation/results_screen.dart';
import '../data/classifier_service.dart';

class ProcessingScreen extends StatefulWidget {
  final String imagePath;

  const ProcessingScreen({super.key, required this.imagePath});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  final ClassifierService _classifier = ClassifierService();
  bool _isProcessing = true;
  Map<String, double>? _results;

  @override
  void initState() {
    super.initState();
    _startProcessing();
  }

  Future<void> _startProcessing() async {
    // Load model
    await _classifier.loadModel();

    // Run prediction
    final results = await _classifier.predict(widget.imagePath);

    if (mounted) {
      setState(() {
        _isProcessing = false;
        _results = results;
      });
    }
  }

  void _onContinue() {
    if (_results != null) {
      // Replace the Processing Screen so the user can't go "back" to it
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
              imagePath: widget.imagePath,
              results: _results!
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.file(
            File(widget.imagePath),
            fit: BoxFit.cover,
          ),

          // Dimmed Overlay
          Container(color: Colors.black.withValues(alpha: 0.4)),

          // Processing Card (Wireframe Page 6)
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 2)
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isProcessing ? 'Processing' : 'Analysis Complete',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isProcessing) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text(
                      'Image is being Processed\nusing local classifier',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ] else ...[
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Processing finished successfully.',
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isProcessing ? null : _onContinue,
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}