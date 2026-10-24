import 'website_builder_draft.dart';

class WebsiteTemplateInfo {
  const WebsiteTemplateInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.features,
    required this.primaryColor,
    required this.accentColor,
    this.recommended = false,
  });

  final String id;
  final String name;
  final String description;
  final List<String> features;
  final int primaryColor;
  final int accentColor;
  final bool recommended;
}

abstract final class WebsiteTemplateCatalog {
  static const professional = WebsiteTemplateInfo(
    id: WebsiteTemplates.professional,
    name: 'Professional',
    description:
        'Create a professional online presence to showcase your profile, experience, achievements, and public service.',
    features: [
      'Professional profile',
      'Biography',
      'Experience and political journey',
      'Key achievements',
      'Development projects',
      'News and updates',
      'Photo and video gallery',
      'Social media links',
      'Contact information',
    ],
    primaryColor: 0xFF1D4ED8,
    accentColor: 0xFFF08A24,
    recommended: true,
  );

  static const official = WebsiteTemplateInfo(
    id: WebsiteTemplates.official,
    name: 'Official',
    description:
        'Establish an official online presence to share your designation, political journey, official announcements, public activities, and contact information.',
    features: [
      'Official profile',
      'Designation and organization',
      'Political background',
      'Achievements and projects',
      'Official announcements',
      'Office address and hours',
      'Media gallery',
    ],
    primaryColor: 0xFF1E3A5F,
    accentColor: 0xFFC9A227,
  );

  static const community = WebsiteTemplateInfo(
    id: WebsiteTemplates.community,
    name: 'Community',
    description:
        'Connect with your community, showcase local development, share public activities, and help citizens reach you easily.',
    features: [
      'Leader and community information',
      'Development projects',
      'Community events',
      'Citizen services',
      'Local news and announcements',
      'Photo and video gallery',
      'Contact and get involved',
    ],
    primaryColor: 0xFF0F766E,
    accentColor: 0xFF2563EB,
  );

  /// Kept for draft ID compatibility. The selection screen offers only
  /// [professional].
  static const all = [professional, official, community];

  static const selectable = [professional];

  static WebsiteTemplateInfo byId(String? id) {
    final normalized = WebsiteTemplates.normalize(id);
    return all.firstWhere(
      (item) => item.id == normalized,
      orElse: () => professional,
    );
  }
}
