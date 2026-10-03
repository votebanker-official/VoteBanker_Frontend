import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';
import 'package:votebanker/features/merchandise/models/merchandise_product.dart';
import 'package:votebanker/features/merchandise/screens/merchandise_design_screen.dart';
import 'package:votebanker/features/merchandise/screens/merchandise_screen.dart';
import 'package:votebanker/features/merchandise/services/merchandise_service.dart';

void main() {
  testWidgets('the marketplace lists campaign merchandise', (tester) async {
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
    expect(find.text('Design and order'), findsWidgets);
    expect(find.text('Coming later'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a design request keeps the line the user typed and does not charge', (tester) async {
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

    await tester.enterText(find.byType(TextField).at(0), 'River Ward meetings');
    await tester.enterText(find.byType(TextField).at(1), 'Meera Rao');
    final save = find.text('Save design request');
    await tester.ensureVisible(save);
    await tester.pumpAndSettle();
    await tester.tap(save);
    await tester.pumpAndSettle();

    expect(saved?['campaign_line'], 'River Ward meetings');
    expect(saved?['contact_name'], 'Meera Rao');
    expect(saved?['product_slug'], 'cap');
    expect(find.textContaining('nothing is charged'), findsOneWidget);
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
