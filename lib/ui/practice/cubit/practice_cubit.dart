// ignore_for_file: prefer_initializing_formals

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/practice_repository.dart';
import '../../../utils/result.dart';
import 'practice_state.dart';

/// Cubit managing state for the practice screen.
class PracticeCubit extends Cubit<PracticeState> {
  PracticeCubit({
    required PracticeRepository repository,
    required String studentId,
  }) : _repository = repository,
       _studentId = studentId,
       super(const PracticeInitial());

  final PracticeRepository _repository;
  final String _studentId;

  /// Loads practice questions from the repository.
  ///
  /// Prevents concurrent in-flight requests (double-refresh guard).
  /// Safely checks [isClosed] before emitting any state.
  Future<void> loadQuestions() async {
    if (state is PracticeLoading) {
      return;
    }

    emit(const PracticeLoading());

    final result = await _repository.nextQuestions(_studentId);

    if (isClosed) {
      return;
    }

    switch (result) {
      case Ok(value: final questions):
        if (questions.isEmpty) {
          emit(const PracticeEmpty());
        } else {
          emit(PracticeSuccess(questions));
        }
      case Err(failure: final failure):
        emit(PracticeFailure(failure));
    }
  }
}
