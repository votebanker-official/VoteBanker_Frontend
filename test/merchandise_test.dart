import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';
import 'package:votebanker/features/merchandise/models/merchandise_pricing.dart';
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
      final save = find.text('Order now');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();

      expect(saved?['campaign_line'], 'River Ward meetings');
      expect(saved?['contact_name'], 'Meera Rao');
      expect(saved?['product_slug'], 'cap');
      expect(saved?.containsKey('campaign_photo'), isFalse);
      expect(find.textContaining('nothing is charged'), findsOneWidget);
      expect(
        find.text('Your product is booked, and our VoteBanker team will contact you soon.'),
        findsOneWidget,
      );
      expect(find.text('Cap'), findsWidgets);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
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
          service: MerchandiseService(
            client: MockClient(
              (request) async => http.Response('{"error":"price_not_configured"}', 409),
            ),
            baseUrls: const ['http://127.0.0.1:9'],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Create Your Campaign Merchandise'), findsOneWidget);
    expect(find.text('Campaign Templates'), findsNothing);
    expect(find.text('T-Shirt'), findsWidgets);
    expect(find.text('Scarf'), findsNothing);
    expect(find.text('Design & Order'), findsOneWidget);
    expect(find.text('Order now'), findsOneWidget);
    expect(find.text('Skip now'), findsOneWidget);
    expect(find.text('50 pieces — ₹199/piece'), findsOneWidget);
    expect(find.text('₹199 per piece'), findsOneWidget);
    expect(find.text('Total Price'), findsOneWidget);
    expect(find.text('₹9,950'), findsOneWidget);
    expect(find.textContaining('Selected quantity'), findsNothing);
    expect(find.text('Custom quantity'), findsNothing);
    expect(find.text('Price is not configured'), findsNothing);
    expect(find.textContaining('GST'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Order now'));
    await tester.tap(find.text('Order now'));
    await tester.pump();
    expect(find.text('Booked'), findsNothing);
    expect(find.text('Order now'), findsWidgets);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(Icons.chevron_right).hitTestable());
    await tester.pumpAndSettle();

    expect(find.text('Scarf'), findsWidgets);
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
    expect(find.text('Order now'), findsOneWidget);
    expect(find.text('Skip now'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every merchandise product keeps its own quantity', (tester) async {
    tester.view.physicalSize = const Size(1280, 1100);
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

    expect(tester.getSize(find.byKey(const ValueKey('merchArrow-next'))).shortestSide, 52);
    expect(find.byKey(const ValueKey('merchArrow-previous')), findsNothing);
    final art = tester.getSize(find.byKey(const ValueKey('merchProductArt-t-shirt')));
    expect(art.shortestSide, greaterThanOrEqualTo(320));

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    expect(find.text('Custom quantity'), findsNothing);
    expect(find.text('1000 pieces — ₹199/piece'), findsWidgets);
    await tester.tap(find.text('100 pieces — ₹199/piece').last);
    await tester.pumpAndSettle();
    expect(find.text('100 pieces — ₹199/piece'), findsOneWidget);
    expect(find.text('₹19,900'), findsOneWidget);

    for (var index = 0; index < campaignTemplateProducts.length; index++) {
      final product = campaignTemplateProducts[index];
      expect(find.text(product.name), findsOneWidget);
      expect(find.text('Total Price'), findsWidgets);
      expect(find.textContaining('GST'), findsNothing);
      expect(find.textContaining('Tax'), findsNothing);
      final label = switch (product.slug) {
        't-shirt' => '100 pieces — ₹199/piece',
        'scarf' => '50 pieces — ₹50/piece',
        'flag' => '50 pieces — ₹100/piece',
        'badge' => '50 pieces — ₹60/piece',
        'cap' => '50 pieces — ₹120/piece',
        'mug' => '50 pieces — ₹80/piece',
        'poster' => '50 pieces — ₹150/piece',
        'sticker' => '50 pieces — ₹20/piece',
        'keychain' => '50 pieces — ₹40/piece',
        'pen' => '50 pieces — ₹10/piece',
        'bag' => '50 pieces — ₹150/piece',
        'gift-box' => '50 pieces — ₹50/piece',
        _ => '50 pieces',
      };
      final total = switch (product.slug) {
        't-shirt' => '₹19,900',
        'scarf' => '₹2,500',
        'flag' => '₹5,000',
        'badge' => '₹3,000',
        'cap' => '₹6,000',
        'mug' => '₹4,000',
        'poster' => '₹7,500',
        'sticker' => '₹1,000',
        'keychain' => '₹2,000',
        'pen' => '₹500',
        'bag' => '₹7,500',
        'gift-box' => '₹2,500',
        _ => '',
      };
      expect(find.text(label), findsOneWidget);
      expect(find.text(total), findsOneWidget);
      expect(find.text('Price is not configured'), findsNothing);
      expect(find.byIcon(Icons.chevron_left).hitTestable(), index == 0 ? findsNothing : findsOneWidget);
      expect(
        find.byIcon(Icons.chevron_right).hitTestable(),
        index == campaignTemplateProducts.length - 1 ? findsNothing : findsOneWidget,
      );
      if (index < campaignTemplateProducts.length - 1) {
        await tester.tap(find.byIcon(Icons.chevron_right).hitTestable());
        await tester.pumpAndSettle();
      }
    }

    for (var index = campaignTemplateProducts.length - 1; index > 0; index--) {
      await tester.tap(find.byIcon(Icons.chevron_left).hitTestable());
      await tester.pumpAndSettle();
    }
    expect(find.text('T-Shirt'), findsOneWidget);
    expect(find.text('100 pieces — ₹199/piece'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the quantity menu lists only the seven priced options', (tester) async {
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        CampaignTemplatesScreen(
          products: campaignTemplateProducts.where((item) => item.slug == 'mug').toList(),
          service: MerchandiseService(baseUrls: const ['http://127.0.0.1:9']),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    for (final quantity in merchandisePresetQuantities) {
      expect(find.text('$quantity pieces — ₹80/piece'), findsWidgets);
    }
    expect(find.text('Custom quantity'), findsNothing);
    expect(find.byKey(const ValueKey('merchCustomQuantity')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a configured price is confirmed before booking', (tester) async {
    tester.view.physicalSize = const Size(1280, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final client = MockClient((request) async {
      if (request.url.path.endsWith('/quote')) {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final quantity = body['quantity'] as int;
        final unit = quantity >= 100 ? 1800 : 2500;
        return http.Response(
          jsonEncode({
            'product_slug': body['product_slug'],
            'product_name': 'Cap',
            'quantity': quantity,
            'unit_price_paise': unit,
            'line_total_paise': unit * quantity,
            'currency': 'INR',
          }),
          200,
        );
      }
      return http.Response('{}', 404);
    });

    await tester.pumpWidget(
      _app(
        CampaignTemplatesScreen(
          products: const [
            MerchandiseProduct(
              slug: 'cap',
              name: 'Cap',
              description: 'A cap printed with the line you supply.',
              sizes: ['Free size'],
              colors: ['Navy'],
              priceSlabs: [
                MerchandisePriceSlab(minQuantity: 50, unitPricePaise: 2500),
                MerchandisePriceSlab(minQuantity: 100, unitPricePaise: 2000),
              ],
            ),
          ],
          service: MerchandiseService(
            client: client,
            baseUrls: const ['http://127.0.0.1:9'],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('₹25 per piece'), findsOneWidget);
    expect(find.text('₹1,250'), findsOneWidget);
    expect(find.textContaining('GST'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('100 pieces — ₹20/piece').last);
    await tester.pumpAndSettle();
    expect(find.text('₹20 per piece'), findsOneWidget);
    expect(find.text('₹2,000'), findsOneWidget);

    await tester.ensureVisible(find.text('Order now'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Order now').first);
    await tester.pumpAndSettle();
    expect(
      find.text('Your product is booked, and our VoteBanker team will contact you soon.'),
      findsOneWidget,
    );
    expect(find.text('₹1,800'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Booked'), findsOneWidget);
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
