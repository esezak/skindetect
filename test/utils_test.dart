import 'package:flutter_test/flutter_test.dart';
import 'package:skindetect/core/utils/utils.dart';

void main() {
  group('cleanKey', () {
    test('removes numeric prefix and underscores, capitalizes words', () {
      expect(cleanKey('1_Melanoma'), 'Melanoma');
      expect(cleanKey('Unknown_Normal'), 'Unknown Normal');
      expect(cleanKey('psoriasis'), 'Psoriasis');
    });

    test('handles empty and underscore-only strings', () {
      expect(cleanKey(''), '');
      expect(cleanKey('_'), '');
      expect(cleanKey('__a__b__'), 'A B');
    });
  });
}

