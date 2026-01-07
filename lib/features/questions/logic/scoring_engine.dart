import '../../../core/utils/utils.dart';

class ScoringEngine {
  /// Calculates the final percentages based on AI scan + Questionnaire
  Map<String, double> calculateFinalScores({
    required Map<String, double> aiResults, // Raw AI output (0.0 - 1.0)
    required Map<String, bool?> userAnswers, // 'q1': true (Yes), 'q2': false (No)
    required List<dynamic> allQuestions, // Question Tree
  }) {
    // Initialize Score Board
    Map<String, double> scoreboard = {
      'Acne': 0,
      'Benign_tumors': 0,
      'Candidiasis': 0,
      'Eczema': 0,
      'Lichen': 0,
      'Moles': 0,
      'Psoriasis': 0,
      'SkinCancer': 0,
      'Tinea': 0,
      'Unknown_Normal': 0,
      'Vascular_Tumors': 0,
      'Vasculitis': 0,
      'Vitiligo': 0,
      'Warts': 0,
    };

    // APPLY AI BONUSES
    // Sort AI results to find Rank 1 and Rank 2
    var sortedAI = aiResults.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedAI.isNotEmpty) {
      // #1 Disease gets +20 points
      String top1 = cleanKey(sortedAI[0].key);
      scoreboard[top1] = (scoreboard[top1] ?? 0) + 20;
    }
    if (sortedAI.length > 1) {
      // #2 Disease gets +10 points
      String top2 = cleanKey(sortedAI[1].key);
      scoreboard[top2] = (scoreboard[top2] ?? 0) + 10;
    }

    // APPLY QUESTION POINTS
    _applyTreePoints(allQuestions, userAnswers, scoreboard);

    // CLAMP SCORES TO MIN 0 (For Negative Scoring)
    scoreboard.updateAll((key, val) => val < 0 ? 0 : val);

    // NORMALIZE TO PERCENTAGE (Top 5)
    double totalPoints = scoreboard.values.fold(0, (sum, val) => sum + val);

    if (totalPoints == 0) return {}; // Avoid division by zero

    Map<String, double> finalPercentages = {};
    scoreboard.forEach((key, points) {
      finalPercentages[key] = points / totalPoints;
    });

    return finalPercentages;
  }

  /// Recursive function to walk the question tree and tally points
  void _applyTreePoints(List<dynamic> nodes, Map<String, bool?> answers, Map<String, double> scoreboard) {
    for (var node in nodes) {
      // Has the user answered this question?
      if (answers.containsKey(node.id) && answers[node.id] != null) {
        bool answer = answers[node.id]!;
        // Add points based on answer
        Map<String, int> pointsToAdd = answer ? node.yesPoints : node.noPoints;
        pointsToAdd.forEach((disease, points) {
          String key = cleanKey(disease);
          scoreboard[key] = (scoreboard[key] ?? 0) + points;
        });

        // Recursively process children if they are visible
        if (answer) {
          _applyTreePoints(node.yesChildren, answers, scoreboard);
        } else {
          _applyTreePoints(node.noChildren, answers, scoreboard);
        }
      }
    }
  }
}