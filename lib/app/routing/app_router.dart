import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/profile_service.dart';
import '../../features/onboarding/state/onboarding_controller.dart';
import '../../features/dashboard/screens/dashboard_placeholder_screen.dart';
import '../../features/onboarding/screens/basic_profile_screen.dart';
import '../../features/onboarding/screens/domain_search_screen.dart';
import '../../features/onboarding/screens/login_screen.dart';
import '../../features/onboarding/screens/otp_login_screen.dart';
import '../../features/onboarding/screens/ready_screen.dart';
import '../../features/onboarding/screens/social_setup_screen.dart';
import '../../features/onboarding/screens/vrm_setup_screen.dart';
import '../../features/onboarding/screens/website_screen.dart';

abstract final class AppRoutes {
  static const login = '/';
  static const otp = '/otp';
  static const profile = '/profile';
  static const domain = '/domain';
  static const website = '/website';
  static const social = '/social';
  static const vrm = '/vrm';
  static const ready = '/ready';
  static const dashboard = '/dashboard';
}

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      AppRoutes.otp => OtpLoginScreen(
          channel: settings.arguments == 'whatsapp' ? 'whatsapp' : 'sms',
        ),
      AppRoutes.profile => const BasicProfileScreen(),
      AppRoutes.domain => const DomainSearchScreen(),
      AppRoutes.website => const WebsiteScreen(),
      AppRoutes.social => const SocialSetupScreen(),
      AppRoutes.vrm => const VrmSetupScreen(),
      AppRoutes.ready => const ReadyScreen(),
      AppRoutes.dashboard => const DashboardPlaceholderScreen(),
      _ => const LoginScreen(),
    };

    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  static void open(BuildContext context, String route, {Object? arguments}) {
    // Every onboarding step moves forward through here, so this is where the
    // answers collected so far are saved for signed-in users.
    final draft = OnboardingScope.maybeOf(context)?.draft;
    if (draft != null) {
      unawaited(ProfileService.instance.saveDraft(draft));
    }
    Navigator.of(context).pushNamed(route, arguments: arguments);
  }

  static void back(BuildContext context, String fallbackRoute) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed(fallbackRoute);
  }
}
