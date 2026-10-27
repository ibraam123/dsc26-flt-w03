import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'cubit/practice_cubit.dart';
import 'cubit/practice_state.dart';
import 'widgets/practice_empty_view.dart';
import 'widgets/practice_error_view.dart';
import 'widgets/practice_list_view.dart';
import 'widgets/practice_loading_view.dart';

/// Main screen for practice exercises.
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PracticeCubit, PracticeState>(
      builder: (context, state) {
        final isLoading = state is PracticeLoading || state is PracticeInitial;

        return Scaffold(
          appBar: AppBar(
            title: const Text('تدريب مسارات'),
            actions: [
              IconButton(
                key: const Key('practice-refresh'),
                icon: const Icon(Icons.refresh),
                tooltip: 'تحديث',
                onPressed: isLoading
                    ? null
                    : () => context.read<PracticeCubit>().loadQuestions(),
              ),
            ],
          ),
          body: switch (state) {
            PracticeInitial() ||
            PracticeLoading() => const PracticeLoadingView(),
            PracticeSuccess(questions: final questions) => PracticeListView(
              questions: questions,
            ),
            PracticeEmpty() => const PracticeEmptyView(),
            PracticeFailure(failure: final failure) => PracticeErrorView(
              failure: failure,
              onRetry: () => context.read<PracticeCubit>().loadQuestions(),
            ),
          },
        );
      },
    );
  }
}
