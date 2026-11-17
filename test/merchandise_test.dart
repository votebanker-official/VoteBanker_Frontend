import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';
import 'package:votebanker/features/merchandise/models/merchandise_product.dart';
import 'package:votebanker/features/merchandise/screens/campaign_templates_screen.dart';
import 'package:votebanker/features/merchandise/screens/merchandise_design_screen.dart';
import 'package:votebanker/features/merchandise/screens/merchandise_screen.dart';
import 'package:votebanker/features/merchandise/services/merchandise_service.dart';

void main() {
  testWidgets('the marketplace lists campaign merchandise', (tester) async {
    tester.view.physicalSize = const Size(1280, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        MerchandiseScreen(
          initialCatalog: MerchandiseCatalog(
            storageReady: true,
            products: const [
              MerchandiseProduct(
                slug: 'cap',
                name: 'Cap',
                description: 'A cap printed with the line you supply.',
                sizes: ['Free size'],
                colors: ['Navy'],
              ),
              MerchandiseProduct(
                slug: 'mug',
                name: 'Mug',
                description: 'A mug printed with the line you supply.',
                sizes: ['330 ml'],
                colors: ['White'],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Cap'), findsOneWidget);
    expect(find.text('Mug'), findsOneWidget);
    expect(find.text('Design & Order'), findsWidgets);
    expect(find.text('Coming later'), findsNothing);
    expect(find.text('Skip for now'), findsNothing);
    expect(find.text('VOTE BANKER'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a design request keeps the line the user typed and does not charge',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Map<String, dynamic>? saved;
      await tester.pumpWidget(
        _app(
          MerchandiseDesignScreen(
            product: const MerchandiseProduct(
              slug: 'cap',
              name: 'Cap',
              description: 'A cap printed with the line you supply.',
              sizes: ['Free size'],
              colors: ['Navy'],
            ),
            onSubmit: (payload) async {
              saved = payload;
            },
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextField).at(0),
        'River Ward meetings',
      );
      await tester.pump();
      final preview = tester.widget<Text>(
        find.byKey(const Key('merchPreviewLine')),
      );
      expect(preview.data, 'River Ward meetings');
      expect(find.text('LIVE PREVIEW'), findsOneWidget);
      expect(find.text('Add your photo'), findsOneWidget);
      expect(find.byKey(const ValueKey('merchAddPhoto')), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(1), 'Meera Rao');
      final save = find.text('Save design request');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(saved?['campaign_line'], 'River Ward meetings');
      expect(saved?['contact_name'], 'Meera Rao');
      expect(saved?['product_slug'], 'cap');
      expect(saved?.containsKey('campaign_photo'), isFalse);
      expect(find.textContaining('nothing is charged'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the merchandise sidebar stays off phone-width screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        const MerchandiseScreen(
          initialCatalog: MerchandiseCatalog(
            storageReady: true,
            products: [
              MerchandiseProduct(
                slug: 'cap',
                name: 'Cap',
                description: 'A cap printed with the line you supply.',
                sizes: ['Free size'],
                colors: ['Navy'],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('VOTE BANKER'), findsNothing);
    expect(find.text('Cap'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('campaign templates shows one product with the three actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        CampaignTemplatesScreen(
          service: MerchandiseService(baseUrls: const ['http://127.0.0.1:9']),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Create Your Campaign Merchandise'), findsOneWidget);
    expect(find.text('Campaign Templates'), findsNothing);
    expect(find.text('T-Shirt'), findsOneWidget);
    expect(find.text('Scarf'), findsNothing);
    expect(find.text('Design & Order'), findsOneWidget);
    expect(find.text('Book Now'), findsOneWidget);
    expect(find.text('Skip now'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Book Now'));
    await tester.pump();
    expect(find.text('Booked'), findsOneWidget);
    expect(find.text('Book Now'), findsNothing);
    await tester.pump(const Duration(milliseconds: 2500));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('Scarf'), findsOneWidget);
    expect(
      find.text('2 of ${campaignTemplateProducts.length}'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpWidget(
      _app(
        CampaignTemplatesScreen(
          service: MerchandiseService(baseUrls: const ['http://127.0.0.1:9']),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Design & Order'), findsOneWidget);
    expect(find.text('Book Now'), findsOneWidget);
    expect(find.text('Skip now'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _app(Widget home) {
  return ThemeScope(
    controller: ThemeController(),
    child: OnboardingScope(
      controller: OnboardingController(),
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    ),
  );
}
