import 'package:dsc26_flt_w03/domain/models/question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Question.fromJson', () {
    test('parses a valid question and ignores unknown fields', () {
      final json = {
        'id': 'q100',
        'skillId': 'math.algebra',
        'stem': 'ما قيمة س إذا كانت ٢س = ١٠؟',
        'choices': ['2', '3', '5', '10'],
        'extra_field': 'ignore_me',
        'another_unknown': 12345,
      };

      final question = Question.fromJson(json);
      expect(question.id, 'q100');
      expect(question.skillId, 'math.algebra');
      expect(question.stem, 'ما قيمة س إذا كانت ٢س = ١٠؟');
      expect(question.choices, ['2', '3', '5', '10']);
    });

    test('accepts minimum boundary of 2 choices', () {
      final json = {
        'id': 'q1',
        'skillId': 'bio',
        'stem': 'سؤال',
        'choices': ['أ', 'ب'],
      };
      final question = Question.fromJson(json);
      expect(question.choices.length, 2);
    });

    test('accepts maximum boundary of 6 choices', () {
      final json = {
        'id': 'q1',
        'skillId': 'bio',
        'stem': 'سؤال',
        'choices': ['1', '2', '3', '4', '5', '6'],
      };
      final question = Question.fromJson(json);
      expect(question.choices.length, 6);
    });

    test(
      'throws FormatException when id is missing, not a string, or empty',
      () {
        expect(
          () => Question.fromJson({
            'skillId': 's',
            'stem': 'stem',
            'choices': ['a', 'b'],
          }),
          throwsFormatException,
        );
        expect(
          () => Question.fromJson({
            'id': 123,
            'skillId': 's',
            'stem': 'stem',
            'choices': ['a', 'b'],
          }),
          throwsFormatException,
        );
        expect(
          () => Question.fromJson({
            'id': '',
            'skillId': 's',
            'stem': 'stem',
            'choices': ['a', 'b'],
          }),
          throwsFormatException,
        );
      },
    );

    test(
      'throws FormatException when skillId is missing, not a string, or empty',
      () {
        expect(
          () => Question.fromJson({
            'id': 'q',
            'stem': 'stem',
            'choices': ['a', 'b'],
          }),
          throwsFormatException,
        );
        expect(
          () => Question.fromJson({
            'id': 'q',
            'skillId': 456,
            'stem': 'stem',
            'choices': ['a', 'b'],
          }),
          throwsFormatException,
        );
        expect(
          () => Question.fromJson({
            'id': 'q',
            'skillId': '',
            'stem': 'stem',
            'choices': ['a', 'b'],
          }),
          throwsFormatException,
        );
      },
    );

    test(
      'throws FormatException when stem is missing, not a string, or empty',
      () {
        expect(
          () => Question.fromJson({
            'id': 'q',
            'skillId': 's',
            'choices': ['a', 'b'],
          }),
          throwsFormatException,
        );
        expect(
          () => Question.fromJson({
            'id': 'q',
            'skillId': 's',
            'stem': true,
            'choices': ['a', 'b'],
          }),
          throwsFormatException,
        );
        expect(
          () => Question.fromJson({
            'id': 'q',
            'skillId': 's',
            'stem': '',
            'choices': ['a', 'b'],
          }),
          throwsFormatException,
        );
      },
    );

    test('throws FormatException when choices is not a list, too short, or too long', () {
      expect(
        () => Question.fromJson({
          'id': 'q',
          'skillId': 's',
          'stem': 'stem',
          'choices': 'not_list',
        }),
        throwsFormatException,
      );
      expect(
        () => Question.fromJson({
          'id': 'q',
          'skillId': 's',
          'stem': 'stem',
          'choices': ['one'],
        }),
        throwsFormatException,
      );
      expect(
        () => Question.fromJson({
          'id': 'q',
          'skillId': 's',
          'stem': 'stem',
          'choices': ['1', '2', '3', '4', '5', '6', '7'],
        }),
        throwsFormatException,
      );
    });

    test(
      'throws FormatException when any choice is not a string or is empty',
      () {
        expect(
          () => Question.fromJson({
            'id': 'q',
            'skillId': 's',
            'stem': 'stem',
            'choices': ['a', 2],
          }),
          throwsFormatException,
        );
        expect(
          () => Question.fromJson({
            'id': 'q',
            'skillId': 's',
            'stem': 'stem',
            'choices': ['a', ''],
          }),
          throwsFormatException,
        );
      },
    );
  });
}
