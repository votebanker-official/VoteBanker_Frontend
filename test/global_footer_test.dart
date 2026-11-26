import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:votebanker/app/localization/app_localizations.dart';
import 'package:votebanker/app/routing/app_router.dart';
import 'package:votebanker/app/theme/app_colors.dart';
import 'package:votebanker/app/theme/app_theme.dart';
import 'package:votebanker/core/services/theme_controller.dart';
import 'package:votebanker/core/widgets/global_footer.dart';
import 'package:votebanker/features/campaigns/screens/campaign_management_screen.dart';
import 'package:votebanker/features/merchandise/screens/campaign_templates_screen.dart';
import 'package:votebanker/features/onboarding/screens/basic_profile_screen.dart';
import 'package:votebanker/features/profile/screens/my_portfolio_screen.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('footer is on the listed app pages and not on auth pages', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 900));

    for (final route in AppRoutes.globalFooterRoutes) {
      await tester.pumpWidget(_app(route));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final footer = find.byKey(const Key('global-footer'));
      await tester.ensureVisible(footer);
      await tester.pump();
      expect(footer.hitTestable(), findsOneWidget, reason: route);
      expect(tester.takeException(), isNull, reason: route);
    }

    await _setSurface(tester, const Size(390, 844));
    for (final route in AppRoutes.globalFooterRoutes) {
      await tester.pumpWidget(_app(route));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.byKey(const Key('global-footer')),
        findsNothing,
        reason: route,
      );
      expect(
        find.byKey(const Key('mobile-bottom-nav')),
        findsOneWidget,
        reason: route,
      );
      expect(tester.takeException(), isNull, reason: route);
    }

    for (final route in const [
      AppRoutes.login,
      AppRoutes.otp,
      AppRoutes.authCallback,
      AppRoutes.profile,
      AppRoutes.social,
    ]) {
      await tester.pumpWidget(_app(route));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(GlobalFooter), findsNothing, reason: route);
      expect(tester.takeException(), isNull, reason: route);
    }
  });

  testWidgets(
    'mobile navigation shows the five route tabs without the web footer',
    (tester) async {
      await _setSurface(tester, const Size(390, 844));
      await tester.pumpWidget(
        _app(AppRoutes.dashboard, platform: TargetPlatform.android),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('global-footer')), findsNothing);
      final bar = find.byKey(const Key('mobile-bottom-nav'));
      expect(bar, findsOneWidget);
      for (final item in const [
        ('home', 'Home', Icons.home_outlined),
        ('voters', 'Voters', Icons.people_outline),
        ('website', 'Website', Icons.language_outlined),
        ('campaigns', 'Campaigns', Icons.campaign_outlined),
        ('profile', 'Profile', Icons.person_outline),
      ]) {
        expect(
          find.descendant(of: bar, matching: find.text(item.$2)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: bar, matching: find.byIcon(item.$3)),
          findsOneWidget,
        );
        expect(find.byKey(Key('mobile-nav-${item.$1}')), findsOneWidget);
      }

      expect(
        tester
            .widget<Icon>(find.byKey(const Key('mobile-nav-icon-voters')))
            .color,
        const Color(0xFF64748B),
      );
      expect(
        tester
            .getSize(find.byKey(const Key('mobile-nav-underline-voters')))
            .width,
        0,
      );
      final activeUnderline = find.byKey(
        const Key('mobile-nav-underline-home'),
      );
      expect(tester.getSize(activeUnderline).width, closeTo(68, 1));
      expect(
        (tester.widget<AnimatedContainer>(activeUnderline).decoration!
                as BoxDecoration)
            .color,
        const Color(0xFF246BFD),
      );

      await _setSurface(tester, const Size(320, 568));
      await tester.pumpWidget(
        _app(AppRoutes.dashboard, platform: TargetPlatform.android),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mobile-bottom-nav')), findsOneWidget);
      expect(tester.getRect(bar).right, lessThanOrEqualTo(320));
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        _app(AppRoutes.dashboard, platform: TargetPlatform.iOS),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mobile-bottom-nav')), findsOneWidget);

      await _setSurface(tester, const Size(1280, 900));
      await tester.pumpWidget(
        _app(AppRoutes.dashboard, platform: TargetPlatform.android),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mobile-bottom-nav')), findsOneWidget);

      await _setSurface(tester, const Size(1024, 900));
      await tester.pumpWidget(_app(AppRoutes.dashboard));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mobile-bottom-nav')), findsOneWidget);
      expect(find.byKey(const Key('mobile-app-shell')), findsOneWidget);
    },
  );

  testWidgets(
    'mobile navigation follows theme changes and avoids content overlap',
    (tester) async {
      await _setSurface(tester, const Size(390, 844));
      final themeController = ThemeController();
      await tester.pumpWidget(
        _app(
          AppRoutes.dashboard,
          platform: TargetPlatform.android,
          themeController: themeController,
        ),
      );
      addTearDown(themeController.dispose);
      await tester.pumpAndSettle();

      final bar = find.byKey(const Key('mobile-bottom-nav'));
      AnimatedContainer decoration() => tester.widget<AnimatedContainer>(bar);
      expect((decoration().decoration! as BoxDecoration).color, Colors.white);
      expect(
        ((decoration().decoration! as BoxDecoration).border! as Border)
            .top
            .color,
        const Color(0xFFE5E7EB),
      );
      expect(
        tester
            .widget<Icon>(find.byKey(const Key('mobile-nav-icon-home')))
            .color,
        const Color(0xFF246BFD),
      );
      expect(
        tester.getSize(find.byKey(const Key('mobile-nav-home'))).height,
        greaterThanOrEqualTo(48),
      );

      final page = tester.getRect(find.byType(Scaffold).last);
      final navigation = tester.getRect(bar);
      expect(page.bottom, lessThanOrEqualTo(navigation.top));

      themeController.value = ThemeMode.dark;
      await tester.pumpAndSettle();
      expect(Theme.of(tester.element(bar)).brightness, Brightness.dark);
      expect(
        (decoration().decoration! as BoxDecoration).color,
        const Color(0xFF111827),
      );
      expect(
        ((decoration().decoration! as BoxDecoration).border! as Border)
            .top
            .color,
        const Color(0xFF374151),
      );
      expect(
        tester
            .widget<Icon>(find.byKey(const Key('mobile-nav-icon-home')))
            .color,
        const Color(0xFF3B82F6),
      );
      expect(
        tester
            .widget<Icon>(find.byKey(const Key('mobile-nav-icon-voters')))
            .color,
        const Color(0xFF9CA3AF),
      );
      expect(
        (tester
                    .widget<AnimatedContainer>(
                      find.byKey(const Key('mobile-nav-underline-home')),
                    )
                    .decoration!
                as BoxDecoration)
            .color,
        const Color(0xFF3B82F6),
      );
    },
  );

  testWidgets(
    'mobile navigation is omitted from authentication and onboarding',
    (tester) async {
      await _setSurface(tester, const Size(390, 844));

      for (final route in const [
        AppRoutes.login,
        AppRoutes.signUp,
        AppRoutes.otp,
        AppRoutes.authCallback,
        AppRoutes.resetOtp,
        AppRoutes.ready,
        AppRoutes.domain,
        AppRoutes.social,
        AppRoutes.additionalProfile,
        AppRoutes.voterLists,
        AppRoutes.profile,
        AppRoutes.website,
      ]) {
        await tester.pumpWidget(_app(route, platform: TargetPlatform.android));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mobile-bottom-nav')),
          findsNothing,
          reason: route,
        );
        expect(tester.takeException(), isNull, reason: route);
      }

      for (final route in AppRoutes.mobileNavigationRoutes.where(
        (route) => route != AppRoutes.website,
      )) {
        await tester.pumpWidget(_app(route, platform: TargetPlatform.android));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mobile-bottom-nav')),
          findsOneWidget,
          reason: route,
        );
        expect(
          AppRoutes.mobileNavigationIndex(route),
          inInclusiveRange(0, 4),
          reason: route,
        );
      }

      for (final route in AppRoutes.globalFooterRoutes) {
        await tester.pumpWidget(_app(route, platform: TargetPlatform.android));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mobile-bottom-nav')),
          findsOneWidget,
          reason: route,
        );
        expect(tester.takeException(), isNull, reason: route);
      }

      for (final route in const [
        AppRoutes.dashboard,
        AppRoutes.vrmRecords,
        AppRoutes.website,
        AppRoutes.campaignManagement,
        AppRoutes.myPortfolio,
      ]) {
        expect(AppRoutes.showsMobileNavigation(route), isTrue, reason: route);
      }
      expect(AppRoutes.mobileNavigationRoutes, hasLength(5));
    },
  );

  testWidgets('each mobile navigation item opens its existing route', (
    tester,
  ) async {
    await _setSurface(tester, const Size(390, 844));
    final observer = _RouteObserver();
    await tester.pumpWidget(
      _app(
        AppRoutes.dashboard,
        platform: TargetPlatform.android,
        navigatorObserver: observer,
      ),
    );
    await tester.pumpAndSettle();

    for (final destination in const [
      ('voters', AppRoutes.vrmRecords),
      ('website', AppRoutes.website),
      ('campaigns', AppRoutes.campaignManagement),
      ('profile', AppRoutes.myPortfolio),
    ]) {
      await tester.tap(find.byKey(Key('mobile-nav-${destination.$1}')));
      await tester.pumpAndSettle();
      expect(observer.currentRoute, destination.$2);
      expect(find.byKey(const Key('mobile-bottom-nav')), findsOneWidget);
      expect(
        tester
            .getSize(find.byKey(Key('mobile-nav-underline-${destination.$1}')))
            .width,
        closeTo(68, 1),
      );
    }

    await tester.tap(find.byKey(const Key('mobile-nav-home')));
    await tester.pumpAndSettle();
    expect(observer.currentRoute, AppRoutes.dashboard);
    expect(
      tester.getSize(find.byKey(const Key('mobile-nav-underline-home'))).width,
      closeTo(68, 1),
    );
  });

  testWidgets('campaign and profile tabs open their dedicated screens', (
    tester,
  ) async {
    await _setSurface(tester, const Size(390, 844));

    await tester.pumpWidget(
      _app(AppRoutes.campaignManagement, platform: TargetPlatform.android),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CampaignManagementScreen), findsOneWidget);
    expect(find.byType(CampaignTemplatesScreen), findsNothing);

    await tester.pumpWidget(
      _app(AppRoutes.myPortfolio, platform: TargetPlatform.android),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MyPortfolioScreen), findsOneWidget);
    expect(find.byType(BasicProfileScreen), findsNothing);
  });

  test('voter records route is excluded from the shared footer shell', () {
    expect(AppRoutes.showsGlobalFooter(AppRoutes.vrmRecords), isFalse);
    expect(AppRoutes.showsMobileNavigation(AppRoutes.vrmRecords), isTrue);
  });

  testWidgets('footer link hover has no fill and turns the words teal', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 500));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(alignment: Alignment.topCenter, child: GlobalFooter()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final link = find.byKey(const Key('footer-link-website-builder'));
    await tester.ensureVisible(link);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(link));
    await tester.pump(const Duration(milliseconds: 250));

    final box = tester.widget<AnimatedContainer>(
      find.ancestor(of: link, matching: find.byType(AnimatedContainer)).first,
    );
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.color, Colors.transparent);

    final words = tester.widget<AnimatedDefaultTextStyle>(
      find
          .ancestor(
            of: find.text('Website Builder'),
            matching: find.byType(AnimatedDefaultTextStyle),
          )
          .first,
    );
    expect(words.style.color, GlobalFooter.teal);

    final pill = find.byKey(const Key('footer-link-privacy'));
    await gesture.moveTo(tester.getCenter(pill));
    await tester.pump(const Duration(milliseconds: 250));
    final pillBox = tester.widget<AnimatedContainer>(
      find.ancestor(of: pill, matching: find.byType(AnimatedContainer)).first,
    );
    expect((pillBox.decoration! as BoxDecoration).color, GlobalFooter.pill);
    await gesture.removePointer();
  });

  testWidgets('footer links open existing routes and skip the current one', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 900));
    await tester.pumpWidget(_app(AppRoutes.dashboard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.ensureVisible(
      find.byKey(const Key('footer-link-website-builder')),
    );
    await tester.tap(find.byKey(const Key('footer-link-website-builder')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('My Website'), findsWidgets);
    expect(find.byType(GlobalFooter), findsNothing);

    await tester.pumpWidget(_app(AppRoutes.about));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.byKey(const Key('footer-link-features')));
    await tester.tap(find.byKey(const Key('footer-link-features')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('About VoteBanker'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('footer-link-about')));
    await tester.tap(find.byKey(const Key('footer-link-about')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byKey(const Key('global-footer')));
    await tester.pump();
    expect(find.byType(GlobalFooter).hitTestable(), findsOneWidget);
  });

  testWidgets('footer updates across light, dark and mobile themes', (
    tester,
  ) async {
    final controller = ThemeController();

    for (final size in const [Size(1280, 900), Size(390, 1400)]) {
      await _setSurface(tester, size);
      await tester.pumpWidget(_themeApp(controller));
      await tester.pumpAndSettle();

      final lightPainter =
          tester
              .widget<CustomPaint>(find.byKey(const Key('global-footer')))
              .painter!;
      expect(
        tester.widget<Text>(find.text('Quick Links')).style!.color,
        GlobalFooter.navy,
      );
      expect(_footerLinkColor(tester, 'Privacy Policy'), GlobalFooter.navy);
      expect(
        tester.widget<Text>(find.text(GlobalFooter.copyrightLine)).style!.color,
        GlobalFooter.text,
      );
      final legal = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.byKey(const Key('footer-link-privacy')),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      expect((legal.decoration! as BoxDecoration).color, GlobalFooter.pill);

      controller.value = ThemeMode.dark;
      await tester.pumpAndSettle();

      final darkPainter =
          tester
              .widget<CustomPaint>(find.byKey(const Key('global-footer')))
              .painter!;
      expect(darkPainter.shouldRepaint(lightPainter), isTrue);
      expect(
        tester.widget<Text>(find.text('Quick Links')).style!.color,
        AppPalette.dark.text,
      );
      expect(
        tester
            .widget<Text>(
              find.text(
                'Empowering Modern Political Campaigns & Voter Outreach.',
              ),
            )
            .style!
            .color,
        AppPalette.dark.textMuted,
      );
      expect(
        tester.widget<Text>(find.text(GlobalFooter.copyrightLine)).style!.color,
        AppPalette.dark.textMuted,
      );
      expect(_footerLinkColor(tester, 'Privacy Policy'), AppPalette.dark.text);
      final darkLegal = tester.widget<AnimatedContainer>(
        find
            .ancestor(
              of: find.byKey(const Key('footer-link-privacy')),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final darkDecoration = darkLegal.decoration! as BoxDecoration;
      expect(darkDecoration.color, AppPalette.dark.surfaceSecondary);
      expect(
        (darkDecoration.border! as Border).top.color,
        AppPalette.dark.border,
      );
      expect(tester.takeException(), isNull);

      controller.value = ThemeMode.light;
      await tester.pumpAndSettle();
      final restoredPainter =
          tester
              .widget<CustomPaint>(find.byKey(const Key('global-footer')))
              .painter!;
      expect(restoredPainter.shouldRepaint(darkPainter), isTrue);
      expect(
        tester.widget<Text>(find.text('Quick Links')).style!.color,
        GlobalFooter.navy,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('desktop columns stay in order and mobile stacks', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 420));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(alignment: Alignment.topCenter, child: GlobalFooter()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final brand = tester.getTopLeft(
      find.text('Voter Relationship Management Private Limited'),
    );
    final quick = tester.getTopLeft(find.text('Quick Links'));
    final support = tester.getTopLeft(find.text('Support'));
    final company = tester.getTopLeft(find.text('Company'));
    final follow = tester.getTopLeft(find.text('Follow Us'));
    expect(brand.dx, lessThan(quick.dx));
    expect(quick.dx, lessThan(support.dx));
    expect(support.dx, lessThan(company.dx));
    expect(company.dx, lessThan(follow.dx));
    expect((brand.dy - quick.dy).abs(), lessThan(8));

    expect(
      tester
          .getTopLeft(
            find.text(
              '© 2026 Voter Relationship Management Private Limited. All rights reserved.',
            ),
          )
          .dx,
      lessThan(tester.getTopLeft(find.text('Privacy Policy')).dx),
    );
    expect(tester.getSize(find.byKey(const Key('global-footer'))).width, 1280);

    await _setSurface(tester, const Size(390, 1400));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: GlobalFooter())),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.text('Quick Links')).dy,
      greaterThan(
        tester
                .getTopLeft(
                  find.text('Voter Relationship Management Private Limited'),
                )
                .dy +
            20,
      ),
    );
    expect(
      tester.getTopLeft(find.text('Follow Us')).dy,
      greaterThan(tester.getTopLeft(find.text('Company')).dy),
    );
    final footerSize = tester.getSize(find.byKey(const Key('global-footer')));
    expect(footerSize.width, lessThanOrEqualTo(390));

    await _setSurface(tester, const Size(820, 1400));
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: GlobalFooter())),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(find.text('Support')).dy,
      greaterThan(
        tester
            .getTopLeft(
              find.text('Voter Relationship Management Private Limited'),
            )
            .dy,
      ),
    );
  });

  testWidgets('footer stays below the page and spans the parent width', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 800));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: const AppFooterShell(
          child: ColoredBox(key: Key('page-body'), color: Colors.white),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final page = tester.getRect(find.byKey(const Key('page-body')));
    final footer = tester.getRect(find.byKey(const Key('global-footer')));
    expect(page.width, 1280);
    expect(footer.left, 0);
    expect(footer.width, 1280);
    expect(footer.top, greaterThanOrEqualTo(page.bottom - 1));
    expect(find.byType(VerticalDivider), findsNothing);
    expect(find.byType(Divider), findsNothing);
    expect(
      find.text('Voter Relationship Management Private Limited'),
      findsWidgets,
    );
    expect(find.text('Quick Links'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Refund & Shipping Policy'), findsOneWidget);

    await _setSurface(tester, const Size(390, 900));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: const AppFooterShell(
          child: ColoredBox(key: Key('page-body'), color: Colors.white),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('global-footer')), findsNothing);
    expect(find.text('Quick Links'), findsNothing);
    expect(tester.getRect(find.byKey(const Key('page-body'))).width, 390);
  });

  testWidgets('long pages scroll to the full footer below the content', (
    tester,
  ) async {
    await _setSurface(tester, const Size(1280, 600));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.windows),
        home: AppFooterShell(
          child: ListView(
            children: [
              for (var i = 0; i < 30; i++)
                SizedBox(height: 80, child: Text('row $i')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final footer = find.byKey(const Key('global-footer'));
    final before = tester.getRect(footer);
    expect(before.width, 1280);
    expect(before.top, greaterThan(1500));
    expect(before.height, greaterThan(120));

    await tester.ensureVisible(footer);
    await tester.pumpAndSettle();
    final after = tester.getRect(footer);
    expect(after.top, lessThan(before.top));
    expect(after.height, before.height);
    expect(after.width, 1280);
    expect(
      find.text('Voter Relationship Management Private Limited'),
      findsWidgets,
    );
    expect(find.text('Quick Links'), findsOneWidget);
    expect(find.text('Follow Us'), findsOneWidget);
    expect(
      find.text(
        '© 2026 Voter Relationship Management Private Limited. All rights reserved.',
      ),
      findsOneWidget,
    );
  });
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _app(
  String route, {
  TargetPlatform platform = TargetPlatform.windows,
  ThemeController? themeController,
  NavigatorObserver? navigatorObserver,
}) {
  final controller = themeController ?? ThemeController();
  final routeObserver =
      navigatorObserver is _RouteObserver
          ? navigatorObserver
          : _RouteObserver();
  final navigatorKey = GlobalKey<NavigatorState>();
  return ThemeScope(
    controller: controller,
    child: OnboardingScope(
      controller: OnboardingController(),
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: controller,
        builder:
            (context, themeMode, _) => MaterialApp(
              key: ValueKey(route),
              navigatorKey: navigatorKey,
              navigatorObservers: [
                routeObserver,
                if (navigatorObserver != null &&
                    !identical(navigatorObserver, routeObserver))
                  navigatorObserver,
              ],
              theme: AppTheme.light().copyWith(platform: platform),
              darkTheme: AppTheme.dark().copyWith(platform: platform),
              themeMode: themeMode,
              builder:
                  (context, child) => ValueListenableBuilder<String?>(
                    valueListenable: routeObserver.routeName,
                    builder:
                        (context, routeName, _) => ValueListenableBuilder<bool>(
                          valueListenable:
                              routeObserver.mobileNavigationEnabled,
                          builder:
                              (
                                context,
                                mobileNavigationEnabled,
                                _,
                              ) => GlobalFooter.mainAppLayout(
                                context,
                                child ?? const SizedBox.shrink(),
                                routeName: routeName,
                                mobileNavigationEnabled:
                                    mobileNavigationEnabled,
                                onNavigate: (destination) {
                                  final navigatorContext =
                                      navigatorKey.currentState?.context;
                                  if (navigatorContext == null) {
                                    throw StateError(
                                      'The test app navigator is not available.',
                                    );
                                  }
                                  AppRouter.open(
                                    navigatorContext,
                                    destination,
                                    arguments:
                                        destination == AppRoutes.website
                                            ? AppRoutes.mobileNavigationArgument
                                            : null,
                                  );
                                },
                              ),
                        ),
                  ),
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              initialRoute: route,
              onGenerateRoute: AppRouter.onGenerateRoute,
              onGenerateInitialRoutes: (initialRoute) {
                return [
                  AppRouter.onGenerateRoute(RouteSettings(name: initialRoute)),
                ];
              },
            ),
      ),
    ),
  );
}

class _RouteObserver extends NavigatorObserver {
  String? currentRoute;
  final routeName = ValueNotifier<String?>(null);
  final mobileNavigationEnabled = ValueNotifier<bool>(false);

  void _update(Route<dynamic>? route) {
    final name = route?.settings.name;
    if (name == null) return;
    currentRoute = AppRouter.normalizeRouteName(name);
    final normalized = currentRoute;
    final showNavigation =
        AppRoutes.showsMobileNavigation(normalized) &&
        (normalized != AppRoutes.website ||
            route!.settings.arguments == AppRoutes.mobileNavigationArgument);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      routeName.value = normalized;
      mobileNavigationEnabled.value = showNavigation;
    });
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _update(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _update(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _update(newRoute);
  }
}

Widget _themeApp(ThemeController controller) {
  return ThemeScope(
    controller: controller,
    child: ValueListenableBuilder<ThemeMode>(
      valueListenable: controller,
      builder: (context, mode, _) {
        return MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: mode,
          home: const Scaffold(
            body: Align(alignment: Alignment.topCenter, child: GlobalFooter()),
          ),
        );
      },
    ),
  );
}

Color? _footerLinkColor(WidgetTester tester, String label) {
  return tester
      .widget<AnimatedDefaultTextStyle>(
        find
            .ancestor(
              of: find.text(label),
              matching: find.byType(AnimatedDefaultTextStyle),
            )
            .first,
      )
      .style
      .color;
}
