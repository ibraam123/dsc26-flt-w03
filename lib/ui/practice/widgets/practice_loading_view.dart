import 'package:flutter/material.dart';

/// Loading indicator view displayed while fetching questions.
class PracticeLoadingView extends StatelessWidget {
  const PracticeLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('practice-loading'),
      child: CircularProgressIndicator(),
    );
  }
}
