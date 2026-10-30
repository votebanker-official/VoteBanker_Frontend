import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';
import 'package:votebanker/features/social_integration/social_integration_screen.dart';
import 'package:votebanker/features/social_integration/social_integration_service.dart';
import 'package:votebanker/features/social_integration/social_post_media.dart';

void main() {
  SocialIntegrationService service(MockClient client) {
    return SocialIntegrationService(client: client, baseUrls: const ['http://example.test']);
  }

  Map<String, dynamic> disconnected() {
    return {
      'success': true,
      'accounts': {
        'facebook': {'connected': false, 'pageCount': 0, 'status': 'setup_required'},
        'instagram': {'connected': false, 'accountCount': 0, 'status': 'setup_required'},
        'whatsapp': {'connected': false, 'businessReady': false, 'status': 'setup_required'},
      },
      'capabilities': {
        'drafts': false,
        'scheduling': false,
        'publishing': false,
        'captions': false,
        'mediaStorage': false,
      },
    };
  }

  Future<void> pump(WidgetTester tester, SocialIntegrationService api, {String name = 'Ramesh Kumar'}) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = OnboardingController()..draft.fullName = name;
    await tester.pumpWidget(
      ThemeScope(
        controller: ThemeController(ThemeMode.dark),
        child: OnboardingScope(
          controller: controller,
          child: MaterialApp(
            theme: AppTheme.dark(),
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: SocialIntegrationScreen(service: api),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('media validation accepts a small png and rejects an oversized file', () {
    expect(
      SocialPostMedia.validate(name: 'rally.png', bytes: 1200, kind: SocialMediaKind.image),
      isNotNull,
    );
    expect(
      SocialPostMedia.validate(
        name: 'rally.png',
        bytes: SocialPostMedia.imageLimit + 1,
        kind: SocialMediaKind.image,
      ),
      isNull,
    );
    expect(
      SocialPostMedia.validate(name: 'notes.exe', bytes: 100, kind: SocialMediaKind.document),
      isNull,
    );
  });

  testWidgets('unavailable integrations stay not connected', (tester) async {
    await pump(
      tester,
      service(MockClient((request) async {
        return http.Response(jsonEncode(disconnected()), 200);
      })),
    );
    expect(find.text('Setup Required'), findsNWidgets(3));
    expect(find.text('Connected'), findsNothing);
    expect(find.text('Ramesh Kumar'), findsOneWidget);
  });

  testWidgets('platform selection and caption update the preview', (tester) async {
    await pump(
      tester,
      service(MockClient((request) async {
        return http.Response(jsonEncode(disconnected()), 200);
      })),
      name: '',
    );
    await tester.enterText(find.byKey(const Key('smi-caption')), 'Town hall tonight');
    await tester.pump();
    expect(find.text('Town hall tonight'), findsWidgets);

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Instagram'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Instagram'));
    await tester.pump();
    expect(find.text('Name not set'), findsOneWidget);
    expect(find.text('Instagram'), findsWidgets);
  });

  testWidgets('draft saving confirms only after the server accepts it', (tester) async {
    var posts = 0;
    await pump(
      tester,
      service(MockClient((request) async {
        if (request.url.path.endsWith('/posts')) {
          posts += 1;
          return http.Response(jsonEncode({'success': true}), 200);
        }
        return http.Response(jsonEncode(disconnected()), 200);
      })),
    );
    await tester.ensureVisible(find.byKey(const Key('smi-save-draft')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('smi-save-draft')));
    await tester.pumpAndSettle();
    expect(posts, 1);
    expect(find.text('Draft saved.'), findsOneWidget);
  });

  testWidgets('missing publishing integration shows a setup message', (tester) async {
    await pump(
      tester,
      service(MockClient((request) async {
        if (request.url.path.endsWith('/posts')) {
          return http.Response(
            jsonEncode({'success': false, 'error': 'publishing_not_configured'}),
            501,
          );
        }
        if (request.url.path.endsWith('/captions')) {
          return http.Response(
            jsonEncode({'success': false, 'error': 'caption_ai_not_configured'}),
            501,
          );
        }
        return http.Response(jsonEncode(disconnected()), 200);
      })),
    );
    await tester.ensureVisible(find.byKey(const Key('smi-post-now')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('smi-post-now')));
    await tester.pumpAndSettle();
    expect(find.textContaining('no publishing integration'), findsOneWidget);

    await tester.tap(find.text('Generate with AI'));
    await tester.pumpAndSettle();
    expect(find.textContaining('caption model is not configured'), findsOneWidget);
  });
}
