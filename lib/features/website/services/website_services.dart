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
    // TODO: Send audio to the VOTE BANKER backend. Do not put a provider key in the app.
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
    // TODO: Ask the VOTE BANKER backend to translate. This preview keeps the original words.
    return TranslatedText(text: value, pending: true);
  }
}

abstract class WebsiteGenerationService {
  /// Later: POST /api/website/generate with inputLanguage, websiteLanguage,
  /// description, answers, selectedSections, and style.
  Future<WebsiteDocument> generate(WebsiteDraft draft);
}

class MockWebsiteGenerationService implements WebsiteGenerationService {
  MockWebsiteGenerationService(this.translation);

  final ContentTranslationService translation;

  @override
  Future<WebsiteDocument> generate(WebsiteDraft draft) async {
    // TODO: Replace this mock with POST /api/website/generate. Do not put a provider key here.
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
    // TODO: Call the VOTE BANKER backend payment API. Do not mark this as paid.
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
    // TODO: Call the domain provider through the VOTE BANKER backend.
    return const PublishAttempt(connected: false);
  }

  @override
  Future<PublishAttempt> usePlatformDomain() async {
    // TODO: Reserve a VOTE BANKER domain through the backend.
    return const PublishAttempt(connected: false);
  }

  @override
  Future<PublishAttempt> publish() async {
    // TODO: Publish only after the backend confirms payment and domain setup.
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
       generation = generation ??
           MockWebsiteGenerationService(
             translation ?? MockContentTranslationService(),
           );

  final SpeechToTextService speech;
  final ContentTranslationService translation;
  final WebsiteGenerationService generation;
  final PaymentService payment;
  final WebsitePublishingService publishing;
}
