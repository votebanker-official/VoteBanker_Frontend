import 'package:flutter/widgets.dart';

import '../../../app/localization/app_languages.dart';
import '../../website/models/website_draft.dart';
import '../../website/services/website_services.dart';
import '../models/onboarding_draft.dart';

/// Session state for onboarding. Nothing here is sent to a server.
class OnboardingController {
  OnboardingController() : locale = ValueNotifier(const Locale('en'));

  final ValueNotifier<Locale> locale;
  final OnboardingDraft draft = OnboardingDraft();
  final WebsiteDraft website = WebsiteDraft();
  final WebsiteServices websiteServices = WebsiteServices();

  void setLanguageCode(String code) {
    if (!AppLanguages.supports(code)) {
      return;
    }
    draft.selectedLanguage = code;
    locale.value = Locale(code);
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

  @override
  bool updateShouldNotify(OnboardingScope oldWidget) {
    return controller != oldWidget.controller;
  }
}
