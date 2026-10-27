// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/models/question.dart';
import '../../utils/result.dart';
import 'api_failure.dart';

/// One call to the Masaraat questions API. Holds no state and never retries.
///
/// Keep the constructor and the signature of [fetchNext] exactly.
class QuestionApi {
  QuestionApi({
    required http.Client client,
    required Uri baseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) : _client = client,
       _baseUrl = baseUrl,
       _timeout = timeout;

  final http.Client _client;
  final Uri _baseUrl;
  final Duration _timeout;

  /// `GET {baseUrl}/v1/students/{studentId}/next-questions?limit={limit}`.
  ///
  /// See the README for the URL, headers, parsing, status mapping
  /// and network failures. Never throws for network or server problems.
  Future<Result<List<Question>>> fetchNext({
    required String studentId,
    int limit = 10,
  }) async {
    if (limit < 1 || limit > 50) {
      throw ArgumentError.value(
        limit,
        'limit',
        'limit must be between 1 and 50 (inclusive)',
      );
    }

    final baseSegments = _baseUrl.pathSegments.where((s) => s.isNotEmpty);
    final pathSegments = [
      ...baseSegments,
      'v1',
      'students',
      studentId,
      'next-questions',
    ];
    final url = _baseUrl.replace(
      pathSegments: pathSegments,
      queryParameters: {'limit': limit.toString()},
    );

    final http.Response response;
    try {
      response = await _client
          .get(url, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);
    } on TimeoutException {
      return const Err(TimedOut());
    } on http.ClientException {
      return const Err(Offline());
    } catch (_) {
      return const Err(Offline());
    }

    final statusCode = response.statusCode;
    if (statusCode == 200) {
      final String decodedBody;
      try {
        decodedBody = utf8.decode(response.bodyBytes);
      } catch (e) {
        return Err(BadResponse('Invalid UTF-8: $e'));
      }

      final Object? jsonObject;
      try {
        jsonObject = jsonDecode(decodedBody);
      } catch (e) {
        return Err(BadResponse('Malformed JSON: $e'));
      }

      if (jsonObject is! Map<String, Object?>) {
        return const Err(BadResponse('Expected root JSON object'));
      }

      final questionsRaw = jsonObject['questions'];
      if (questionsRaw is! List) {
        return const Err(BadResponse('Missing or invalid "questions" list'));
      }

      final questions = <Question>[];
      for (final item in questionsRaw) {
        if (item is! Map<String, Object?>) {
          return const Err(BadResponse('Each question must be a JSON object'));
        }
        try {
          questions.add(Question.fromJson(item));
        } catch (e) {
          return Err(BadResponse('Invalid question format: $e'));
        }
      }
      return Ok(List.unmodifiable(questions));
    }

    if (statusCode == 401) {
      return const Err(Unauthorized());
    }

    if (statusCode == 404) {
      return const Err(NotFound());
    }

    if (statusCode == 429) {
      final retryHeader = response.headers['retry-after'];
      var seconds = 5;
      if (retryHeader != null) {
        final parsed = int.tryParse(retryHeader.trim());
        if (parsed != null && parsed >= 0) {
          seconds = parsed;
        }
      }
      return Err(RateLimited(Duration(seconds: seconds)));
    }

    if (statusCode >= 500 && statusCode <= 599) {
      return Err(ServerError(statusCode));
    }

    return Err(UnexpectedStatus(statusCode));
  }
}
