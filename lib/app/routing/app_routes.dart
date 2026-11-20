import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/profile_service.dart';
import '../../features/onboarding/state/onboarding_controller.dart';

/// Route names only. Screens import this file. The page router must not be
/// imported by a screen, or the web compiler drops that screen.
abstract final class AppRoutes {
  static const login = '/';
  static const authCallback = '/auth/callback';
  static const otp = '/otp';
  static const profile = '/profile';
  static const additionalProfile = '/profile/additional';
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
  static const blueTik = '/blue-tik';
  static const campaignTemplates = '/campaign-templates';
  static const vrm = '/vrm';
  static const vrmRecords = '/vrm/records';
  static const vrmGetMore = '/vrm/get-more';
  static const volunteers = '/volunteers';
  static const team = '/team';
  static const socialContacts = '/social-media';
  static const socialIntegration = '/social-integration';
  static const ready = '/ready';
  static const dashboard = '/dashboard';
  static const administrations = '/administrations';
  static const admin = '/admin';
  static const adminClient = '/admin/client';
  static const merchandise = '/merchandise';
  static const speech = '/speech';
  static const letter = '/letter';
}

abstract final class AppNav {
  static void open(BuildContext context, String route, {Object? arguments}) {
    final current = ModalRoute.of(context);
    if (current != null && !current.isCurrent) return;

    final draft = OnboardingScope.maybeOf(context)?.draft;
    if (draft != null) {
      unawaited(ProfileService.instance.saveDraft(draft));
    }
    unawaited(ProfileService.instance.saveLastRoute(route));
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
