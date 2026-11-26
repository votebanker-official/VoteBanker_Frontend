import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/profile_service.dart';
import '../../features/onboarding/state/onboarding_controller.dart';

/// Route names only. Screens import this file. The page router must not be
/// imported by a screen, or the web compiler drops that screen.
abstract final class AppRoutes {
  static const login = '/';
  static const signUp = '/signup';
  static const forgotPassword = '/forgot-password';
  static const resetChannel = '/forgot-password/channel';
  static const resetOtp = '/forgot-password/otp';
  static const resetPassword = '/forgot-password/new';
  static const resetSuccess = '/forgot-password/success';
  static const authCallback = '/auth/callback';
  static const otp = '/otp';
  static const profile = '/profile';
  static const myPortfolio = '/my-portfolio';
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
  static const voterLists = '/voter-lists';
  static const campaignTemplates = '/campaign-templates';
  static const speechPreview = '/campaign-templates/speech-preview';
  static const vrmRecords = '/vrm/records';
  static const vrmGetMore = '/vrm/get-more';
  static const volunteers = '/volunteers';
  static const team = '/team';
  static const socialContacts = '/social-media';
  static const socialIntegration = '/social-integration';
  static const ready = '/ready';
  static const dashboard = '/dashboard';
  static const campaignManagement = '/campaign-management';
  static const mobileNavigationArgument = 'mobile-navigation';
  static const administrations = '/administrations';
  static const admin = '/admin';
  static const adminClient = '/admin/client';
  static const merchandise = '/merchandise';
  static const speech = '/speech';
  static const letter = '/letter';
  static const about = '/about';
  static const privacyPolicy = '/privacy-policy';
  static const settings = '/settings';
  static const helpCenter = '/help-center';
  static const faqs = '/faqs';
  static const terms = '/terms-and-conditions';
  static const dataDeletion = '/data-deletion';
  static const electionDisclaimer = '/election-disclaimer';
  static const refundPolicy = '/refund-and-shipping-policy';
  static const contactSupport = '/contact-support';

  /// Named routes that show the shared footer. Authentication and onboarding
  /// screens are omitted on purpose.
  static const globalFooterRoutes = <String>{
    dashboard,
    campaignManagement,
    myPortfolio,
    merchandise,
    team,
    volunteers,
    speech,
    letter,
    socialIntegration,
    about,
    privacyPolicy,
    settings,
    helpCenter,
    faqs,
    terms,
    dataDeletion,
    electionDisclaimer,
    refundPolicy,
    contactSupport,
  };

  static const mobileNavigationRoutes = <String>{
    dashboard,
    vrmRecords,
    website,
    campaignManagement,
    myPortfolio,
  };

  static bool showsGlobalFooter(String route) =>
      globalFooterRoutes.contains(route);

  static bool showsMobileNavigation(String? route) {
    if (route == null) return false;
    final path = Uri.parse(route).path;
    return mobileNavigationRoutes.contains(path) ||
        globalFooterRoutes.contains(path);
  }

  static int? mobileNavigationIndex(String? route) {
    if (route == null) return null;
    return switch (Uri.parse(route).path) {
      dashboard => 0,
      vrmRecords => 1,
      website => 2,
      campaignManagement => 3,
      myPortfolio => 4,
      _ => null,
    };
  }
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
