import 'dart:typed_data';

import '../../../core/utils/person_name.dart';
import '../../onboarding/models/onboarding_draft.dart';
import 'website_document.dart';

/// Session website answers. Generated documents can also be persisted via the API.
class WebsiteDraft {
  String style = 'public';
  String templateId = 'professional';
  String description = '';
  String inputLanguage = 'en';
  String websiteLanguage = 'en';
  String regenerateInstruction = '';
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
      'work' => {
        'home',
        'work',
        'achievements',
        'updates',
        'events',
        'contact',
      },
      'issue' => {'home', 'about', 'requests', 'contact'},
      _ => {'home', 'about', 'vision', 'contact'},
    };
  }

  void applyTemplate(String? template) {
    if (template != null && template.isNotEmpty) {
      templateId = template;
    }
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
      publicTitle = profile.assemblyConstituency;
    }
    if (organization.isEmpty) {
      organization = profile.organization;
    }
    if (publicContact.isEmpty) {
      publicContact = profile.publicContact;
    }
  }

  /// Full name on the website questions comes from Facebook or Google only.
  /// A signed-out visit does not keep a name copied from the leader profile.
  /// A name already typed on this website draft is left as the user wrote it.
  void applyLoginName({
    required bool signedIn,
    required String loginName,
    required String profileName,
  }) {
    final login = formatPersonName(loginName);
    final profile = profileName.trim();
    final current = fullName.trim();
    if (signedIn) {
      if (login.isNotEmpty && (current.isEmpty || current == profile)) {
        fullName = login;
        return;
      }
      if (current.isEmpty) {
        final chosen = formatPersonName(profile);
        if (chosen.isNotEmpty) {
          fullName = chosen;
        }
      }
      return;
    }
    if (current.isEmpty || current == profile) {
      fullName = '';
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
