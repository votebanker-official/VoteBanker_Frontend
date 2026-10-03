import 'dart:typed_data';

import '../../onboarding/models/onboarding_draft.dart';
import 'website_document.dart';

/// Session-only website answers. A repository can replace this when the API exists.
class WebsiteDraft {
  String style = 'public';
  String description = '';
  String inputLanguage = 'en';
  String websiteLanguage = 'en';
  bool languagesReady = false;
  bool sectionsReady = false;

  String fullName = '';
  String publicTitle = '';
  String organization = '';
  String introduction = '';
  String about = '';
  String vision = '';
  String mission = '';
  String achievements = '';
  String priorities = '';
  String publicContact = '';
  String address = '';
  String phone = '';
  String email = '';
  String socialLinks = '';
  String callToAction = '';
  String publicLinks = '';
  String eventsNote = '';

  /// 0, 1, or 2. Regenerate changes the layout only.
  int layoutVariant = 0;
  final List<Uint8List> photos = <Uint8List>[];
  Uint8List? logo;
  final Set<String> sections = <String>{};
  WebsiteDocument? preview;

  static const sectionIds = <String>[
    'home',
    'about',
    'vision',
    'mission',
    'work',
    'achievements',
    'updates',
    'events',
    'requests',
    'contact',
    'social',
    'gallery',
  ];

  static Set<String> defaultsFor(String? style) {
    return switch (style) {
      'work' => {'home', 'work', 'achievements', 'updates', 'events', 'contact'},
      'issue' => {'home', 'about', 'requests', 'contact'},
      _ => {'home', 'about', 'vision', 'contact'},
    };
  }

  void applyStyle(String? style) {
    if (style != null && style.isNotEmpty) {
      this.style = style;
    }
    if (!sectionsReady) {
      sections
        ..clear()
        ..addAll(defaultsFor(this.style));
      sectionsReady = true;
    }
  }

  void seedFromProfile(OnboardingDraft profile) {
    if (!languagesReady) {
      inputLanguage = profile.selectedLanguage;
      websiteLanguage = profile.selectedLanguage;
      languagesReady = true;
    }
    if (fullName.isEmpty) {
      fullName = profile.fullName;
    }
    if (publicTitle.isEmpty) {
      publicTitle = profile.designation;
    }
    if (organization.isEmpty) {
      organization = profile.organization;
    }
    if (publicContact.isEmpty) {
      publicContact = profile.publicContact;
    }
  }

  bool get hasWritableContent {
    return [
      description,
      fullName,
      publicTitle,
      organization,
      introduction,
      about,
      vision,
      mission,
      achievements,
      priorities,
      publicContact,
      address,
      phone,
      email,
      socialLinks,
      callToAction,
      publicLinks,
      eventsNote,
    ].any((value) => value.trim().isNotEmpty);
  }
}
