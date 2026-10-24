import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:votebanker/features/website/models/website_document.dart';
import 'package:votebanker/features/website/models/website_draft.dart';
import 'package:votebanker/features/website/services/website_services.dart';

void main() {
  test('WebsiteDocument round-trips structured AI fields', () {
    final original = WebsiteDocument.fromJson({
      'siteTitle': 'Mehta Clinic',
      'personName': 'Dr. Mehta',
      'professionalTitle': 'Family physician',
      'organization': 'Mehta Clinic',
      'tagline': 'Care close to home',
      'introduction': 'Neighborhood checkups.',
      'heroTitle': 'Care for every family',
      'websiteType': 'healthcare',
      'heroLayout': 'split',
      'primaryCta': 'Book a visit',
      'secondaryCta': 'Our services',
      'themeId': 'elegant',
      'layoutVariant': 1,
      'languageCode': 'en',
      'navigation': ['Home', 'Services', 'About'],
      'sections': [
        {
          'id': 'services',
          'type': 'services',
          'heading': 'Services',
          'content': 'Checkups and care',
          'items': [
            {'title': 'Checkups', 'description': 'Routine visits'},
          ],
          'imageUrl': 'https://images.unsplash.com/example.jpg',
          'imageSource': 'stock',
        },
      ],
      'seoTitle': 'Mehta Clinic',
      'seoDescription': 'Family care',
      'brandIdentity': 'Elegant clinic',
      'templateId': 'official',
      'designDirection': 'Elegant and premium',
      'heroImageUrl': 'https://images.unsplash.com/hero.jpg',
      'heroImageSource': 'stock',
      'source': 'ai',
    });

    expect(original.isAiGenerated, isTrue);
    expect(original.templateId, 'official');
    expect(original.find(WebsiteSectionType.services)?.items.single.title, 'Checkups');
    expect(original.heroImageSource, 'stock');

    final again = WebsiteDocument.fromJson(original.toJson());
    expect(again.siteTitle, 'Mehta Clinic');
    expect(again.sections.single.imageSource, 'stock');
    expect(again.source, 'ai');
  });

  test('ApiWebsiteGenerationService posts template facts and parses the document', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/websites/generate');
      expect(request.method, 'POST');
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['templateId'], 'community');
      expect(body['description'], contains('community health'));
      expect(body['facts']['fullName'], 'Arun Kumar');
      return http.Response(
        jsonEncode({
          'success': true,
          'source': 'ai',
          'imageSource': 'stock',
          'document': {
            'siteTitle': 'Arun Kumar',
            'personName': 'Arun Kumar',
            'professionalTitle': 'Public Representative',
            'organization': '',
            'tagline': 'Serving people',
            'introduction': 'Working with people on health and roads.',
            'heroTitle': 'For our constituency',
            'websiteType': 'leadership',
            'heroLayout': 'split',
            'primaryCta': 'Contact office',
            'secondaryCta': 'Learn more',
            'themeId': 'warm',
            'templateId': 'community',
            'designDirection': 'Community-focused and warm',
            'heroImageUrl': 'https://images.unsplash.com/photo-1',
            'heroImageSource': 'stock',
            'source': 'ai',
            'sections': [
              {'id': 'hero', 'type': 'hero', 'heading': 'Home', 'content': 'Serving people'},
              {'id': 'about', 'type': 'about', 'heading': 'About', 'content': 'Local work'},
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = ApiWebsiteGenerationService(
      client: client,
      baseUrls: const ['http://website.test'],
    );
    final draft = WebsiteDraft()
      ..templateId = 'community'
      ..fullName = 'Arun Kumar'
      ..description =
          'I work with people on community health, roads, and education.';

    final document = await service.generate(draft);
    expect(document.personName, 'Arun Kumar');
    expect(document.templateId, 'community');
    expect(document.isAiGenerated, isTrue);
    expect(document.heroImageSource, 'stock');
  });

  test('ApiWebsiteGenerationService surfaces missing AI configuration honestly', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'success': false,
          'error': 'website_ai_not_configured',
          'requiredEnv': ['WEBSITE_AI_API_KEY (or SPEECH_AI_API_KEY / OPENAI_API_KEY)'],
          'hint': 'Set WEBSITE_AI_API_KEY on the backend.',
        }),
        503,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = ApiWebsiteGenerationService(
      client: client,
      baseUrls: const ['http://website.test'],
    );

    expect(
      () => service.generate(
        WebsiteDraft()
          ..description =
              'A photographer specializing in portraits and wedding stories.',
      ),
      throwsA(
        isA<WebsiteGenerationException>()
            .having((error) => error.code, 'code', 'website_ai_not_configured')
            .having((error) => error.requiredEnv, 'requiredEnv', isNotEmpty),
      ),
    );
  });
}
