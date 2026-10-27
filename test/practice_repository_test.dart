import 'package:dsc26_flt_w03/data/repositories/practice_repository.dart';
import 'package:dsc26_flt_w03/data/services/api_failure.dart';
import 'package:dsc26_flt_w03/data/services/question_api.dart';
import 'package:dsc26_flt_w03/domain/models/question.dart';
import 'package:dsc26_flt_w03/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final baseUri = Uri.parse('https://api.masaraat.test');

  group('PracticeRepository immediate returns', () {
    test('returns Ok immediately on first call with 0 sleeps', () async {
      final waits = <Duration>[];
      var calls = 0;
      final repo = PracticeRepository(
        api: QuestionApi(
          client: MockClient((_) async {
            calls++;
            return http.Response(
              '{"questions": [{"id": "q1", "skillId": "s1", "stem": "stem", "choices": ["c1", "c2"]}]}',
              200,
            );
          }),
          baseUrl: baseUri,
        ),
        sleep: (d) async => waits.add(d),
      );

      final result = await repo.nextQuestions('std-1');
      expect(result, isA<Ok<List<Question>>>());
      expect(calls, 1);
      expect(waits, isEmpty);
    });

    test('returns permanent failures immediately with 0 sleeps', () async {
      for (final code in [401, 404, 400]) {
        final waits = <Duration>[];
        var calls = 0;
        final repo = PracticeRepository(
          api: QuestionApi(
            client: MockClient((_) async {
              calls++;
              return http.Response('err', code);
            }),
            baseUrl: baseUri,
          ),
          sleep: (d) async => waits.add(d),
        );

        final result = await repo.nextQuestions('std-1');
        expect(result, isA<Err<List<Question>>>());
        expect((result as Err<List<Question>>).failure.isTransient, isFalse);
        expect(calls, 1);
        expect(waits, isEmpty);
      }
    });

    test('returns BadResponse immediately with 0 sleeps', () async {
      final waits = <Duration>[];
      var calls = 0;
      final repo = PracticeRepository(
        api: QuestionApi(
          client: MockClient((_) async {
            calls++;
            return http.Response('{"questions": "not-a-list"}', 200);
          }),
          baseUrl: baseUri,
        ),
        sleep: (d) async => waits.add(d),
      );

      final result = await repo.nextQuestions('std-1');
      expect(result, isA<Err<List<Question>>>());
      expect((result as Err<List<Question>>).failure, isA<BadResponse>());
      expect(calls, 1);
      expect(waits, isEmpty);
    });
  });

  group('PracticeRepository transient retry policy', () {
    test('retries transient failures up to maxRetries with 2^n exponential backoff', () async {
      final waits = <Duration>[];
      var calls = 0;
      final repo = PracticeRepository(
        api: QuestionApi(
          client: MockClient((_) async {
            calls++;
            return http.Response('busy', 503);
          }),
          baseUrl: baseUri,
        ),
        sleep: (d) async => waits.add(d),
        maxRetries: 3,
      );

      final result = await repo.nextQuestions('std-1');
      expect(result, isA<Err<List<Question>>>());
      expect(calls, 4); // 1 initial + 3 retries
      expect(waits, [
        const Duration(seconds: 1), // 2^0
        const Duration(seconds: 2), // 2^1
        const Duration(seconds: 4), // 2^2
      ]);
    });

    test('recovers after retry when transient failure resolves', () async {
      final waits = <Duration>[];
      var calls = 0;
      final repo = PracticeRepository(
        api: QuestionApi(
          client: MockClient((_) async {
            calls++;
            if (calls < 3) {
              return http.Response('error', 500);
            }
            return http.Response(
              '{"questions": [{"id": "q1", "skillId": "s1", "stem": "stem", "choices": ["c1", "c2"]}]}',
              200,
            );
          }),
          baseUrl: baseUri,
        ),
        sleep: (d) async => waits.add(d),
        maxRetries: 2,
      );

      final result = await repo.nextQuestions('std-1');
      expect(result, isA<Ok<List<Question>>>());
      expect(calls, 3);
      expect(waits, [const Duration(seconds: 1), const Duration(seconds: 2)]);
    });

    test('sleeps for RateLimited retryAfter, capped at 30 seconds', () async {
      final waits = <Duration>[];
      var calls = 0;
      final repo = PracticeRepository(
        api: QuestionApi(
          client: MockClient((_) async {
            calls++;
            return http.Response(
              'rate limited',
              429,
              headers: {'retry-after': '45'},
            );
          }),
          baseUrl: baseUri,
        ),
        sleep: (d) async => waits.add(d),
        maxRetries: 1,
      );

      final result = await repo.nextQuestions('std-1');
      expect(result, isA<Err<List<Question>>>());
      expect(calls, 2);
      expect(waits, [const Duration(seconds: 30)]); // capped from 45 to 30
    });

    test(
      'handles sequence: 429 (retry-after: 7), then 503, then 200',
      () async {
        final waits = <Duration>[];
        var calls = 0;
        final repo = PracticeRepository(
          api: QuestionApi(
            client: MockClient((_) async {
              calls++;
              if (calls == 1) {
                return http.Response(
                  'rate limited',
                  429,
                  headers: {'retry-after': '7'},
                );
              } else if (calls == 2) {
                return http.Response('server error', 503);
              }
              return http.Response(
                '{"questions": [{"id": "q1", "skillId": "s1", "stem": "stem", "choices": ["c1", "c2"]}]}',
                200,
              );
            }),
            baseUrl: baseUri,
          ),
          sleep: (d) async => waits.add(d),
        );

        final result = await repo.nextQuestions('std-1');
        expect(result, isA<Ok<List<Question>>>());
        expect(calls, 3);
        expect(waits, [const Duration(seconds: 7), const Duration(seconds: 2)]);
      },
    );
  });
}
