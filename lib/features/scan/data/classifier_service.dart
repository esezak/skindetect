import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'image_processing.dart';

class ClassifierService {
  static final ClassifierService _instance = ClassifierService._internal();
  factory ClassifierService() => _instance;
  ClassifierService._internal();

  Interpreter? _interpreter;

  // ---------------- CONFIGURATION ----------------
  static const int INPUT_SIZE = 416;
  static const String MODEL_PATH = 'assets/skin_model.tflite';
  static const List<String> LABELS = [
    'Acne',
    'Benign_tumors',
    'Candidiasis',
    'Eczema',
    'Lichen',
    'Moles',
    'Psoriasis',
    'SkinCancer',
    'Tinea',
    'Unknown_Normal',
    'Vascular_Tumors',
    'Vasculitis',
    'Vitiligo',
    'Warts',
  ];
  // -----------------------------------------------

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions();
      options.threads = 4; // Use 4 CPU threads for speed

      debugPrint('Loading model on CPU...');
      _interpreter = await Interpreter.fromAsset(MODEL_PATH, options: options);

      // Explicitly resize and allocate tensors to prevent "Shape Mismatch"
      _interpreter!.resizeInputTensor(0, [1, 416, 416, 3]);
      _interpreter!.allocateTensors();

      debugPrint('TFLite Model loaded and Tensors allocated.');
    } catch (e) {
      debugPrint('Error loading model: $e');
    }
  }

  Future<Map<String, double>> predict(String imagePath) async {
    if (_interpreter == null) await loadModel();

    final imageData = File(imagePath).readAsBytesSync();
    final img.Image? originalImage = img.decodeImage(imageData);
    if (originalImage == null) return {};

    final img.Image inputImage = resizeToSquare(originalImage, INPUT_SIZE);

    // Prepare Input Buffer (Float32)
    var inputBytes = Float32List(1 * INPUT_SIZE * INPUT_SIZE * 3);
    var bufferIndex = 0;

    for (var y = 0; y < INPUT_SIZE; y++) {
      for (var x = 0; x < INPUT_SIZE; x++) {
        final pixel = inputImage.getPixel(x, y);
        inputBytes[bufferIndex++] = pixel.r / 255.0;
        inputBytes[bufferIndex++] = pixel.g / 255.0;
        inputBytes[bufferIndex++] = pixel.b / 255.0;
      }
    }

    // Prepare Output Buffer
    var outputBytes = Float32List(LABELS.length);

    try {
      _interpreter!.run(inputBytes.buffer, outputBytes.buffer);
    } catch (e) {
      debugPrint('Inference Failed: $e');
      return {};
    }

    // Parse Results
    List<double> probabilities = outputBytes.toList();
    Map<String, double> result = {};
    for (int i = 0; i < LABELS.length; i++) {
      if (i < probabilities.length) {
        result[LABELS[i]] = probabilities[i];
      }
    }

    // Sort: Highest confidence first
    var sortedEntries = result.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }
}