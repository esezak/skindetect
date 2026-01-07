import 'package:flutter/foundation.dart';
import 'question_model.dart';
import 'question_parser.dart';

class QuestionService {
  // Singleton Instance
  static final QuestionService _instance = QuestionService._internal();
  factory QuestionService() => _instance;
  QuestionService._internal();

  // Memory Storage
  List<Question>? _cachedQuestions;

  // Helper to check if data is ready
  bool get isLoaded => _cachedQuestions != null && _cachedQuestions!.isNotEmpty;

  // One-time Load Function
  Future<void> initialize() async {
    if (isLoaded) return; // Don't reload if already done
    try {
      final parser = QuestionParser();
      _cachedQuestions = await parser.loadQuestions('assets/questions.json');
      debugPrint("[OK] QuestionService: Loaded ${_cachedQuestions!.length} questions.");
    } catch (e) {
      debugPrint("[FAIL] QuestionService Error: $e");
      _cachedQuestions = []; // Prevent null errors, just empty list
    }
  }

  // 5. Accessor
  List<Question> get questions {
    if (_cachedQuestions == null) {
      debugPrint("[WARN] Warning: Accessing questions before initialization!");
      return [];
    }
    return _cachedQuestions!;
  }
}