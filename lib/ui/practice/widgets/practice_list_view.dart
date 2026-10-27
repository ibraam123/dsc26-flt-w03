import 'package:flutter/material.dart';

import '../../../domain/models/question.dart';

/// Renders the list of practice questions.
class PracticeListView extends StatelessWidget {
  const PracticeListView({super.key, required this.questions});

  final List<Question> questions;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      key: const Key('practice-list'),
      padding: const EdgeInsets.all(16),
      itemCount: questions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final q = questions[index];
        return Card(
          key: Key('question-${q.id}'),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.stem,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...q.choices.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${entry.key + 1}. ${entry.value}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
