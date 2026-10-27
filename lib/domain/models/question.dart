/// One practice question chosen for a student by the Masaraat backend.
final class Question {
  const Question({
    required this.id,
    required this.skillId,
    required this.stem,
    required this.choices,
  });

  final String id;
  final String skillId;
  final String stem;
  final List<String> choices;

  /// Reads one question from the API. Unknown fields are ignored.
  ///
  /// Throws a [FormatException] for a missing or wrongly typed field,
  /// or when `choices` is not a list of 2 to 6 non-empty strings.
  factory Question.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Question "id" must be a non-empty string');
    }

    final skillId = json['skillId'];
    if (skillId is! String || skillId.isEmpty) {
      throw const FormatException(
        'Question "skillId" must be a non-empty string',
      );
    }

    final stem = json['stem'];
    if (stem is! String || stem.isEmpty) {
      throw const FormatException('Question "stem" must be a non-empty string');
    }

    final rawChoices = json['choices'];
    if (rawChoices is! List) {
      throw const FormatException('Question "choices" must be a list');
    }

    if (rawChoices.length < 2 || rawChoices.length > 6) {
      throw const FormatException(
        'Question "choices" must contain between 2 and 6 items',
      );
    }

    final choices = <String>[];
    for (final choice in rawChoices) {
      if (choice is! String || choice.isEmpty) {
        throw const FormatException('Each choice must be a non-empty string');
      }
      choices.add(choice);
    }

    return Question(
      id: id,
      skillId: skillId,
      stem: stem,
      choices: List.unmodifiable(choices),
    );
  }
}
