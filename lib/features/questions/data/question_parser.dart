import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'question_model.dart';

class QuestionParser {

  // ---------------------------------------------------------
  // CONFIGURATION: Adjust point values here
  // ---------------------------------------------------------
  static const Map<String, int> POINT_VALUES = {
    // POSITIVE SCORING
    'low': 5,
    'med': 10,
    'medium': 10,
    'high': 20,
    'very_high': 40,

    // NEGATIVE SCORING
    'n_low': -5,
    'n_med': -10,
    'n_medium': -10,
    'n_high': -20,
    'n_very_high': -40,
  };

  Future<List<Question>> loadQuestions(String assetPath) async {
    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final List<dynamic> rawList = json.decode(jsonString);

      final Map<String, Question> questionMap = {};
      final Map<String, List<String>> pendingYesLinks = {};
      final Map<String, List<String>> pendingNoLinks = {};

      for (var item in rawList) {
        final id = item['id'];
        if (id == null) throw Exception("Found a question without an ID!");
        if (questionMap.containsKey(id)) throw Exception("Duplicate ID found: $id");

        // PARSE POINTS (Can be String or Int)
        Map<String, int> yesPoints = _parsePoints(item['points_if_yes']);
        Map<String, int> noPoints = _parsePoints(item['points_if_no']);

        questionMap[id] = Question(
          id: id,
          text: item['text'] ?? "Missing Text",
          yesPoints: yesPoints,
          noPoints: noPoints,
          yesChildren: [],
          noChildren: [],
        );

        pendingYesLinks[id] = List<String>.from(item['next_questions_if_yes'] ?? []);
        pendingNoLinks[id] = List<String>.from(item['next_questions_if_no'] ?? []);
      }

      // Link Children
      _linkChildren(questionMap, pendingYesLinks, true);
      _linkChildren(questionMap, pendingNoLinks, false);

      return questionMap.values.where((q) => q.id.startsWith('root_')).toList();

    } catch (e) {
      _notifyDeveloper("CRITICAL JSON ERROR: $e");
      return [];
    }
  }

  /// Helper to convert "high" -> 20, "low" -> 5
  Map<String, int> _parsePoints(dynamic jsonMap) {
    if (jsonMap == null) return {};
    Map<String, int> result = {};

    jsonMap.forEach((disease, value) {
      if (value is int) {
        // Support numbers if provided directly
        result[disease] = value;
      } else if (value is String) {
        // Convert String to Int
        String key = value.toLowerCase().trim();
        if (POINT_VALUES.containsKey(key)) {
          result[disease] = POINT_VALUES[key]!;
        } else {
          _notifyDeveloper("Warning: Unknown point value '$value' for disease '$disease'. Defaulting to 0.");
          result[disease] = 0;
        }
      }
    });
    return result;
  }

  void _linkChildren(Map<String, Question> map, Map<String, List<String>> links, bool isYes) {
    links.forEach((parentId, childIds) {
      final parent = map[parentId]!;
      for (var childId in childIds) {
        if (!map.containsKey(childId)) {
          _notifyDeveloper("Error in Question '$parentId': Referenced child '$childId' does not exist.");
        } else {
          if (isYes) {
            parent.yesChildren.add(map[childId]!);
          } else {
            parent.noChildren.add(map[childId]!);
          }
        }
      }
    });
  }

  void _notifyDeveloper(String message) {
    debugPrint("\n🔴 CONFIG ERROR: $message\n");
  }
}