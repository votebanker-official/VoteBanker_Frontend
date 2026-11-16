import 'dart:typed_data';

import '../../../core/utils/person_name.dart';
import '../../onboarding/models/onboarding_draft.dart';
import 'website_document.dart';

/// One additional campaign photo stored for the signed-in user.
class CampaignPhoto {
  CampaignPhoto({
    required this.id,
    required this.url,
    required this.userId,
    this.bytes,
  });

  final String id;
  final String url;
  final String userId;
  Uint8List? bytes;
}

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

  /// Persisted campaign logo. Empty until Supabase confirms the upload.
  String logoId = '';
  String logoUrl = '';
  String logoUserId = '';
  String mediaOwnerId = '';

  /// True after campaign photos are saved, so the gallery follows those photos.
  bool ownsGallery = false;
  final List<CampaignPhoto> campaignPhotos = <CampaignPhoto>[];
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

  void clearCampaignMedia() {
    logo = null;
    logoId = '';
    logoUrl = '';
    logoUserId = '';
    mediaOwnerId = '';
    ownsGallery = false;
    campaignPhotos.clear();
    photos.clear();
  }

  /// Replaces saved logo and campaign photos with the signed-in user's records.
  /// Bytes already downloaded for the same ids are kept.
  void applyStoredMedia({
    required String userId,
    String? logoId,
    String? logoUrl,
    String? logoUserId,
    required List<CampaignPhoto> photos,
  }) {
    if (mediaOwnerId.isNotEmpty && mediaOwnerId != userId) {
      clearCampaignMedia();
    }
    mediaOwnerId = userId;

    if (logoId == null || logoId.isEmpty) {
      if (this.logoId.isNotEmpty) {
        logo = null;
        this.logoId = '';
        this.logoUrl = '';
        this.logoUserId = '';
      }
    } else if (this.logoId != logoId) {
      this.logoId = logoId;
      this.logoUrl = logoUrl ?? '';
      this.logoUserId = (logoUserId == null || logoUserId.isEmpty)
          ? userId
          : logoUserId;
      logo = null;
    } else {
      this.logoUrl = logoUrl ?? this.logoUrl;
      if (logoUserId != null && logoUserId.isNotEmpty) {
        this.logoUserId = logoUserId;
      }
    }

    final previous = {for (final photo in campaignPhotos) photo.id: photo};
    final hadSavedPhotos = campaignPhotos.isNotEmpty;
    campaignPhotos
      ..clear()
      ..addAll([
        for (final photo in photos)
          CampaignPhoto(
            id: photo.id,
            url: photo.url,
            userId: photo.userId.isEmpty ? userId : photo.userId,
            bytes: previous[photo.id]?.bytes ?? photo.bytes,
          ),
      ]);
    if (campaignPhotos.any((photo) => photo.bytes != null) ||
        (hadSavedPhotos && campaignPhotos.isEmpty)) {
      ownsGallery = true;
      syncGalleryBytes();
    }
  }

  void syncGalleryBytes() {
    if (!ownsGallery) return;
    photos
      ..clear()
      ..addAll([
        for (final photo in campaignPhotos)
          if (photo.bytes != null) photo.bytes!,
      ]);
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
