import 'package:flutter/material.dart';
import '../data/question_model.dart';
import '../data/question_parser.dart';     // Add the parser import
import '../data/question_service.dart';
import '../logic/scoring_engine.dart';
import '../../results/presentation/results_screen.dart';

class QuestionnaireScreen extends StatefulWidget {
  final Map<String, double> aiResults;
  final String imagePath;

  const QuestionnaireScreen({
    super.key,
    required this.aiResults,
    required this.imagePath,
  });

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  // Store user answers: 'root_1': true (Yes), 'sub_itch': false (No)
  final Map<String, bool?> _answers = {};
  final List<Question> _rootQuestions = QuestionService().questions;


  // Flatten the tree into a list of currently VISIBLE questions
  List<Question> _getVisibleQuestions() {
    List<Question> visible = [];
    for (var q in _rootQuestions) {
      _addIfVisible(q, visible);
    }
    return visible;
  }

  void _addIfVisible(Question node, List<Question> list) {
    list.add(node);

    // If the user has answered this question...
    if (_answers.containsKey(node.id) && _answers[node.id] != null) {
      bool isYes = _answers[node.id]!;

      // ...get the appropriate children (Yes-branch or No-branch)
      List<Question> children = isYes ? node.yesChildren : node.noChildren;

      for (var child in children) {
        _addIfVisible(child, list);
      }
    }
  }
  // Recursive function to clear answers for hidden paths
  void _clearDownstreamAnswers(Question node, bool keepingYesPath) {
    // If we are keeping the YES path, we must clear the NO path children
    // If we are keeping the NO path, we must clear the YES path children

    List<Question> childrenToClear = keepingYesPath ? node.noChildren : node.yesChildren;

    for (var child in childrenToClear) {
      if (_answers.containsKey(child.id)) {
        // Remove the answer
        _answers.remove(child.id);

        // Recursively clear this child's children
        _clearAllChildren(child);
      }
    }
  }

  void _clearAllChildren(Question node) {
    for (var child in [...node.yesChildren, ...node.noChildren]) {
      if (_answers.containsKey(child.id)) {
        _answers.remove(child.id);
        _clearAllChildren(child);
      }
    }
  }
  void _finishTest() {
    final engine = ScoringEngine();

    // Calculate final score using the loaded questions
    final finalScores = engine.calculateFinalScores(
      aiResults: widget.aiResults,
      userAnswers: _answers,
      allQuestions: _rootQuestions,
    );

    Navigator.pop(context, finalScores);
  }

  @override
  Widget build(BuildContext context) {
    final visibleQuestions = _getVisibleQuestions();
    // Check if every visible question has an answer
    bool isComplete = visibleQuestions.isNotEmpty &&
        visibleQuestions.every((q) => _answers.containsKey(q.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Improve Accuracy')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: visibleQuestions.length,
              itemBuilder: (context, index) {
                final question = visibleQuestions[index];
                final isAnswered = _answers.containsKey(question.id);
                final currentAnswer = _answers[question.id];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: isAnswered ? 1 : 4,
                  color: isAnswered ? Colors.grey[100] : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          question.text,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isAnswered ? Colors.black54 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // YES Button
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('Yes')),
                                selected: currentAnswer == true,
                                onSelected: (selected) {
                                  setState(() {
                                    _answers[question.id] = true;
                                    _clearDownstreamAnswers(question, true);
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            // NO Button
                            Expanded(
                              child: ChoiceChip(
                                label: const Center(child: Text('No')),
                                selected: currentAnswer == false,
                                onSelected: (selected) {
                                  setState(() {
                                    _answers[question.id] = false;
                                    _clearDownstreamAnswers(question, false);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Finish Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isComplete ? _finishTest : null,
                child: const Text('Finish Test & Update Results'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}