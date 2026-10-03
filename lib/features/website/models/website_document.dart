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

  WebsiteSection copyWith({
    String? heading,
    String? subtitle,
    String? content,
    List<WebsiteItem>? items,
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
    );
  }
}

/// The page a visitor would see. Every sentence here comes from the draft.
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

  WebsiteSection? find(WebsiteSectionType type) {
    for (final section in sections) {
      if (section.type == type && section.enabled) {
        return section;
      }
    }
    return null;
  }

  bool has(WebsiteSectionType type) => find(type) != null;
}
