import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/auth_service.dart';
import '../models/website_document.dart';
import '../models/website_draft.dart';
import 'website_content_planner.dart';

/// Voice capture. The real provider must stay behind the VOTE BANKER backend.
abstract class SpeechToTextService {
  Future<SpeechCapture> listen({required String languageCode});
}

class SpeechCapture {
  const SpeechCapture({required this.connected, this.transcript});

  final bool connected;
  final String? transcript;
}

class MockSpeechToTextService implements SpeechToTextService {
  @override
  Future<SpeechCapture> listen({required String languageCode}) async {
    return const SpeechCapture(connected: false);
  }
}

/// Turns entered text into the website language. The provider is not connected.
abstract class ContentTranslationService {
  Future<TranslatedText> translate({
    required String text,
    required String fromLanguage,
    required String toLanguage,
  });
}

class TranslatedText {
  const TranslatedText({required this.text, required this.pending});

  final String text;
  final bool pending;
}

class MockContentTranslationService implements ContentTranslationService {
  @override
  Future<TranslatedText> translate({
    required String text,
    required String fromLanguage,
    required String toLanguage,
  }) async {
    final value = text.trim();
    if (value.isEmpty || fromLanguage == toLanguage) {
      return TranslatedText(text: value, pending: false);
    }
    return TranslatedText(text: value, pending: true);
  }
}

class WebsiteGenerationException implements Exception {
  const WebsiteGenerationException(
    this.code, {
    this.hint,
    this.requiredEnv = const [],
    this.detail,
  });

  final String code;
  final String? hint;
  final List<String> requiredEnv;
  final String? detail;
}

abstract class WebsiteGenerationService {
  Future<WebsiteDocument> generate(WebsiteDraft draft);
}

/// Calls POST /api/websites/generate. Secrets stay on the backend.
class ApiWebsiteGenerationService implements WebsiteGenerationService {
  ApiWebsiteGenerationService({
    http.Client? client,
    this.baseUrls = const [],
    this.timeout = const Duration(seconds: 360),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final List<String> baseUrls;
  final Duration timeout;

  List<String> get _bases {
    if (baseUrls.isNotEmpty) {
      return baseUrls;
    }
    final configured = AppConfig.apiBaseUrl;
    if (kDebugMode &&
        !configured.contains('127.0.0.1') &&
        !configured.contains('localhost')) {
      return ['http://127.0.0.1:5000', configured];
    }
    return [configured];
  }

  @override
  Future<WebsiteDocument> generate(WebsiteDraft draft) async {
    final response = await _send(_payload(draft));
    if (response == null) {
      throw const WebsiteGenerationException('unreachable');
    }
    final body = _json(response);
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        body['success'] == true) {
      final document = body['document'];
      if (document is Map<String, dynamic>) {
        return WebsiteDocument.fromJson(
          document,
          portrait: draft.photos.isNotEmpty ? draft.photos.first : null,
          logo: draft.logo,
          gallery: List<Uint8List>.from(draft.photos),
        );
      }
      throw const WebsiteGenerationException('bad_response');
    }

    final required = body['requiredEnv'];
    throw WebsiteGenerationException(
      body['error'] as String? ?? 'generation_failed',
      hint: body['hint'] as String?,
      detail: body['detail'] as String?,
      requiredEnv: required is List
          ? [
              for (final item in required)
                if (item is String) item,
            ]
          : const [],
    );
  }

  Map<String, dynamic> _payload(WebsiteDraft draft) {
    return {
      'description': draft.description.trim().isNotEmpty
          ? draft.description.trim()
          : [
              draft.introduction,
              draft.about,
              draft.vision,
              draft.mission,
              draft.priorities,
              draft.achievements,
            ].where((value) => value.trim().isNotEmpty).join(' '),
      'templateId': draft.templateId,
      'style': draft.style,
      'websiteLanguage': draft.websiteLanguage,
      'inputLanguage': draft.inputLanguage,
      'layoutVariant': draft.layoutVariant,
      'selectedSections': draft.sections.toList(),
      'regenerateInstruction': draft.regenerateInstruction,
      'facts': {
        'fullName': draft.fullName,
        'publicTitle': draft.publicTitle,
        'organization': draft.organization,
        'about': draft.about,
        'vision': draft.vision,
        'mission': draft.mission,
        'achievements': draft.achievements,
        'priorities': draft.priorities,
        'phone': draft.phone,
        'email': draft.email,
        'address': draft.address,
        'socialLinks': draft.socialLinks,
        'callToAction': draft.callToAction,
        'publicContact': draft.publicContact,
        'eventsNote': draft.eventsNote,
      },
    };
  }

  Future<http.Response?> _send(Map<String, dynamic> payload) async {
    http.Response? last;
    for (final base in _bases) {
      try {
        final headers = <String, String>{'Content-Type': 'application/json'};
        final token = AuthService.instance.session?.accessToken;
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
        final response = await _client
            .post(
              Uri.parse('$base/api/websites/generate'),
              headers: headers,
              body: jsonEncode(payload),
            )
            .timeout(timeout);
        last = response;
        if (response.statusCode == 404) {
          continue;
        }
        // Prefer a configured local model over Railway when Railway is not set up.
        if (kDebugMode &&
            _isRemoteApi(base) &&
            _isConfigOrAuthFailure(response) &&
            base != _bases.last) {
          continue;
        }
        return response;
      } catch (_) {
        continue;
      }
    }
    return last;
  }

  bool _isRemoteApi(String base) {
    final lower = base.toLowerCase();
    return !lower.contains('127.0.0.1') && !lower.contains('localhost');
  }

  bool _isConfigOrAuthFailure(http.Response response) {
    if (response.statusCode != 503 && response.statusCode != 502) {
      return false;
    }
    final error = _json(response)['error'];
    return error == 'website_ai_not_configured' ||
        error == 'website_ai_failed';
  }

  Map<String, dynamic> _json(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      return const {};
    }
    return const {};
  }
}

/// Local planner only. Used by tests and as an explicit offline fallback.
class MockWebsiteGenerationService implements WebsiteGenerationService {
  MockWebsiteGenerationService(this.translation);

  final ContentTranslationService translation;

  @override
  Future<WebsiteDocument> generate(WebsiteDraft draft) async {
    var pending = false;

    Future<String> convert(String value) async {
      final result = await translation.translate(
        text: value,
        fromLanguage: draft.inputLanguage,
        toLanguage: draft.websiteLanguage,
      );
      pending = pending || result.pending;
      return result.text;
    }

    final planned = const WebsiteContentGenerator().generate(draft);
    final sections = <WebsiteSection>[];
    for (final section in planned.sections) {
      final items = <WebsiteItem>[];
      for (final item in section.items) {
        items.add(
          item.copyWith(
            title: await convert(item.title),
            description: await convert(item.description),
          ),
        );
      }
      sections.add(
        section.copyWith(
          heading: await convert(section.heading),
          subtitle: await convert(section.subtitle),
          content: await convert(section.content),
          items: items,
        ),
      );
    }

    return WebsiteDocument(
      siteTitle: await convert(planned.siteTitle),
      personName: await convert(planned.personName),
      professionalTitle: await convert(planned.professionalTitle),
      organization: await convert(planned.organization),
      tagline: await convert(planned.tagline),
      introduction: await convert(planned.introduction),
      heroTitle: await convert(planned.heroTitle),
      websiteType: planned.websiteType,
      heroLayout: planned.heroLayout,
      primaryCta: await convert(planned.primaryCta),
      secondaryCta: await convert(planned.secondaryCta),
      themeId: planned.themeId,
      layoutVariant: planned.layoutVariant,
      languageCode: draft.websiteLanguage,
      translationPending: pending,
      navigation: planned.navigation,
      sections: sections,
      portrait: planned.portrait,
      logo: planned.logo,
      gallery: planned.gallery,
      templateId: draft.templateId,
      source: 'local',
    );
  }
}

abstract class PaymentService {
  Future<PaymentAttempt> startWebsitePurchase();
}

class PaymentAttempt {
  const PaymentAttempt({required this.connected});

  /// True only after a real gateway confirms payment. The mock never does that.
  final bool connected;
}

class MockPaymentService implements PaymentService {
  @override
  Future<PaymentAttempt> startWebsitePurchase() async {
    return const PaymentAttempt(connected: false);
  }
}

abstract class WebsitePublishingService {
  Future<PublishAttempt> connectDomain();

  Future<PublishAttempt> usePlatformDomain();

  Future<PublishAttempt> publish();
}

class PublishAttempt {
  const PublishAttempt({required this.connected});

  final bool connected;
}

class MockWebsitePublishingService implements WebsitePublishingService {
  @override
  Future<PublishAttempt> connectDomain() async {
    return const PublishAttempt(connected: false);
  }

  @override
  Future<PublishAttempt> usePlatformDomain() async {
    return const PublishAttempt(connected: false);
  }

  @override
  Future<PublishAttempt> publish() async {
    return const PublishAttempt(connected: false);
  }
}

class WebsiteServices {
  WebsiteServices({
    SpeechToTextService? speech,
    ContentTranslationService? translation,
    WebsiteGenerationService? generation,
    PaymentService? payment,
    WebsitePublishingService? publishing,
  }) : speech = speech ?? MockSpeechToTextService(),
       translation = translation ?? MockContentTranslationService(),
       payment = payment ?? MockPaymentService(),
       publishing = publishing ?? MockWebsitePublishingService(),
       generation = generation ?? ApiWebsiteGenerationService();

  final SpeechToTextService speech;
  final ContentTranslationService translation;
  final WebsiteGenerationService generation;
  final PaymentService payment;
  final WebsitePublishingService publishing;
}
