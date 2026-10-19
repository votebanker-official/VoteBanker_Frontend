import 'dart:convert';
import 'dart:typed_data';

import 'website_builder_draft.dart';

/// Legacy portfolio website config kept for older screens and migrations.
class PortfolioConfig {
  PortfolioConfig();

  String templateId = WebsiteTemplates.professional;
  final Map<String, PortfolioDesign> templates = {
    for (final id in templateIds) id: PortfolioDesign.forTemplate(id),
  };

  static const templateIds = [
    WebsiteTemplates.professional,
    WebsiteTemplates.official,
    WebsiteTemplates.community,
  ];

  PortfolioDesign get active =>
      templates[templateId] ?? templates[WebsiteTemplates.professional]!;

  void selectTemplate(String id) {
    final normalized = WebsiteTemplates.normalize(id);
    if (!templateIds.contains(normalized)) return;
    templateId = normalized;
  }

  Map<String, dynamic> toJson() => {
        'templateId': templateId,
        'templates': {
          for (final entry in templates.entries) entry.key: entry.value.toJson(),
        },
      };

  static PortfolioConfig fromJson(Map<String, dynamic> json) {
    final config = PortfolioConfig();
    final templateId = WebsiteTemplates.normalize(json['templateId'] as String?);
    config.templateId = templateId;
    final templates = json['templates'];
    if (templates is Map) {
      for (final id in templateIds) {
        final raw = templates[id] ??
            templates[WebsiteTemplates.legacyPortfolioId(id)];
        if (raw is Map) {
          config.templates[id] = PortfolioDesign.fromJson(
            Map<String, dynamic>.from(raw),
          );
        }
      }
    }
    return config;
  }

  String encode() => jsonEncode(toJson());

  static PortfolioConfig decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return PortfolioConfig();
    return fromJson(Map<String, dynamic>.from(decoded));
  }
}

class PortfolioDesign {
  PortfolioDesign({
    required this.title,
    required this.tagline,
    required this.about,
    required this.vision,
    required this.achievements,
    required this.news,
    required this.contact,
    required this.socialLinks,
    required this.primaryColor,
    required this.accentColor,
    required this.fontKey,
    required this.layoutKey,
    List<PortfolioGalleryItem>? gallery,
  }) : gallery = gallery ?? <PortfolioGalleryItem>[];

  String title;
  String tagline;
  String about;
  String vision;
  String achievements;
  String news;
  String contact;
  String socialLinks;
  int primaryColor;
  int accentColor;
  String fontKey;
  String layoutKey;
  List<PortfolioGalleryItem> gallery;

  static PortfolioDesign forTemplate(String id) {
    final normalized = WebsiteTemplates.normalize(id);
    final colors = switch (normalized) {
      WebsiteTemplates.official => (0xFF1E3A5F, 0xFFC9A227),
      WebsiteTemplates.community => (0xFF0F766E, 0xFF2563EB),
      _ => (0xFF1D4ED8, 0xFFF08A24),
    };
    return PortfolioDesign(
      title: '',
      tagline: '',
      about: '',
      vision: '',
      achievements: '',
      news: '',
      contact: '',
      socialLinks: '',
      primaryColor: colors.$1,
      accentColor: colors.$2,
      fontKey: normalized == WebsiteTemplates.official ? 'serif' : 'system',
      layoutKey:
          normalized == WebsiteTemplates.community ? 'stacked' : 'split',
    );
  }

  PortfolioDesign copy() {
    return PortfolioDesign(
      title: title,
      tagline: tagline,
      about: about,
      vision: vision,
      achievements: achievements,
      news: news,
      contact: contact,
      socialLinks: socialLinks,
      primaryColor: primaryColor,
      accentColor: accentColor,
      fontKey: fontKey,
      layoutKey: layoutKey,
      gallery: [for (final item in gallery) item.copy()],
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'tagline': tagline,
        'about': about,
        'vision': vision,
        'achievements': achievements,
        'news': news,
        'contact': contact,
        'socialLinks': socialLinks,
        'primaryColor': primaryColor,
        'accentColor': accentColor,
        'fontKey': fontKey,
        'layoutKey': layoutKey,
        'gallery': [for (final item in gallery) item.toJson()],
      };

  static PortfolioDesign fromJson(Map<String, dynamic> json) {
    final design = PortfolioDesign.forTemplate(WebsiteTemplates.professional);
    design.title = json['title'] as String? ?? '';
    design.tagline = json['tagline'] as String? ?? '';
    design.about = json['about'] as String? ?? '';
    design.vision = json['vision'] as String? ?? '';
    design.achievements = json['achievements'] as String? ?? '';
    design.news = json['news'] as String? ?? '';
    design.contact = json['contact'] as String? ?? '';
    design.socialLinks = json['socialLinks'] as String? ?? '';
    design.primaryColor = json['primaryColor'] as int? ?? design.primaryColor;
    design.accentColor = json['accentColor'] as int? ?? design.accentColor;
    design.fontKey = json['fontKey'] as String? ?? design.fontKey;
    design.layoutKey = json['layoutKey'] as String? ?? design.layoutKey;
    final gallery = json['gallery'];
    if (gallery is List) {
      design.gallery = [
        for (final item in gallery)
          if (item is Map)
            PortfolioGalleryItem.fromJson(Map<String, dynamic>.from(item)),
      ];
    }
    return design;
  }
}

class PortfolioGalleryItem {
  PortfolioGalleryItem({
    required this.id,
    this.caption = '',
    this.imageBase64,
  });

  final String id;
  String caption;
  String? imageBase64;

  Uint8List? get image {
    if (imageBase64 == null || imageBase64!.isEmpty) return null;
    try {
      return base64Decode(imageBase64!);
    } catch (_) {
      return null;
    }
  }

  PortfolioGalleryItem copy() =>
      PortfolioGalleryItem(id: id, caption: caption, imageBase64: imageBase64);

  Map<String, dynamic> toJson() => {
        'id': id,
        'caption': caption,
        'imageBase64': imageBase64,
      };

  static PortfolioGalleryItem fromJson(Map<String, dynamic> json) {
    return PortfolioGalleryItem(
      id: json['id'] as String? ?? 'item',
      caption: json['caption'] as String? ?? '',
      imageBase64: json['imageBase64'] as String?,
    );
  }
}
