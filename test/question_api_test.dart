import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dsc26_flt_w03/data/services/api_failure.dart';
import 'package:dsc26_flt_w03/data/services/question_api.dart';
import 'package:dsc26_flt_w03/domain/models/question.dart';
import 'package:dsc26_flt_w03/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final baseUri = Uri.parse('https://api.masaraat.test');

  Map<String, Object?> sampleQuestion(String id) => {
        'id': id,
        'skillId': 'math.algebra',
        'stem': 'ما ناتج ٢ + ٢؟',
        'choices': ['1', '2', '4', '8'],
      };

  group('QuestionApi URL & parameter validation', () {
    test('throws ArgumentError when limit is < 1 or > 50', () async {
      final api = QuestionApi(
        client: MockClient((_) async => http.Response('{}', 200)),
        baseUrl: baseUri,
      );

      expect(() => api.fetchNext(studentId: 's1', limit: 0), throwsArgumentError);
      expect(() => api.fetchNext(studentId: 's1', limit: -5), throwsArgumentError);
      expect(() => api.fetchNext(studentId: 's1', limit: 51), throwsArgumentError);
      expect(() => api.fetchNext(studentId: 's1', limit: 100), throwsArgumentError);
    });

    test('preserves base URL subpath and strips trailing slash', () async {
      late Uri capturedUri;
      final api = QuestionApi(
        client: MockClient((req) async {
          capturedUri = req.url;
          return http.Response.bytes(
            utf8.encode(jsonEncode({'questions': [sampleQuestion('q1')]})),
            200,
          );
        }),
        baseUrl: Uri.parse('https://gw.example/mobile/'),
      );

      final result = await api.fetchNext(studentId: 'user1');
      expect(result, isA<Ok<List<Question>>>());
      expect(capturedUri.path, '/mobile/v1/students/user1/next-questions');
      expect(capturedUri.queryParameters['limit'], '10');
    });

    test('encodes studentId special characters (spaces as %20, slashes as %2F)', () async {
      late Uri capturedUri;
      final api = QuestionApi(
        client: MockClient((req) async {
          capturedUri = req.url;
          return http.Response.bytes(
            utf8.encode(jsonEncode({'questions': [sampleQuestion('q1')]})),
            200,
          );
        }),
        baseUrl: baseUri,
      );

      await api.fetchNext(studentId: 'student/special name');
      expect(capturedUri.path, '/v1/students/student%2Fspecial%20name/next-questions');
    });

    test('sets Accept: application/json header and sends GET request', () async {
      late String capturedMethod;
      late Map<String, String> capturedHeaders;
      final api = QuestionApi(
        client: MockClient((req) async {
          capturedMethod = req.method;
          capturedHeaders = req.headers;
          return http.Response.bytes(
            utf8.encode(jsonEncode({'questions': []})),
            200,
          );
        }),
        baseUrl: baseUri,
      );

      await api.fetchNext(studentId: 's-1');
      expect(capturedMethod, 'GET');
      expect(capturedHeaders['Accept'] ?? capturedHeaders['accept'], 'application/json');
    });
  });

  group('QuestionApi UTF-8 and response parsing', () {
    test('parses Arabic text correctly even when server header claims Latin-1', () async {
      const arabicText = 'كم عدد المولات في ١٨ جرام من الماء؟';
      final jsonStr = jsonEncode({
        'questions': [
          {
            'id': 'q1',
            'skillId': 'chem',
            'stem': arabicText,
            'choices': ['أ', 'ب', 'ج'],
          }
        ]
      });

      final api = QuestionApi(
        client: MockClient((_) async => http.Response.bytes(
              utf8.encode(jsonStr),
              200,
              headers: {'content-type': 'text/plain; charset=iso-8859-1'},
            )),
        baseUrl: baseUri,
      );

      final result = await api.fetchNext(studentId: 's-1');
      expect(result, isA<Ok<List<Question>>>());
      final questions = (result as Ok<List<Question>>).value;
      expect(questions.first.stem, arabicText);
      expect(questions.first.choices.first, 'أ');
    });

    test('returns BadResponse on invalid UTF-8 bytes', () async {
      final api = QuestionApi(
        client: MockClient((_) async => http.Response.bytes(
              Uint8List.fromList([0xFF, 0xFE, 0xFD]), // invalid UTF-8 sequence
              200,
            )),
        baseUrl: baseUri,
      );

      final result = await api.fetchNext(studentId: 's-1');
      expect(result, isA<Err<List<Question>>>());
      expect((result as Err<List<Question>>).failure, isA<BadResponse>());
    });

    test('returns BadResponse on malformed JSON', () async {
      final api = QuestionApi(
        client: MockClient((_) async => http.Response('not json at all {', 200)),
        baseUrl: baseUri,
      );

      final result = await api.fetchNext(studentId: 's-1');
      expect(result, isA<Err<List<Question>>>());
      expect((result as Err<List<Question>>).failure, isA<BadResponse>());
    });

    test('returns BadResponse when root is an array instead of an object', () async {
      final api = QuestionApi(
        client: MockClient((_) async => http.Response('[{"id": "q1"}]', 200)),
        baseUrl: baseUri,
      );

      final result = await api.fetchNext(studentId: 's-1');
      expect(result, isA<Err<List<Question>>>());
      expect((result as Err<List<Question>>).failure, isA<BadResponse>());
    });

    test('returns BadResponse when questions field is missing or not a list', () async {
      final api = QuestionApi(
        client: MockClient((_) async => http.Response('{"status": "ok"}', 200)),
        baseUrl: baseUri,
      );

      final result = await api.fetchNext(studentId: 's-1');
      expect(result, isA<Err<List<Question>>>());
      expect((result as Err<List<Question>>).failure, isA<BadResponse>());
    });

    test('returns BadResponse when a question fails validation', () async {
      final api = QuestionApi(
        client: MockClient((_) async => http.Response(
              jsonEncode({
                'questions': [
                  {'id': '', 'skillId': 's', 'stem': 'stem', 'choices': ['a', 'b']}
                ]
              }),
              200,
            )),
        baseUrl: baseUri,
      );

      final result = await api.fetchNext(studentId: 's-1');
      expect(result, isA<Err<List<Question>>>());
      expect((result as Err<List<Question>>).failure, isA<BadResponse>());
    });
  });

  group('QuestionApi status mapping', () {
    test('maps 401 to Unauthorized', () async {
      final api = QuestionApi(
        client: MockClient((_) async => http.Response('Unauthorized', 401)),
        baseUrl: baseUri,
      );
      final result = await api.fetchNext(studentId: 's-1');
      expect((result as Err<List<Question>>).failure, isA<Unauthorized>());
    });

    test('maps 404 to NotFound', () async {
      final api = QuestionApi(
        client: MockClient((_) async => http.Response('Not Found', 404)),
        baseUrl: baseUri,
      );
      final result = await api.fetchNext(studentId: 's-1');
      expect((result as Err<List<Question>>).failure, isA<NotFound>());
    });

    test('maps 429 with integer retry-after header to RateLimited(duration)', () async {
      final api = QuestionApi(
        client: MockClient((_) async => http.Response('rate limited', 429, headers: {'retry-after': '12'})),
        baseUrl: baseUri,
      );
      final result = await api.fetchNext(studentId: 's-1');
      final failure = (result as Err<List<Question>>).failure as RateLimited;
      expect(failure.retryAfter, const Duration(seconds: 12));
    });

    test('maps 429 with missing, date, or non-integer header to default 5s', () async {
      final apiDate = QuestionApi(
        client: MockClient((_) async => http.Response('rate limited', 429, headers: {'retry-after': 'Wed, 21 Oct 2026 07:28:00 GMT'})),
        baseUrl: baseUri,
      );
      final resultDate = await apiDate.fetchNext(studentId: 's-1');
      expect(((resultDate as Err<List<Question>>).failure as RateLimited).retryAfter, const Duration(seconds: 5));

      final apiFloat = QuestionApi(
        client: MockClient((_) async => http.Response('rate limited', 429, headers: {'retry-after': '2.5'})),
        baseUrl: baseUri,
      );
      final resultFloat = await apiFloat.fetchNext(studentId: 's-1');
      expect(((resultFloat as Err<List<Question>>).failure as RateLimited).retryAfter, const Duration(seconds: 5));

      final apiMissing = QuestionApi(
        client: MockClient((_) async => http.Response('rate limited', 429)),
        baseUrl: baseUri,
      );
      final resultMissing = await apiMissing.fetchNext(studentId: 's-1');
      expect(((resultMissing as Err<List<Question>>).failure as RateLimited).retryAfter, const Duration(seconds: 5));
    });

    test('maps 500-599 to ServerError(statusCode)', () async {
      for (final code in [500, 502, 503, 599]) {
        final api = QuestionApi(
          client: MockClient((_) async => http.Response('server error', code)),
          baseUrl: baseUri,
        );
        final result = await api.fetchNext(studentId: 's-1');
        final failure = (result as Err<List<Question>>).failure as ServerError;
        expect(failure.statusCode, code);
      }
    });

    test('maps other status codes to UnexpectedStatus(statusCode)', () async {
      for (final code in [301, 302, 400, 403, 418]) {
        final api = QuestionApi(
          client: MockClient((_) async => http.Response('other', code)),
          baseUrl: baseUri,
        );
        final result = await api.fetchNext(studentId: 's-1');
        final failure = (result as Err<List<Question>>).failure as UnexpectedStatus;
        expect(failure.statusCode, code);
      }
    });
  });

  group('QuestionApi network failures & timeouts', () {
    test('maps http.ClientException to Offline', () async {
      final api = QuestionApi(
        client: MockClient((_) async => throw http.ClientException('no network')),
        baseUrl: baseUri,
      );
      final result = await api.fetchNext(studentId: 's-1');
      expect((result as Err<List<Question>>).failure, isA<Offline>());
    });

    test('maps timeout to TimedOut', () async {
      final api = QuestionApi(
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return http.Response('ok', 200);
        }),
        baseUrl: baseUri,
        timeout: const Duration(milliseconds: 20),
      );
      final result = await api.fetchNext(studentId: 's-1');
      expect((result as Err<List<Question>>).failure, isA<TimedOut>());
    });
  });
}
