import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dsc26_flt_w03/data/repositories/practice_repository.dart';
import 'package:dsc26_flt_w03/data/services/api_failure.dart';
import 'package:dsc26_flt_w03/data/services/question_api.dart';
import 'package:dsc26_flt_w03/domain/models/question.dart';
import 'package:dsc26_flt_w03/ui/practice/cubit/practice_cubit.dart';
import 'package:dsc26_flt_w03/ui/practice/cubit/practice_state.dart';
import 'package:dsc26_flt_w03/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockPracticeRepository extends Mock implements PracticeRepository {}

void main() {
  late MockPracticeRepository repository;

  setUp(() {
    repository = MockPracticeRepository();
  });

  const question = Question(
    id: 'q1',
    skillId: 's1',
    stem: 'stem',
    choices: ['a', 'b'],
  );

  group('PracticeCubit', () {
    test('initial state is PracticeInitial', () {
      final cubit = PracticeCubit(repository: repository, studentId: 's-1');
      expect(cubit.state, const PracticeInitial());
      cubit.close();
    });

    blocTest<PracticeCubit, PracticeState>(
      'emits [PracticeLoading, PracticeSuccess] when repository returns non-empty questions',
      build: () {
        when(() => repository.nextQuestions('s-1'))
            .thenAnswer((_) async => const Ok([question]));
        return PracticeCubit(repository: repository, studentId: 's-1');
      },
      act: (cubit) => cubit.loadQuestions(),
      expect: () => [
        const PracticeLoading(),
        const PracticeSuccess([question]),
      ],
    );

    blocTest<PracticeCubit, PracticeState>(
      'emits [PracticeLoading, PracticeEmpty] when repository returns empty questions',
      build: () {
        when(() => repository.nextQuestions('s-1'))
            .thenAnswer((_) async => const Ok([]));
        return PracticeCubit(repository: repository, studentId: 's-1');
      },
      act: (cubit) => cubit.loadQuestions(),
      expect: () => [
        const PracticeLoading(),
        const PracticeEmpty(),
      ],
    );

    blocTest<PracticeCubit, PracticeState>(
      'emits [PracticeLoading, PracticeFailure] when repository returns failure',
      build: () {
        when(() => repository.nextQuestions('s-1'))
            .thenAnswer((_) async => const Err(Offline()));
        return PracticeCubit(repository: repository, studentId: 's-1');
      },
      act: (cubit) => cubit.loadQuestions(),
      expect: () => [
        const PracticeLoading(),
        const PracticeFailure(Offline()),
      ],
    );

    test('ignores concurrent load calls while already loading (double-refresh guard)', () async {
      final completer = Completer<Result<List<Question>>>();
      var callCount = 0;
      when(() => repository.nextQuestions('s-1')).thenAnswer((_) {
        callCount++;
        return completer.future;
      });

      final cubit = PracticeCubit(repository: repository, studentId: 's-1');
      final future1 = cubit.loadQuestions();
      final future2 = cubit.loadQuestions(); // Second call while loading

      expect(callCount, 1);
      completer.complete(const Ok([question]));
      await Future.wait([future1, future2]);

      expect(cubit.state, const PracticeSuccess([question]));
      cubit.close();
    });

    test('does not throw or emit state after cubit is closed mid-request', () async {
      final completer = Completer<Result<List<Question>>>();
      when(() => repository.nextQuestions('s-1')).thenAnswer((_) => completer.future);

      final cubit = PracticeCubit(repository: repository, studentId: 's-1');
      unawaited(cubit.loadQuestions());
      expect(cubit.state, const PracticeLoading());

      await cubit.close();
      expect(cubit.isClosed, isTrue);

      // Completing after cubit is closed
      completer.complete(const Ok([question]));
      await Future<void>.delayed(Duration.zero);
      // Cubit was closed, state emissions stopped without throwing Bad state
    });
  });
}
