import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:skindetect/features/scan/data/classifier_service.dart';
import 'package:skindetect/features/scan/data/image_processing.dart';

class _FakeInterpreter {
  void run(ByteBuffer input, ByteBuffer output) {
    final Float32List out = output.asFloat32List();
    for (int i = 0; i < out.length; i++) {
      out[i] = i.toDouble();
    }
  }
}

void main() {
  test('resizeToSquare produces correct size for classifier', () {
    final img.Image original = img.Image(width: 300, height: 500);
    final img.Image resized = resizeToSquare(original, ClassifierService.INPUT_SIZE);
    expect(resized.width, ClassifierService.INPUT_SIZE);
    expect(resized.height, ClassifierService.INPUT_SIZE);
  });

  test('classifier maps outputs to labels in order', () {
    final labelsLen = ClassifierService.LABELS.length;
    final Float32List outputBytes = Float32List(labelsLen);
    _FakeInterpreter().run(Float32List(1 * ClassifierService.INPUT_SIZE * ClassifierService.INPUT_SIZE * 3).buffer, outputBytes.buffer);

    final Map<String, double> result = {};
    for (int i = 0; i < ClassifierService.LABELS.length; i++) {
      result[ClassifierService.LABELS[i]] = outputBytes[i];
    }

    expect(result.keys.length, labelsLen);
    expect(result[ClassifierService.LABELS.first], 0);
    expect(result[ClassifierService.LABELS.last], (labelsLen - 1).toDouble());
  });
}

