import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'data/repositories/practice_repository.dart';
import 'ui/practice/cubit/practice_cubit.dart';
import 'ui/practice/practice_screen.dart';

/// The practice app. The tests only ever call this function.
Widget buildPracticeApp({
  required PracticeRepository repository,
  String studentId = 'demo',
}) {
  return MaterialApp(
    title: 'Masaraat Practice',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
    ),
    home: BlocProvider(
      create: (context) =>
          PracticeCubit(repository: repository, studentId: studentId)
            ..loadQuestions(),
      child: const PracticeScreen(),
    ),
  );
}
