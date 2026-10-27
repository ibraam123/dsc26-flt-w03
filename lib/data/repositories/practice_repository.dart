import '../../domain/models/question.dart';
import '../../utils/result.dart';
import '../services/api_failure.dart';
import '../services/question_api.dart';

/// The source of truth for practice questions. Owns the retry policy.
///
/// Keep the constructor and the signature of [nextQuestions] exactly.
class PracticeRepository {
  // ignore: prefer_initializing_formals
  PracticeRepository({
    required QuestionApi api,
    required Future<void> Function(Duration) sleep,
    int maxRetries = 2,
  })  : _api = api,
        _sleep = sleep,
        _maxRetries = maxRetries;

  final QuestionApi _api;
  final Future<void> Function(Duration) _sleep;
  final int _maxRetries;

  /// Retries transient failures at most maxRetries times, waiting
  /// 1 s, 2 s, ... (Retry-After for 429, capped at 30 s). Return permanent
  /// failures after one call.
  Future<Result<List<Question>>> nextQuestions(String studentId) async {
    var result = await _api.fetchNext(studentId: studentId);

    for (var retry = 0; retry < _maxRetries; retry++) {
      if (result is Ok<List<Question>>) {
        return result;
      }

      final failure = (result as Err<List<Question>>).failure;
      if (!failure.isTransient) {
        return result;
      }

      final Duration wait;
      if (failure is RateLimited) {
        wait = failure.retryAfter > const Duration(seconds: 30)
            ? const Duration(seconds: 30)
            : failure.retryAfter;
      } else {
        wait = Duration(seconds: 1 << retry);
      }

      await _sleep(wait);
      result = await _api.fetchNext(studentId: studentId);
    }

    return result;
  }
}
