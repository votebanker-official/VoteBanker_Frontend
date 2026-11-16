import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/auth_service.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';
import 'package:votebanker/features/website/models/website_draft.dart';
import 'package:votebanker/features/website/screens/website_questions_screen.dart';
import 'package:votebanker/features/website/services/campaign_media_service.dart';

const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

Uint8List get _png => base64Decode(_pngBase64);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CampaignMediaService previous;

  setUp(() {
    previous = CampaignMediaService.instance;
    AuthService.instance.session = null;
    CampaignMediaService.instance = _QuietMedia();
  });

  tearDown(() {
    CampaignMediaService.instance = previous;
    AuthService.instance.session = null;
  });

  testWidgets('media step keeps logo and photo uploads separate', (tester) async {
    await _openMedia(tester, OnboardingController());

    expect(find.text('More photos and logo'), findsOneWidget);
    expect(find.text('Photos and logo'), findsNothing);
    expect(find.text('Logo (Optional)'), findsOneWidget);
    expect(find.text('More photos (Optional)'), findsOneWidget);
    expect(find.text('Upload Logo'), findsOneWidget);
    expect(find.text('+ Add More Photos'), findsOneWidget);
    expect(find.text('Add photo'), findsNothing);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Skip this field'), findsOneWidget);
    expect(find.text('Loading saved photos...'), findsNothing);
  });

  testWidgets('photo grid stays inside a phone-width card', (tester) async {
    final controller = OnboardingController();
    for (var index = 0; index < 2; index++) {
      controller.website.campaignPhotos.add(
        CampaignPhoto(
          id: 'm$index',
          url: 'https://cdn.example/m$index.png',
          userId: 'user-1',
          bytes: _png,
        ),
      );
    }

    await _openMedia(tester, controller, const Size(390, 844));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('campaign-photo-m0')), findsOneWidget);
    expect(find.byKey(const Key('campaign-photo-m1')), findsOneWidget);
    expect(find.text('+ Add More Photos'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('saved logo and photos render with remove controls', (tester) async {
    final controller = OnboardingController();
    controller.website
      ..logo = _png
      ..logoId = 'logo-1'
      ..logoUrl = 'https://cdn.example/logo.png'
      ..logoUserId = 'user-1';
    for (var index = 0; index < 3; index++) {
      controller.website.campaignPhotos.add(
        CampaignPhoto(
          id: 'p$index',
          url: 'https://cdn.example/p$index.png',
          userId: 'user-1',
          bytes: _png,
        ),
      );
    }

    await _openMedia(tester, controller);

    expect(find.text('Replace logo'), findsOneWidget);
    expect(find.byKey(const Key('logo-preview')), findsOneWidget);
    expect(find.byKey(const Key('remove-logo')), findsOneWidget);
    expect(find.byKey(const Key('campaign-photo-p0')), findsOneWidget);
    expect(find.byKey(const Key('campaign-photo-p2')), findsOneWidget);
    expect(find.text('+ Add More Photos'), findsOneWidget);
    expect(find.text('3 of 10'), findsOneWidget);

    await tester.tap(find.byKey(const Key('remove-photo-p1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campaign-photo-p1')), findsNothing);
    expect(find.text('2 of 10'), findsOneWidget);
    expect(controller.website.campaignPhotos.map((photo) => photo.id), ['p0', 'p2']);
  });

  testWidgets('a failed delete leaves the photo in place', (tester) async {
    CampaignMediaService.instance = _FailingMedia();
    final controller = OnboardingController();
    controller.website.campaignPhotos.add(
      CampaignPhoto(
        id: 'p0',
        url: 'https://cdn.example/p0.png',
        userId: 'user-1',
        bytes: _png,
      ),
    );

    await _openMedia(tester, controller);
    await tester.tap(find.byKey(const Key('remove-photo-p0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campaign-photo-p0')), findsOneWidget);
    expect(find.text('Could not remove that image. Please try again.'), findsOneWidget);
  });

  testWidgets('the add control hides once 10 photos are saved', (tester) async {
    final controller = OnboardingController();
    for (var index = 0; index < 10; index++) {
      controller.website.campaignPhotos.add(
        CampaignPhoto(
          id: 'p$index',
          url: 'https://cdn.example/p$index.png',
          userId: 'user-1',
          bytes: _png,
        ),
      );
    }

    await _openMedia(tester, controller);

    expect(find.text('+ Add More Photos'), findsNothing);
    expect(find.text('10 of 10'), findsOneWidget);
    expect(find.byKey(const Key('remove-photo-p9')), findsOneWidget);
  });
}

Future<void> _openMedia(
  WidgetTester tester,
  OnboardingController controller, [
  Size size = const Size(900, 1800),
]) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ThemeScope(
      controller: ThemeController(),
      child: OnboardingScope(
        controller: controller,
        child: MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const WebsiteQuestionsScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  for (var step = 0; step < 4; step++) {
    final fields = find.byType(TextField);
    final count = fields.evaluate().length;
    for (var i = 0; i < count; i++) {
      await tester.enterText(fields.at(i), 'Answer $step $i');
    }
    await tester.pump();
    final next = find.text('Next');
    await tester.ensureVisible(next);
    await tester.tap(next);
    await tester.pumpAndSettle();
  }
}

class _QuietMedia extends CampaignMediaService {
  @override
  Future<CampaignMediaSnapshot?> fetch() async => null;

  @override
  Future<void> deletePhoto(String id) async {}
}

class _FailingMedia extends CampaignMediaService {
  @override
  Future<CampaignMediaSnapshot?> fetch() async => null;

  @override
  Future<void> deletePhoto(String id) async {
    throw const CampaignMediaException('delete_failed');
  }
}
