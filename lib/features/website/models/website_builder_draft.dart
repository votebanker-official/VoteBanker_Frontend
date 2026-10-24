import 'dart:convert';
import 'dart:typed_data';

/// Canonical template ids for the website builder.
abstract final class WebsiteTemplates {
  static const professional = 'professional';
  static const official = 'official';
  static const community = 'community';
  static const all = [professional, official, community];

  /// Maps legacy portfolio ids and style ids onto the builder templates.
  static String normalize(String? id) {
    return switch (id) {
      'traditional' || 'work' || official => official,
      'peopleFirst' || 'issue' || community => community,
      'modern' || 'public' || professional => professional,
      _ => professional,
    };
  }

  static String legacyPortfolioId(String templateId) {
    return switch (normalize(templateId)) {
      official => 'traditional',
      community => 'peopleFirst',
      _ => 'modern',
    };
  }

  static String styleId(String templateId) {
    return switch (normalize(templateId)) {
      official => 'work',
      community => 'issue',
      _ => 'public',
    };
  }
}

abstract final class WebsiteStatus {
  static const draft = 'draft';
  static const pendingPayment = 'pending_payment';
  static const readyToPublish = 'ready_to_publish';
  static const published = 'published';

  static const all = [draft, pendingPayment, readyToPublish, published];

  static String normalize(String? value) {
    if (value != null && all.contains(value)) return value;
    return draft;
  }
}

abstract final class ProjectStatus {
  static const planned = 'planned';
  static const ongoing = 'ongoing';
  static const completed = 'completed';
  static const all = [planned, ongoing, completed];

  static String normalize(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    if (all.contains(v)) return v;
    return planned;
  }
}

class MediaRef {
  MediaRef({this.url = '', this.base64, this.caption = ''});

  String url;
  String? base64;
  String caption;

  Uint8List? get bytes {
    if (base64 == null || base64!.isEmpty) return null;
    try {
      return base64Decode(base64!);
    } catch (_) {
      return null;
    }
  }

  bool get hasImage => bytes != null || url.trim().isNotEmpty;

  Map<String, dynamic> toJson({bool includeBase64 = true}) => {
        'url': url,
        if (includeBase64 && base64 != null) 'base64': base64,
        'caption': caption,
      };

  static MediaRef fromJson(Map<String, dynamic> json) {
    return MediaRef(
      url: json['url'] as String? ?? '',
      base64: json['base64'] as String? ?? json['imageBase64'] as String?,
      caption: json['caption'] as String? ?? '',
    );
  }
}

class AchievementEntry {
  AchievementEntry({
    String? id,
    this.title = '',
    this.description = '',
    this.dateOrYear = '',
    MediaRef? photo,
  })  : id = id ?? 'a-${DateTime.now().microsecondsSinceEpoch}',
        photo = photo ?? MediaRef();

  final String id;
  String title;
  String description;
  String dateOrYear;
  MediaRef photo;

  bool get isEmpty =>
      title.trim().isEmpty &&
      description.trim().isEmpty &&
      dateOrYear.trim().isEmpty &&
      !photo.hasImage;

  Map<String, dynamic> toJson({bool includeBase64 = true}) => {
        'id': id,
        'title': title,
        'description': description,
        'dateOrYear': dateOrYear,
        'photo': photo.toJson(includeBase64: includeBase64),
      };

  static AchievementEntry fromJson(Map<String, dynamic> json) {
    final photo = json['photo'];
    return AchievementEntry(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dateOrYear: json['dateOrYear'] as String? ?? '',
      photo: photo is Map
          ? MediaRef.fromJson(Map<String, dynamic>.from(photo))
          : MediaRef(),
    );
  }
}

class ProjectEntry {
  ProjectEntry({
    String? id,
    this.name = '',
    this.description = '',
    this.location = '',
    this.status = ProjectStatus.planned,
    this.startDate = '',
    this.completionDate = '',
    this.progressUpdates = '',
    MediaRef? photo,
  })  : id = id ?? 'p-${DateTime.now().microsecondsSinceEpoch}',
        photo = photo ?? MediaRef();

  final String id;
  String name;
  String description;
  String location;
  String status;
  String startDate;
  String completionDate;
  String progressUpdates;
  MediaRef photo;

  bool get isEmpty =>
      name.trim().isEmpty &&
      description.trim().isEmpty &&
      location.trim().isEmpty &&
      !photo.hasImage;

  Map<String, dynamic> toJson({bool includeBase64 = true}) => {
        'id': id,
        'name': name,
        'description': description,
        'location': location,
        'status': ProjectStatus.normalize(status),
        'startDate': startDate,
        'completionDate': completionDate,
        'progressUpdates': progressUpdates,
        'photo': photo.toJson(includeBase64: includeBase64),
      };

  static ProjectEntry fromJson(Map<String, dynamic> json) {
    final photo = json['photo'];
    return ProjectEntry(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      location: json['location'] as String? ?? '',
      status: ProjectStatus.normalize(json['status'] as String?),
      startDate: json['startDate'] as String? ?? '',
      completionDate: json['completionDate'] as String? ?? '',
      progressUpdates: json['progressUpdates'] as String? ?? '',
      photo: photo is Map
          ? MediaRef.fromJson(Map<String, dynamic>.from(photo))
          : MediaRef(),
    );
  }
}

class AnnouncementEntry {
  AnnouncementEntry({
    String? id,
    this.title = '',
    this.description = '',
    this.publicationDate = '',
    this.externalLink = '',
    MediaRef? photo,
  })  : id = id ?? 'n-${DateTime.now().microsecondsSinceEpoch}',
        photo = photo ?? MediaRef();

  final String id;
  String title;
  String description;
  String publicationDate;
  String externalLink;
  MediaRef photo;

  bool get isEmpty =>
      title.trim().isEmpty &&
      description.trim().isEmpty &&
      publicationDate.trim().isEmpty &&
      externalLink.trim().isEmpty &&
      !photo.hasImage;

  Map<String, dynamic> toJson({bool includeBase64 = true}) => {
        'id': id,
        'title': title,
        'description': description,
        'publicationDate': publicationDate,
        'externalLink': externalLink,
        'photo': photo.toJson(includeBase64: includeBase64),
      };

  static AnnouncementEntry fromJson(Map<String, dynamic> json) {
    final photo = json['photo'];
    return AnnouncementEntry(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      publicationDate: json['publicationDate'] as String? ?? '',
      externalLink: json['externalLink'] as String? ?? '',
      photo: photo is Map
          ? MediaRef.fromJson(Map<String, dynamic>.from(photo))
          : MediaRef(),
    );
  }
}

class EventEntry {
  EventEntry({
    String? id,
    this.name = '',
    this.description = '',
    this.dateTime = '',
    this.venue = '',
    this.registrationLink = '',
    MediaRef? photo,
  })  : id = id ?? 'e-${DateTime.now().microsecondsSinceEpoch}',
        photo = photo ?? MediaRef();

  final String id;
  String name;
  String description;
  String dateTime;
  String venue;
  String registrationLink;
  MediaRef photo;

  bool get isEmpty =>
      name.trim().isEmpty &&
      description.trim().isEmpty &&
      dateTime.trim().isEmpty &&
      venue.trim().isEmpty &&
      !photo.hasImage;

  Map<String, dynamic> toJson({bool includeBase64 = true}) => {
        'id': id,
        'name': name,
        'description': description,
        'dateTime': dateTime,
        'venue': venue,
        'registrationLink': registrationLink,
        'photo': photo.toJson(includeBase64: includeBase64),
      };

  static EventEntry fromJson(Map<String, dynamic> json) {
    final photo = json['photo'];
    return EventEntry(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dateTime: json['dateTime'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      registrationLink: json['registrationLink'] as String? ?? '',
      photo: photo is Map
          ? MediaRef.fromJson(Map<String, dynamic>.from(photo))
          : MediaRef(),
    );
  }
}

class DesignSettings {
  DesignSettings({
    this.websiteName = '',
    MediaRef? logo,
    this.primaryColor = 0xFF1D4ED8,
    this.secondaryColor = 0xFFF08A24,
    this.backgroundColor = 0xFFF8FAFC,
    this.fontKey = 'system',
    MediaRef? heroImage,
    Map<String, bool>? sectionVisibility,
    List<String>? sectionOrder,
    Map<String, bool>? socialVisibility,
  })  : logo = logo ?? MediaRef(),
        heroImage = heroImage ?? MediaRef(),
        sectionVisibility = sectionVisibility ?? {},
        sectionOrder = sectionOrder ?? <String>[],
        socialVisibility = socialVisibility ??
            {
              'facebook': true,
              'instagram': true,
              'youtube': true,
              'twitter': true,
              'linkedin': true,
            };

  String websiteName;
  MediaRef logo;
  int primaryColor;
  int secondaryColor;
  int backgroundColor;
  String fontKey;
  MediaRef heroImage;
  Map<String, bool> sectionVisibility;
  List<String> sectionOrder;
  Map<String, bool> socialVisibility;

  static DesignSettings defaultsFor(String templateId) {
    final id = WebsiteTemplates.normalize(templateId);
    return switch (id) {
      WebsiteTemplates.official => DesignSettings(
          primaryColor: 0xFF1E3A5F,
          secondaryColor: 0xFFC9A227,
          backgroundColor: 0xFFF7F5F0,
          fontKey: 'serif',
        ),
      WebsiteTemplates.community => DesignSettings(
          primaryColor: 0xFF0F766E,
          secondaryColor: 0xFF2563EB,
          backgroundColor: 0xFFF0FDFA,
          fontKey: 'system',
        ),
      _ => DesignSettings(
          primaryColor: 0xFF1D4ED8,
          secondaryColor: 0xFFF08A24,
          backgroundColor: 0xFFF8FAFC,
          fontKey: 'system',
        ),
    };
  }

  Map<String, dynamic> toJson({bool includeBase64 = true}) => {
        'websiteName': websiteName,
        'logo': logo.toJson(includeBase64: includeBase64),
        'primaryColor': primaryColor,
        'secondaryColor': secondaryColor,
        'backgroundColor': backgroundColor,
        'fontKey': fontKey,
        'heroImage': heroImage.toJson(includeBase64: includeBase64),
        'sectionVisibility': sectionVisibility,
        'sectionOrder': sectionOrder,
        'socialVisibility': socialVisibility,
      };

  static DesignSettings fromJson(Map<String, dynamic> json) {
    final design = DesignSettings();
    design.websiteName = json['websiteName'] as String? ?? '';
    design.primaryColor = json['primaryColor'] as int? ?? design.primaryColor;
    design.secondaryColor =
        json['secondaryColor'] as int? ?? design.secondaryColor;
    design.backgroundColor =
        json['backgroundColor'] as int? ?? design.backgroundColor;
    design.fontKey = json['fontKey'] as String? ?? design.fontKey;
    final logo = json['logo'];
    if (logo is Map) {
      design.logo = MediaRef.fromJson(Map<String, dynamic>.from(logo));
    }
    final hero = json['heroImage'];
    if (hero is Map) {
      design.heroImage = MediaRef.fromJson(Map<String, dynamic>.from(hero));
    }
    final visibility = json['sectionVisibility'];
    if (visibility is Map) {
      design.sectionVisibility = {
        for (final e in visibility.entries)
          if (e.key is String) e.key as String: e.value == true,
      };
    }
    final order = json['sectionOrder'];
    if (order is List) {
      design.sectionOrder = [
        for (final item in order)
          if (item is String) item,
      ];
    }
    final social = json['socialVisibility'];
    if (social is Map) {
      design.socialVisibility = {
        for (final e in social.entries)
          if (e.key is String) e.key as String: e.value != false,
      };
    }
    return design;
  }
}

/// Full draft for the multi-step website builder.
class WebsiteBuilderDraft {
  WebsiteBuilderDraft({
    this.id,
    String? templateId,
    String? status,
    DesignSettings? design,
  })  : templateId = WebsiteTemplates.normalize(templateId),
        status = WebsiteStatus.normalize(status),
        design = design ??
            DesignSettings.defaultsFor(
              WebsiteTemplates.normalize(templateId),
            );

  String? id;
  String templateId;
  String status;
  late DesignSettings design;

  // Basic information
  String fullName = '';
  String designation = '';
  MediaRef profilePhoto = MediaRef();
  MediaRef coverPhoto = MediaRef();
  String constituency = '';
  String district = '';
  String state = '';
  String party = '';
  String shortIntro = '';
  String biography = '';
  String phone = '';
  String email = '';
  String officeAddress = '';
  String facebookUrl = '';
  String instagramUrl = '';
  String youtubeUrl = '';
  String twitterUrl = '';
  String linkedinUrl = '';

  // Professional
  String education = '';
  String professionalExperience = '';
  String politicalJourney = '';
  String expertise = '';
  List<String> speeches = <String>[];

  // Official
  String officialDesignation = '';
  String termOfOffice = '';
  String previousPositions = '';
  String publicServiceExperience = '';
  String officeName = '';
  String visitingHours = '';
  String officialPhone = '';
  String officialEmail = '';
  List<String> pressLinks = <String>[];
  List<String> publicDocuments = <String>[];

  // Community
  String communityIntro = '';
  String aboutLeader = '';
  String goalsVision = '';
  String localPriorities = '';
  String areasServed = '';
  String citizenAssistance = '';
  String serviceInstructions = '';
  /// Grievance submission is off until a real backend endpoint exists.
  bool grievanceEnabled = false;

  // Shared repeatable content
  List<AchievementEntry> achievements = <AchievementEntry>[];
  List<ProjectEntry> projects = <ProjectEntry>[];
  List<AnnouncementEntry> announcements = <AnnouncementEntry>[];
  List<EventEntry> events = <EventEntry>[];
  List<MediaRef> gallery = <MediaRef>[];
  List<String> videoUrls = <String>[];

  String? publishedUrl;
  String? publishedAt;
  String? updatedAt;
  String? createdAt;

  void selectTemplate(String id) {
    final next = WebsiteTemplates.normalize(id);
    if (next == templateId) return;
    templateId = next;
    final defaults = DesignSettings.defaultsFor(next);
    design.primaryColor = defaults.primaryColor;
    design.secondaryColor = defaults.secondaryColor;
    design.backgroundColor = defaults.backgroundColor;
    design.fontKey = defaults.fontKey;
  }

  /// Replaces party branding from the Leader Profile without clearing
  /// biography, photo, achievements, gallery, or contact fields.
  void applyPartyFromProfile(String partyName) {
    party = partyName.trim();
  }

  bool get hasProfilePhoto => profilePhoto.hasImage;

  bool get basicInfoComplete =>
      fullName.trim().isNotEmpty &&
      designation.trim().isNotEmpty &&
      constituency.trim().isNotEmpty &&
      shortIntro.trim().isNotEmpty;

  bool get canPublish =>
      basicInfoComplete &&
      hasProfilePhoto &&
      design.websiteName.trim().isNotEmpty;

  List<String> publishBlockingReasons() {
    final reasons = <String>[];
    if (fullName.trim().isEmpty) reasons.add('Full name is required.');
    if (designation.trim().isEmpty) reasons.add('Designation is required.');
    if (constituency.trim().isEmpty) {
      reasons.add('Constituency / area is required.');
    }
    if (shortIntro.trim().isEmpty) {
      reasons.add('Short introduction is required.');
    }
    if (!hasProfilePhoto) reasons.add('Profile photo is required.');
    if (design.websiteName.trim().isEmpty) {
      reasons.add('Website name is required.');
    }
    return reasons;
  }

  Map<String, dynamic> toJson({bool includeBase64 = true}) => {
        if (id != null) 'id': id,
        'templateId': templateId,
        'status': status,
        'profileData': {
          'fullName': fullName,
          'designation': designation,
          'profilePhoto': profilePhoto.toJson(includeBase64: includeBase64),
          'coverPhoto': coverPhoto.toJson(includeBase64: includeBase64),
          'constituency': constituency,
          'district': district,
          'state': state,
          'party': party,
          'shortIntro': shortIntro,
          'biography': biography,
          'phone': phone,
          'email': email,
          'officeAddress': officeAddress,
          'facebookUrl': facebookUrl,
          'instagramUrl': instagramUrl,
          'youtubeUrl': youtubeUrl,
          'twitterUrl': twitterUrl,
          'linkedinUrl': linkedinUrl,
        },
        'templateContent': {
          'education': education,
          'professionalExperience': professionalExperience,
          'politicalJourney': politicalJourney,
          'expertise': expertise,
          'speeches': speeches,
          'officialDesignation': officialDesignation,
          'termOfOffice': termOfOffice,
          'previousPositions': previousPositions,
          'publicServiceExperience': publicServiceExperience,
          'officeName': officeName,
          'visitingHours': visitingHours,
          'officialPhone': officialPhone,
          'officialEmail': officialEmail,
          'pressLinks': pressLinks,
          'publicDocuments': publicDocuments,
          'communityIntro': communityIntro,
          'aboutLeader': aboutLeader,
          'goalsVision': goalsVision,
          'localPriorities': localPriorities,
          'areasServed': areasServed,
          'citizenAssistance': citizenAssistance,
          'serviceInstructions': serviceInstructions,
          'grievanceEnabled': false,
          'achievements': [
            for (final item in achievements)
              item.toJson(includeBase64: includeBase64),
          ],
          'projects': [
            for (final item in projects)
              item.toJson(includeBase64: includeBase64),
          ],
          'announcements': [
            for (final item in announcements)
              item.toJson(includeBase64: includeBase64),
          ],
          'events': [
            for (final item in events) item.toJson(includeBase64: includeBase64),
          ],
          'gallery': [
            for (final item in gallery)
              item.toJson(includeBase64: includeBase64),
          ],
          'videoUrls': videoUrls,
        },
        'designSettings': design.toJson(includeBase64: includeBase64),
        'websiteName': design.websiteName,
        if (publishedUrl != null) 'publishedUrl': publishedUrl,
        if (publishedAt != null) 'publishedAt': publishedAt,
        if (updatedAt != null) 'updatedAt': updatedAt,
        if (createdAt != null) 'createdAt': createdAt,
      };

  static WebsiteBuilderDraft fromJson(Map<String, dynamic> json) {
    final draft = WebsiteBuilderDraft(
      id: json['id'] as String?,
      templateId: WebsiteTemplates.normalize(json['templateId'] as String?),
      status: WebsiteStatus.normalize(json['status'] as String?),
    );
    draft.publishedUrl = json['publishedUrl'] as String? ?? json['published_url'] as String?;
    draft.publishedAt = json['publishedAt'] as String? ?? json['published_at'] as String?;
    draft.updatedAt = json['updatedAt'] as String? ?? json['updated_at'] as String?;
    draft.createdAt = json['createdAt'] as String? ?? json['created_at'] as String?;

    final profile = json['profileData'] ?? json['profile_data'];
    if (profile is Map) {
      final p = Map<String, dynamic>.from(profile);
      draft.fullName = p['fullName'] as String? ?? '';
      draft.designation = p['designation'] as String? ?? '';
      draft.constituency = p['constituency'] as String? ?? '';
      draft.district = p['district'] as String? ?? '';
      draft.state = p['state'] as String? ?? '';
      draft.party = p['party'] as String? ?? '';
      draft.shortIntro = p['shortIntro'] as String? ?? '';
      draft.biography = p['biography'] as String? ?? '';
      draft.phone = p['phone'] as String? ?? '';
      draft.email = p['email'] as String? ?? '';
      draft.officeAddress = p['officeAddress'] as String? ?? '';
      draft.facebookUrl = p['facebookUrl'] as String? ?? '';
      draft.instagramUrl = p['instagramUrl'] as String? ?? '';
      draft.youtubeUrl = p['youtubeUrl'] as String? ?? '';
      draft.twitterUrl = p['twitterUrl'] as String? ?? '';
      draft.linkedinUrl = p['linkedinUrl'] as String? ?? '';
      final profilePhoto = p['profilePhoto'];
      if (profilePhoto is Map) {
        draft.profilePhoto =
            MediaRef.fromJson(Map<String, dynamic>.from(profilePhoto));
      }
      final coverPhoto = p['coverPhoto'];
      if (coverPhoto is Map) {
        draft.coverPhoto =
            MediaRef.fromJson(Map<String, dynamic>.from(coverPhoto));
      }
    }

    final content = json['templateContent'] ?? json['template_content'];
    if (content is Map) {
      final c = Map<String, dynamic>.from(content);
      draft.education = c['education'] as String? ?? '';
      draft.professionalExperience =
          c['professionalExperience'] as String? ?? '';
      draft.politicalJourney = c['politicalJourney'] as String? ?? '';
      draft.expertise = c['expertise'] as String? ?? '';
      draft.officialDesignation = c['officialDesignation'] as String? ?? '';
      draft.termOfOffice = c['termOfOffice'] as String? ?? '';
      draft.previousPositions = c['previousPositions'] as String? ?? '';
      draft.publicServiceExperience =
          c['publicServiceExperience'] as String? ?? '';
      draft.officeName = c['officeName'] as String? ?? '';
      draft.visitingHours = c['visitingHours'] as String? ?? '';
      draft.officialPhone = c['officialPhone'] as String? ?? '';
      draft.officialEmail = c['officialEmail'] as String? ?? '';
      draft.communityIntro = c['communityIntro'] as String? ?? '';
      draft.aboutLeader = c['aboutLeader'] as String? ?? '';
      draft.goalsVision = c['goalsVision'] as String? ?? '';
      draft.localPriorities = c['localPriorities'] as String? ?? '';
      draft.areasServed = c['areasServed'] as String? ?? '';
      draft.citizenAssistance = c['citizenAssistance'] as String? ?? '';
      draft.serviceInstructions = c['serviceInstructions'] as String? ?? '';
      draft.grievanceEnabled = false;
      draft.speeches = _stringList(c['speeches']);
      draft.pressLinks = _stringList(c['pressLinks']);
      draft.publicDocuments = _stringList(c['publicDocuments']);
      draft.videoUrls = _stringList(c['videoUrls']);
      draft.achievements = _mapList(c['achievements'], AchievementEntry.fromJson);
      draft.projects = _mapList(c['projects'], ProjectEntry.fromJson);
      draft.announcements =
          _mapList(c['announcements'], AnnouncementEntry.fromJson);
      draft.events = _mapList(c['events'], EventEntry.fromJson);
      draft.gallery = _mapList(c['gallery'], MediaRef.fromJson);
    }

    final design = json['designSettings'] ?? json['design_settings'];
    if (design is Map) {
      draft.design = DesignSettings.fromJson(Map<String, dynamic>.from(design));
    }
    final websiteName = json['websiteName'] ?? json['website_name'];
    if (websiteName is String && websiteName.trim().isNotEmpty) {
      draft.design.websiteName = websiteName.trim();
    }
    return draft;
  }

  String encode({bool includeBase64 = true}) =>
      jsonEncode(toJson(includeBase64: includeBase64));

  static WebsiteBuilderDraft decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return WebsiteBuilderDraft();
    return fromJson(Map<String, dynamic>.from(decoded));
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return <String>[];
    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }

  static List<T> _mapList<T>(
    Object? value,
    T Function(Map<String, dynamic> json) parse,
  ) {
    if (value is! List) return <T>[];
    return [
      for (final item in value)
        if (item is Map) parse(Map<String, dynamic>.from(item)),
    ];
  }
}
