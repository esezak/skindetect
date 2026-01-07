class Question {
  final String id;
  final String text;
  final Map<String, int> yesPoints;
  final Map<String, int> noPoints;

  final List<Question> yesChildren;
  final List<Question> noChildren;

  Question({
    required this.id,
    required this.text,
    this.yesPoints = const {},
    this.noPoints = const {},
    required this.yesChildren, // Pass empty list [] initially
    required this.noChildren,
  });
}