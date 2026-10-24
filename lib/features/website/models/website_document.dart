import 'dart:typed_data';

enum WebsiteSectionType {
  hero,
  about,
  vision,
  mission,
  priorities,
  achievements,
  projects,
  updates,
  events,
  publicRequests,
  gallery,
  contact,
  social,
  favoriteThings,
  personality,
  services,
  menu,
  portfolio,
  appointments,
  custom,
}

WebsiteSectionType websiteSectionTypeFrom(String? raw) {
  return switch ((raw ?? '').trim()) {
    'hero' => WebsiteSectionType.hero,
    'about' => WebsiteSectionType.about,
    'vision' => WebsiteSectionType.vision,
    'mission' => WebsiteSectionType.mission,
    'priorities' => WebsiteSectionType.priorities,
    'achievements' => WebsiteSectionType.achievements,
    'projects' => WebsiteSectionType.projects,
    'updates' => WebsiteSectionType.updates,
    'events' => WebsiteSectionType.events,
    'publicRequests' => WebsiteSectionType.publicRequests,
    'gallery' => WebsiteSectionType.gallery,
    'contact' => WebsiteSectionType.contact,
    'social' => WebsiteSectionType.social,
    'favoriteThings' => WebsiteSectionType.favoriteThings,
    'personality' => WebsiteSectionType.personality,
    'services' => WebsiteSectionType.services,
    'menu' => WebsiteSectionType.menu,
    'portfolio' => WebsiteSectionType.portfolio,
    'appointments' => WebsiteSectionType.appointments,
    _ => WebsiteSectionType.custom,
  };
}

class WebsiteItem {
  const WebsiteItem({
    required this.title,
    this.description = '',
    this.meta = '',
  });

  final String title;
  final String description;
  final String meta;

  WebsiteItem copyWith({String? title, String? description, String? meta}) {
    return WebsiteItem(
      title: title ?? this.title,
      description: description ?? this.description,
      meta: meta ?? this.meta,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'meta': meta,
      };

  factory WebsiteItem.fromJson(Map<String, dynamic> json) {
    return WebsiteItem(
      title: (json['title'] as String? ?? '').trim(),
      description: (json['description'] as String? ?? '').trim(),
      meta: (json['meta'] as String? ?? '').trim(),
    );
  }
}

class WebsiteSection {
  const WebsiteSection({
    required this.id,
    required this.type,
    required this.titleKey,
    required this.order,
    this.heading = '',
    this.subtitle = '',
    this.content = '',
    this.enabled = true,
    this.items = const [],
    this.imageHint = '',
    this.imageUrl = '',
    this.imageSource = '',
  });

  final String id;
  final WebsiteSectionType type;
  final String titleKey;
  final String heading;
  final String subtitle;
  final String content;
  final bool enabled;
  final int order;
  final List<WebsiteItem> items;
  final String imageHint;
  final String imageUrl;
  final String imageSource;

  WebsiteSection copyWith({
    String? heading,
    String? subtitle,
    String? content,
    List<WebsiteItem>? items,
    String? imageHint,
    String? imageUrl,
    String? imageSource,
  }) {
    return WebsiteSection(
      id: id,
      type: type,
      titleKey: titleKey,
      heading: heading ?? this.heading,
      order: order,
      subtitle: subtitle ?? this.subtitle,
      content: content ?? this.content,
      enabled: enabled,
      items: items ?? this.items,
      imageHint: imageHint ?? this.imageHint,
      imageUrl: imageUrl ?? this.imageUrl,
      imageSource: imageSource ?? this.imageSource,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'titleKey': titleKey,
        'heading': heading,
        'subtitle': subtitle,
        'content': content,
        'enabled': enabled,
        'order': order,
        'items': [for (final item in items) item.toJson()],
        'imageHint': imageHint,
        'imageUrl': imageUrl,
        'imageSource': imageSource,
      };

  factory WebsiteSection.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return WebsiteSection(
      id: (json['id'] as String? ?? '').trim().isEmpty
          ? 'section'
          : (json['id'] as String).trim(),
      type: websiteSectionTypeFrom(json['type'] as String?),
      titleKey: (json['titleKey'] as String? ?? json['type'] as String? ?? 'custom')
          .trim(),
      heading: (json['heading'] as String? ?? '').trim(),
      subtitle: (json['subtitle'] as String? ?? '').trim(),
      content: (json['content'] as String? ?? '').trim(),
      enabled: json['enabled'] != false,
      order: json['order'] is num ? (json['order'] as num).toInt() : 0,
      items: rawItems is List
          ? [
              for (final item in rawItems)
                if (item is Map<String, dynamic>) WebsiteItem.fromJson(item),
            ]
          : const [],
      imageHint: (json['imageHint'] as String? ?? '').trim(),
      imageUrl: (json['imageUrl'] as String? ?? '').trim(),
      imageSource: (json['imageSource'] as String? ?? '').trim(),
    );
  }
}

/// The page a visitor would see.
class WebsiteDocument {
  const WebsiteDocument({
    required this.siteTitle,
    required this.personName,
    required this.professionalTitle,
    required this.organization,
    required this.tagline,
    required this.introduction,
    required this.heroTitle,
    required this.websiteType,
    required this.heroLayout,
    required this.primaryCta,
    required this.secondaryCta,
    required this.themeId,
    required this.layoutVariant,
    required this.languageCode,
    required this.translationPending,
    required this.navigation,
    required this.sections,
    this.portrait,
    this.logo,
    this.gallery = const [],
    this.seoTitle = '',
    this.seoDescription = '',
    this.brandIdentity = '',
    this.templateId = '',
    this.designDirection = '',
    this.heroImageUrl = '',
    this.heroImageSource = '',
    this.source = 'local',
  });

  final String siteTitle;
  final String personName;
  final String professionalTitle;
  final String organization;
  final String tagline;
  final String introduction;
  final String heroTitle;
  final String websiteType;
  final String heroLayout;
  final String primaryCta;
  final String secondaryCta;
  final String themeId;
  final int layoutVariant;
  final String languageCode;
  final bool translationPending;
  final List<String> navigation;
  final List<WebsiteSection> sections;
  final Uint8List? portrait;
  final Uint8List? logo;
  final List<Uint8List> gallery;
  final String seoTitle;
  final String seoDescription;
  final String brandIdentity;
  final String templateId;
  final String designDirection;
  final String heroImageUrl;
  final String heroImageSource;
  final String source;

  bool get isAiGenerated => source == 'ai';

  WebsiteSection? find(WebsiteSectionType type) {
    for (final section in sections) {
      if (section.type == type && section.enabled) {
        return section;
      }
    }
    return null;
  }

  bool has(WebsiteSectionType type) => find(type) != null;

  Map<String, dynamic> toJson() => {
        'siteTitle': siteTitle,
        'personName': personName,
        'professionalTitle': professionalTitle,
        'organization': organization,
        'tagline': tagline,
        'introduction': introduction,
        'heroTitle': heroTitle,
        'websiteType': websiteType,
        'heroLayout': heroLayout,
        'primaryCta': primaryCta,
        'secondaryCta': secondaryCta,
        'themeId': themeId,
        'layoutVariant': layoutVariant,
        'languageCode': languageCode,
        'translationPending': translationPending,
        'navigation': navigation,
        'sections': [for (final section in sections) section.toJson()],
        'seoTitle': seoTitle,
        'seoDescription': seoDescription,
        'brandIdentity': brandIdentity,
        'templateId': templateId,
        'designDirection': designDirection,
        'heroImageUrl': heroImageUrl,
        'heroImageSource': heroImageSource,
        'source': source,
      };

  factory WebsiteDocument.fromJson(
    Map<String, dynamic> json, {
    Uint8List? portrait,
    Uint8List? logo,
    List<Uint8List> gallery = const [],
  }) {
    final rawSections = json['sections'];
    final rawNav = json['navigation'];
    return WebsiteDocument(
      siteTitle: (json['siteTitle'] as String? ?? '').trim(),
      personName: (json['personName'] as String? ?? '').trim(),
      professionalTitle: (json['professionalTitle'] as String? ?? '').trim(),
      organization: (json['organization'] as String? ?? '').trim(),
      tagline: (json['tagline'] as String? ?? '').trim(),
      introduction: (json['introduction'] as String? ?? '').trim(),
      heroTitle: (json['heroTitle'] as String? ?? '').trim(),
      websiteType: (json['websiteType'] as String? ?? 'other').trim(),
      heroLayout: (json['heroLayout'] as String? ?? 'split').trim(),
      primaryCta: (json['primaryCta'] as String? ?? '').trim(),
      secondaryCta: (json['secondaryCta'] as String? ?? '').trim(),
      themeId: (json['themeId'] as String? ?? 'professional').trim(),
      layoutVariant:
          json['layoutVariant'] is num ? (json['layoutVariant'] as num).toInt() : 0,
      languageCode: (json['languageCode'] as String? ?? 'en').trim(),
      translationPending: json['translationPending'] == true,
      navigation: rawNav is List
          ? [
              for (final item in rawNav)
                if (item is String && item.trim().isNotEmpty) item.trim(),
            ]
          : const [],
      sections: rawSections is List
          ? [
              for (final item in rawSections)
                if (item is Map<String, dynamic>) WebsiteSection.fromJson(item),
            ]
          : const [],
      portrait: portrait,
      logo: logo,
      gallery: gallery,
      seoTitle: (json['seoTitle'] as String? ?? '').trim(),
      seoDescription: (json['seoDescription'] as String? ?? '').trim(),
      brandIdentity: (json['brandIdentity'] as String? ?? '').trim(),
      templateId: (json['templateId'] as String? ?? '').trim(),
      designDirection: (json['designDirection'] as String? ?? '').trim(),
      heroImageUrl: (json['heroImageUrl'] as String? ?? '').trim(),
      heroImageSource: (json['heroImageSource'] as String? ?? '').trim(),
      source: (json['source'] as String? ?? 'local').trim(),
    );
  }

  WebsiteDocument copyWith({
    String? themeId,
    int? layoutVariant,
    String? languageCode,
    bool? translationPending,
    List<WebsiteSection>? sections,
    String? source,
  }) {
    return WebsiteDocument(
      siteTitle: siteTitle,
      personName: personName,
      professionalTitle: professionalTitle,
      organization: organization,
      tagline: tagline,
      introduction: introduction,
      heroTitle: heroTitle,
      websiteType: websiteType,
      heroLayout: heroLayout,
      primaryCta: primaryCta,
      secondaryCta: secondaryCta,
      themeId: themeId ?? this.themeId,
      layoutVariant: layoutVariant ?? this.layoutVariant,
      languageCode: languageCode ?? this.languageCode,
      translationPending: translationPending ?? this.translationPending,
      navigation: navigation,
      sections: sections ?? this.sections,
      portrait: portrait,
      logo: logo,
      gallery: gallery,
      seoTitle: seoTitle,
      seoDescription: seoDescription,
      brandIdentity: brandIdentity,
      templateId: templateId,
      designDirection: designDirection,
      heroImageUrl: heroImageUrl,
      heroImageSource: heroImageSource,
      source: source ?? this.source,
    );
  }
}
