import 'package:flutter/foundation.dart';

import '../../../data/services/api_failure.dart';
import '../../../domain/models/question.dart';

/// The base state for practice screen.
@immutable
sealed class PracticeState {
  const PracticeState();
}

/// Initial state before any request has been made.
final class PracticeInitial extends PracticeState {
  const PracticeInitial();
}

/// State while questions are loading.
final class PracticeLoading extends PracticeState {
  const PracticeLoading();
}

/// State when practice questions loaded successfully and list is non-empty.
final class PracticeSuccess extends PracticeState {
  const PracticeSuccess(this.questions);

  final List<Question> questions;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeSuccess && listEquals(other.questions, questions);

  @override
  int get hashCode => questions.hashCode;
}

/// State when there are no questions left to practice.
final class PracticeEmpty extends PracticeState {
  const PracticeEmpty();
}

/// State when loading questions failed.
final class PracticeFailure extends PracticeState {
  const PracticeFailure(this.failure);

  final ApiFailure failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeFailure && other.failure == failure;

  @override
  int get hashCode => failure.hashCode;
}
