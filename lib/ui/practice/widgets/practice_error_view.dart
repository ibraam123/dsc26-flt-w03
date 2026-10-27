import 'package:flutter/material.dart';

import '../../../data/services/api_failure.dart';

/// Failure view with friendly message and retry or sign-in action.
///
/// Ensures no text on screen contains the word "Exception".
class PracticeErrorView extends StatelessWidget {
  const PracticeErrorView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.onSignIn,
  });

  final ApiFailure failure;
  final VoidCallback onRetry;
  final VoidCallback? onSignIn;

  String _getFriendlyMessage(ApiFailure failure) {
    return switch (failure) {
      Offline() =>
        'لا يتوفر اتصال بالإنترنت. يرجى التحقق من الشبكة والمحاولة مجدداً.',
      TimedOut() => 'استغرقت الاستجابة وقتاً أطول من المتوقع. يرجى إعادة المحاولة.',
      RateLimited() =>
        'تم إرسال طلبات كثيرة في وقت قصير. يرجى الانتظار قليلاً ثم المحاولة.',
      ServerError() => 'الخادم يواجه مشكلة مؤقتة حالياً. يرجى المحاولة لاحقاً.',
      Unauthorized() => 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول للمتابعة.',
      NotFound() => 'لم نتمكن من العثور على الأسئلة المطلوبة.',
      BadResponse() => 'تعذر معالجة بيانات الأسئلة المستلمة من الخادم.',
      UnexpectedStatus() => 'حدث أمر غير متوقع أثناء جلب الأسئلة.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isUnauthorized = failure is Unauthorized;

    return Center(
      key: const Key('practice-error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isUnauthorized ? Icons.lock_outline : Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              isUnauthorized ? 'مطلوب تسجيل الدخول' : 'حدث خطأ في التحميل',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getFriendlyMessage(failure),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (isUnauthorized)
              FilledButton.icon(
                key: const Key('practice-signin'),
                onPressed: onSignIn ?? () {},
                icon: const Icon(Icons.login),
                label: const Text('تسجيل الدخول'),
              )
            else
              FilledButton.icon(
                key: const Key('practice-retry'),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
          ],
        ),
      ),
    );
  }
}
