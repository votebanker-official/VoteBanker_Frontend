import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/features/website/models/portfolio_config.dart';
import 'package:votebanker/features/website/models/website_builder_draft.dart';

void main() {
  test('template designs stay separate when switching templates', () {
    final config = PortfolioConfig();
    config.templates[WebsiteTemplates.professional]!.title = 'Professional title';
    config.selectTemplate(WebsiteTemplates.official);
    config.templates[WebsiteTemplates.official]!.title = 'Official title';

    expect(config.templateId, WebsiteTemplates.official);
    expect(config.templates[WebsiteTemplates.professional]!.title,
        'Professional title');
    expect(config.active.title, 'Official title');
  });

  test('portfolio configuration round-trips and migrates legacy ids', () {
    final config = PortfolioConfig()..templateId = WebsiteTemplates.community;
    config.active
      ..title = 'Office'
      ..tagline = 'Local work'
      ..about = 'About text'
      ..fontKey = 'serif';
    config.active.gallery = [
      PortfolioGalleryItem(id: '1', caption: 'Rally', imageBase64: null),
    ];

    final restored = PortfolioConfig.decode(config.encode());
    expect(restored.templateId, WebsiteTemplates.community);
    expect(restored.active.title, 'Office');
    expect(restored.active.about, 'About text');
    expect(restored.active.gallery.single.caption, 'Rally');

    final legacy = PortfolioConfig.decode(
      '{"templateId":"peopleFirst","templates":{"peopleFirst":{"title":"Legacy","tagline":"","about":"","vision":"","achievements":"","news":"","contact":"","socialLinks":"","primaryColor":1,"accentColor":2,"fontKey":"system","layoutKey":"stacked","gallery":[]}}}',
    );
    expect(legacy.templateId, WebsiteTemplates.community);
    expect(legacy.active.title, 'Legacy');
  });

  test('website builder draft validates publish requirements', () {
    final draft = WebsiteBuilderDraft();
    expect(draft.canPublish, isFalse);
    draft
      ..fullName = 'Asha'
      ..designation = 'Councillor'
      ..constituency = 'Ward 12'
      ..shortIntro = 'Serving the ward'
      ..profilePhoto = MediaRef(url: 'https://example.com/photo.jpg');
    draft.design.websiteName = 'asha.votebanker.app';
    expect(draft.canPublish, isTrue);
    expect(draft.publishBlockingReasons(), isEmpty);
  });
}
