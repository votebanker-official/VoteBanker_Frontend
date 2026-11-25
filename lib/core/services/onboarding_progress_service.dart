import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class OnboardingProgress {
  const OnboardingProgress({
    required this.currentStep,
    required this.completedSteps,
    required this.onboardingCompleted,
    this.onboardingCompletedAt,
  });

  final String currentStep;
  final List<String> completedSteps;
  final bool onboardingCompleted;
  final String? onboardingCompletedAt;

  factory OnboardingProgress.initial() => const OnboardingProgress(
    currentStep: '/profile',
    completedSteps: <String>[],
    onboardingCompleted: false,
  );

  factory OnboardingProgress.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['completed_steps'];
    final steps =
        rawSteps is List
            ? rawSteps.whereType<String>().toList()
            : const <String>[];
    return OnboardingProgress(
      currentStep:
          (json['current_step'] as String?)?.trim().isNotEmpty == true
              ? (json['current_step'] as String).trim()
              : '/profile',
      completedSteps: steps,
      onboardingCompleted: json['onboarding_completed'] == true,
      onboardingCompletedAt: json['onboarding_completed_at'] as String?,
    );
  }
}

class OnboardingProgressService {
  OnboardingProgressService._();

  static final OnboardingProgressService instance =
      OnboardingProgressService._();

  static const String dashboardRoute = '/dashboard';

  static const List<String> orderedSteps = <String>[
    '/profile',
    '/profile/additional',
    '/website',
    '/domain',
    '/social',
    '/blue-tik',
    '/ready',
  ];

  static const Set<String> onboardingRoutes = <String>{
    '/profile',
    '/profile/additional',
    '/domain',
    '/website',
    '/website/info',
    '/website/questions',
    '/website/sections',
    '/website/generating',
    '/website/preview',
    '/website/edit',
    '/website/purchase',
    '/website/publish',
    '/social',
    '/blue-tik',
    '/voter-lists',
    '/ready',
    '/dashboard',
  };

  Future<OnboardingProgress> fetchProgress() async {
    final session = AuthService.instance.session;
    if (session == null) return OnboardingProgress.initial();
    try {
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/api/profile/progress'),
            headers: {'Authorization': 'Bearer ${session.accessToken}'},
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return OnboardingProgress.initial();
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return OnboardingProgress.initial();
      final progress = decoded['progress'];
      if (progress is! Map<String, dynamic>) {
        return OnboardingProgress.initial();
      }
      return OnboardingProgress.fromJson(progress);
    } catch (_) {
      return OnboardingProgress.initial();
    }
  }

  Future<OnboardingProgress?> saveProgress({
    String? currentStep,
    String? completedStep,
    List<String>? completedSteps,
    bool? onboardingCompleted,
  }) async {
    final session = AuthService.instance.session;
    if (session == null) return null;
    final body = <String, dynamic>{
      if (currentStep != null) 'current_step': currentStep,
      if (completedStep != null) 'completed_step': completedStep,
      if (completedSteps != null) 'completed_steps': completedSteps,
      if (onboardingCompleted != null)
        'onboarding_completed': onboardingCompleted,
    };
    if (body.isEmpty) return fetchProgress();
    try {
      final response = await http
          .put(
            Uri.parse('${AppConfig.apiBaseUrl}/api/profile/progress'),
            headers: {
              'Authorization': 'Bearer ${session.accessToken}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final progress = decoded['progress'];
      if (progress is! Map<String, dynamic>) return null;
      return OnboardingProgress.fromJson(progress);
    } catch (_) {
      return null;
    }
  }

  Future<void> markComplete() async {
    await saveProgress(
      currentStep: dashboardRoute,
      onboardingCompleted: true,
      completedStep: '/ready',
    );
  }

  bool isKnownOnboardingRoute(String route) => onboardingRoutes.contains(route);

  String nextIncompleteRoute(OnboardingProgress progress) {
    if (progress.onboardingCompleted) return dashboardRoute;
    final completed = progress.completedSteps.toSet();
    final current = progress.currentStep;
    if (isKnownOnboardingRoute(current) &&
        current != dashboardRoute &&
        !completed.contains(current)) {
      return current;
    }
    for (final step in orderedSteps) {
      if (!completed.contains(step)) return step;
    }
    return dashboardRoute;
  }

  Future<String> resolveResumeRoute({String fallback = '/profile'}) async {
    final progress = await fetchProgress();
    final resolved = nextIncompleteRoute(progress);
    if (resolved == dashboardRoute && !progress.onboardingCompleted) {
      // All tracked steps are complete; treat as onboarded for resume.
      unawaited(markComplete());
      return dashboardRoute;
    }
    return resolved;
  }
}
