import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/features/website/models/website_builder_draft.dart';
import 'package:votebanker/features/website/widgets/leader_portfolio_site.dart';

void main() {
  testWidgets('mobile hero stays compact across phone widths', (tester) async {
    for (final width in [320.0, 375.0, 390.0, 440.0]) {
      await _pump(tester, width: width, height: 956);
      expect(find.byKey(const ValueKey('hero-layout-column')), findsOneWidget);
      expect(find.byKey(const ValueKey('hero-layout-row')), findsNothing);
      expect(find.byIcon(Icons.menu), findsOneWidget);

      final narrow = width < 360;
      expect(
        tester.getSize(find.byKey(const ValueKey('websiteHeroPhoto'))),
        Size(narrow ? 110 : 124, narrow ? 142 : 154),
      );
      final hero = tester.getSize(
        find.byKey(const ValueKey('hero-layout-column')),
      );
      expect(hero.height, lessThan(360), reason: 'width $width');
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
  });

  testWidgets('tablet and desktop hero keep the wide layout', (tester) async {
    for (final width in [800.0, 1280.0]) {
      await _pump(tester, width: width, height: 900);
      expect(find.byKey(const ValueKey('hero-layout-row')), findsOneWidget);
      expect(find.byKey(const ValueKey('hero-layout-column')), findsNothing);
      expect(find.byIcon(Icons.menu), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('websiteHeroPhoto'))),
        const Size(160, 190),
      );
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required double width,
  required double height,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final draft =
      WebsiteBuilderDraft()
        ..fullName = 'Vaishnavi Kaladagi'
        ..party = 'Indian National Congress';

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: height,
          child: LeaderPortfolioSite(draft: draft, showDemoNote: false),
        ),
      ),
    ),
  );
  await tester.pump();
}
