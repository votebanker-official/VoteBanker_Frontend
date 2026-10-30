import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/profile_service.dart';
import '../../features/onboarding/state/onboarding_controller.dart';
import '../../features/dashboard/screens/administrations_screen.dart';
import '../../features/dashboard/screens/dashboard_placeholder_screen.dart';
import '../../features/merchandise/screens/merchandise_screen.dart';
import '../../features/letter_generator/letter_generator_screen.dart';
import '../../features/speech_generator/speech_generator_screen.dart';
import '../../features/onboarding/screens/basic_profile_screen.dart';
import '../../features/onboarding/screens/domain_search_screen.dart';
import '../../features/onboarding/screens/login_screen.dart';
import '../../features/onboarding/screens/otp_login_screen.dart';
import '../../features/onboarding/screens/ready_screen.dart';
import '../../features/onboarding/screens/social_setup_screen.dart';
import '../../features/onboarding/screens/vrm_setup_screen.dart';
import '../../features/vrm/screens/vrm_get_more_screen.dart';
import '../../features/vrm/screens/vrm_records_screen.dart';
import '../../features/volunteers/screens/volunteer_management_screen.dart';
import '../../features/social_media/social_media_screen.dart';
import '../../features/social_integration/social_integration_screen.dart';
import '../../features/onboarding/screens/website_screen.dart';
import '../../features/website/screens/website_edit_screen.dart';
import '../../features/website/screens/website_generating_screen.dart';
import '../../features/website/screens/website_info_screen.dart';
import '../../features/website/screens/website_preview_screen.dart';
import '../../features/website/screens/website_publish_screen.dart';
import '../../features/website/screens/website_purchase_screen.dart';
import '../../features/website/screens/website_questions_screen.dart';
import '../../features/website/screens/website_sections_screen.dart';

abstract final class AppRoutes {
  static const login = '/';
  static const otp = '/otp';
  static const profile = '/profile';
  static const domain = '/domain';
  static const website = '/website';
  static const websiteInfo = '/website/info';
  static const websiteQuestions = '/website/questions';
  static const websiteSections = '/website/sections';
  static const websiteGenerating = '/website/generating';
  static const websitePreview = '/website/preview';
  static const websiteEdit = '/website/edit';
  static const websitePurchase = '/website/purchase';
  static const websitePublish = '/website/publish';
  static const social = '/social';
  static const vrm = '/vrm';
  static const vrmRecords = '/vrm/records';
  static const vrmGetMore = '/vrm/get-more';
  static const volunteers = '/volunteers';
  static const socialContacts = '/social-media';
  static const socialIntegration = '/social-integration';
  static const ready = '/ready';
  static const dashboard = '/dashboard';
  static const administrations = '/administrations';
  static const merchandise = '/merchandise';
  static const speech = '/speech';
  static const letter = '/letter';
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
      AppRoutes.websiteInfo => const WebsiteInfoScreen(),
      AppRoutes.websiteQuestions => const WebsiteQuestionsScreen(),
      AppRoutes.websiteSections => const WebsiteSectionsScreen(),
      AppRoutes.websiteGenerating => const WebsiteGeneratingScreen(),
      AppRoutes.websitePreview => const WebsitePreviewScreen(),
      AppRoutes.websiteEdit => const WebsiteEditScreen(),
      AppRoutes.websitePurchase => const WebsitePurchaseScreen(),
      AppRoutes.websitePublish => const WebsitePublishScreen(),
      AppRoutes.social => const SocialSetupScreen(),
      AppRoutes.vrm => const VrmSetupScreen(),
      AppRoutes.vrmRecords => const VrmRecordsScreen(),
      AppRoutes.vrmGetMore => const VrmGetMoreScreen(),
      AppRoutes.volunteers => const VolunteerManagementScreen(),
      AppRoutes.socialContacts => const SocialMediaScreen(),
      AppRoutes.socialIntegration => const SocialIntegrationScreen(),
      AppRoutes.ready => const ReadyScreen(),
      AppRoutes.dashboard => const DashboardPlaceholderScreen(),
      AppRoutes.administrations => const AdministrationsScreen(),
      AppRoutes.merchandise => const MerchandiseScreen(),
      AppRoutes.speech => const SpeechGeneratorScreen(),
      AppRoutes.letter => const LetterGeneratorScreen(),
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
    // Ignore repeat taps while this route is already leaving the screen.
    final current = ModalRoute.of(context);
    if (current != null && !current.isCurrent) {
      return;
    }

    // Every onboarding step moves forward through here, so this is where the
    // answers collected so far are saved for signed-in users.
    final draft = OnboardingScope.maybeOf(context)?.draft;
    if (draft != null) {
      unawaited(ProfileService.instance.saveDraft(draft));
    }
    Navigator.of(context).pushNamed(route, arguments: arguments);
  }

  static void replace(BuildContext context, String route) {
    Navigator.of(context).pushReplacementNamed(route);
  }

  static void back(BuildContext context, String fallbackRoute) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed(fallbackRoute);
  }

  /// Returns to the previous route. Does nothing when this screen is the root,
  /// and ignores a second tap while the route is already leaving.
  static void popIfPossible(BuildContext context) {
    final current = ModalRoute.of(context);
    if (current != null && !current.isCurrent) {
      return;
    }
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }
}
