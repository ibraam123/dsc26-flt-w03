import 'dart:async';
import 'dart:convert';

import 'package:dsc26_flt_w03/app.dart';
import 'package:dsc26_flt_w03/data/repositories/practice_repository.dart';
import 'package:dsc26_flt_w03/data/services/question_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final baseUri = Uri.parse('https://api.masaraat.test');

  Map<String, Object?> sampleQ(String id) => {
    'id': id,
    'skillId': 'chem.moles',
    'stem': 'سؤال تجريبي رقم $id',
    'choices': ['اختيار أ', 'اختيار ب', 'اختيار ج'],
  };

  http.Response okResponse(List<Map<String, Object?>> questions) =>
      http.Response.bytes(
        utf8.encode(jsonEncode({'questions': questions})),
        200,
        headers: {'content-type': 'application/json'},
      );

  group('Practice Screen UI states & requirements', () {
    testWidgets('shows loading indicator on initial start', (tester) async {
      final completer = Completer<http.Response>();
      final repo = PracticeRepository(
        api: QuestionApi(
          client: MockClient((_) => completer.future),
          baseUrl: baseUri,
        ),
        sleep: (_) async {},
      );

      await tester.pumpWidget(buildPracticeApp(repository: repo));
      await tester.pump();

      expect(find.byKey(const Key('practice-loading')), findsOneWidget);
      completer.complete(okResponse([]));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'shows practice-list and individual question-<id> rows on success',
      (tester) async {
        final repo = PracticeRepository(
          api: QuestionApi(
            client: MockClient(
              (_) async => okResponse([sampleQ('q1'), sampleQ('q2')]),
            ),
            baseUrl: baseUri,
          ),
          sleep: (_) async {},
        );

        await tester.pumpWidget(buildPracticeApp(repository: repo));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('practice-list')), findsOneWidget);
        expect(find.byKey(const Key('question-q1')), findsOneWidget);
        expect(find.byKey(const Key('question-q2')), findsOneWidget);
      },
    );

    testWidgets('shows practice-empty when questions list is empty', (
      tester,
    ) async {
      final repo = PracticeRepository(
        api: QuestionApi(
          client: MockClient((_) async => okResponse([])),
          baseUrl: baseUri,
        ),
        sleep: (_) async {},
      );

      await tester.pumpWidget(buildPracticeApp(repository: repo));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('practice-empty')), findsOneWidget);
    });

    testWidgets(
      'shows practice-error with retry button on server error (no "Exception" text)',
      (tester) async {
        final repo = PracticeRepository(
          api: QuestionApi(
            client: MockClient((_) async => http.Response('Server Error', 500)),
            baseUrl: baseUri,
          ),
          sleep: (_) async {},
          maxRetries: 0,
        );

        await tester.pumpWidget(buildPracticeApp(repository: repo));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('practice-error')), findsOneWidget);
        expect(find.byKey(const Key('practice-retry')), findsOneWidget);
        expect(find.byKey(const Key('practice-signin')), findsNothing);
        expect(find.textContaining('Exception'), findsNothing);
      },
    );

    testWidgets(
      'shows sign-in button instead of retry button for Unauthorized (401)',
      (tester) async {
        final repo = PracticeRepository(
          api: QuestionApi(
            client: MockClient((_) async => http.Response('Unauthorized', 401)),
            baseUrl: baseUri,
          ),
          sleep: (_) async {},
        );

        await tester.pumpWidget(buildPracticeApp(repository: repo));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('practice-error')), findsOneWidget);
        expect(find.byKey(const Key('practice-signin')), findsOneWidget);
        expect(find.byKey(const Key('practice-retry')), findsNothing);
        expect(find.textContaining('Exception'), findsNothing);
      },
    );

    testWidgets('practice-refresh is always present in app bar in all states', (
      tester,
    ) async {
      // 1. In loading state
      final gate = Completer<http.Response>();
      final repo = PracticeRepository(
        api: QuestionApi(
          client: MockClient((_) => gate.future),
          baseUrl: baseUri,
        ),
        sleep: (_) async {},
      );

      await tester.pumpWidget(buildPracticeApp(repository: repo));
      await tester.pump();
      expect(find.byKey(const Key('practice-refresh')), findsOneWidget);

      // 2. In success state
      gate.complete(okResponse([sampleQ('q1')]));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('practice-refresh')), findsOneWidget);
    });

    testWidgets(
      'refresh is disabled while loading and sends only one request on double tap',
      (tester) async {
        var requestCount = 0;
        final completer = Completer<http.Response>();
        final repo = PracticeRepository(
          api: QuestionApi(
            client: MockClient((_) {
              requestCount++;
              return completer.future;
            }),
            baseUrl: baseUri,
          ),
          sleep: (_) async {},
        );

        await tester.pumpWidget(buildPracticeApp(repository: repo));
        await tester.pump();
        expect(requestCount, 1);

        // Verify the button has onPressed == null while loading
        final iconButtonFinder = find.byKey(const Key('practice-refresh'));
        final iconButton = tester.widget<IconButton>(iconButtonFinder);
        expect(iconButton.onPressed, isNull);

        // Tapping it while disabled should not trigger extra requests
        await tester.tap(iconButtonFinder, warnIfMissed: false);
        await tester.tap(iconButtonFinder, warnIfMissed: false);
        await tester.pump();
        expect(requestCount, 1);

        completer.complete(okResponse([sampleQ('q1')]));
        await tester.pumpAndSettle();
        expect(requestCount, 1);

        // Now enabled, tapping triggers second request
        await tester.tap(iconButtonFinder);
        await tester.pump();
        expect(requestCount, 2);
      },
    );

    testWidgets('unmounting widget while request is in flight does not throw', (
      tester,
    ) async {
      final completer = Completer<http.Response>();
      final repo = PracticeRepository(
        api: QuestionApi(
          client: MockClient((_) => completer.future),
          baseUrl: baseUri,
        ),
        sleep: (_) async {},
      );

      await tester.pumpWidget(buildPracticeApp(repository: repo));
      await tester.pump();

      // Remove the app from tree mid-request
      await tester.pumpWidget(const SizedBox());

      // Response arrives after unmounting
      completer.complete(okResponse([sampleQ('q1')]));
      await tester.pumpAndSettle();
      // No unhandled exception or flutter framework error thrown
    });
  });
}
