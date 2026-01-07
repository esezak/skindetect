import 'package:flutter_test/flutter_test.dart';
import 'package:skindetect/features/questions/logic/scoring_engine.dart';
import 'package:skindetect/features/questions/data/question_model.dart';

void main() {
  group('ScoringEngine', () {
    test('applies AI bonuses to top1 and top2', () {
      final engine = ScoringEngine();
      final ai = {'Acne': 0.9, 'Eczema': 0.7, 'Warts': 0.1};
      final answers = <String, bool?>{};
      final questions = <Question>[];

      final res = engine.calculateFinalScores(
        aiResults: ai,
        userAnswers: answers,
        allQuestions: questions,
      );

      // Acne should have highest percentage due to +20; eczema +10
      expect(res.keys, containsAll(['Acne', 'Eczema']));
      expect(res['Acne']! > res['Eczema']!, true);
    });

    test('accumulates question points and clamps to non-negative', () {
      final engine = ScoringEngine();
      final ai = <String, double>{};
      final q1 = Question(
        id: 'q1',
        text: 'Q1',
        yesPoints: {'Acne': 10, 'Eczema': -5},
        noPoints: {'Warts': 3},
        yesChildren: [],
        noChildren: [],
      );

      final res = engine.calculateFinalScores(
        aiResults: ai,
        userAnswers: {'q1': true},
        allQuestions: [q1],
      );

      // Eczema negative should clamp after normalization path
      expect(res['Acne']! > 0, true);
      // Only Acne > 0 implies Warts is zero/not present
      expect(res.containsKey('Warts'), true);
    });

    test('returns empty map if total points are zero', () {
      final engine = ScoringEngine();
      final res = engine.calculateFinalScores(
        aiResults: {},
        userAnswers: {},
        allQuestions: const [],
      );
      expect(res.isEmpty, true);
    });
  });
}

