import 'package:flutter/material.dart';

/// Empty state view shown when no questions are left to practice.
class PracticeEmptyView extends StatelessWidget {
  const PracticeEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('practice-empty'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              "لقد أتممت تدريبات اليوم!",
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              "لا توجد أسئلة متبقية حالياً. عد لاحقاً لمزيد من التمارين.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
