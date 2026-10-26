import 'package:flutter/widgets.dart';

import '../data/profile_languages.dart';
import '../../website/models/portfolio_config.dart';
import '../../website/models/website_builder_draft.dart';
import '../../website/models/website_draft.dart';
import '../../website/services/website_services.dart';
import '../models/onboarding_draft.dart';

/// Session state for onboarding. Nothing here is sent to a server.
class OnboardingController {
  OnboardingController() : locale = ValueNotifier(const Locale('en'));

  final ValueNotifier<Locale> locale;
  final OnboardingDraft draft = OnboardingDraft();
  final WebsiteDraft website = WebsiteDraft();
  final PortfolioConfig portfolio = PortfolioConfig();
  WebsiteBuilderDraft websiteBuilder = WebsiteBuilderDraft();
  final WebsiteServices websiteServices = WebsiteServices();
  bool portfolioRestored = false;
  bool websiteBuilderRestored = false;

  void setLanguageCode(String code) {
    if (!ProfileLanguages.supports(code)) {
      return;
    }
    draft.selectedLanguage = code;
    draft.preferredLanguage = code;
    if (locale.value.languageCode != code) {
      locale.value = Locale(code);
    }
  }

  /// Apply [draft.preferredLanguage] (e.g. after profile restore) to the live UI.
  void syncLocaleFromDraft() {
    final raw = draft.preferredLanguage.trim().isNotEmpty
        ? draft.preferredLanguage.trim()
        : draft.selectedLanguage.trim();
    if (raw.isEmpty) return;
    setLanguageCode(raw);
  }

  void selectDomain(String domain) {
    draft.selectedDomain = domain;
  }

  void dispose() {
    locale.dispose();
  }
}

class OnboardingScope extends InheritedWidget {
  const OnboardingScope({
    required this.controller,
    required super.child,
    super.key,
  });

  final OnboardingController controller;

  static OnboardingController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<OnboardingScope>();
    assert(scope != null, 'OnboardingScope is missing above this widget.');
    return scope!.controller;
  }

  /// Like [of] but returns null instead of asserting when no scope exists.
  static OnboardingController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<OnboardingScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(OnboardingScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
