import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:votebanker/app/app.dart';
import 'package:votebanker/app/localization/translations/kn.dart';
import 'package:votebanker/features/onboarding/data/location_catalog.dart';
import 'package:votebanker/features/onboarding/data/political_party.dart';
import 'package:votebanker/features/onboarding/widgets/party_symbol.dart';
import 'package:votebanker/features/onboarding/state/onboarding_controller.dart';

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    TestWidgetsFlutterBinding.ensureInitialized();
    await LocationCatalog.load();
  });

  testWidgets('profile labels, language default, and locked location fields', (
    tester,
  ) async {
    await _openProfile(tester);

    expect(find.text('Leader Profile'), findsOneWidget);
    expect(
      find.text('Tell us a little about your leadership and journey.'),
      findsOneWidget,
    );
    expect(find.text('Every field is optional.'), findsNothing);
    expect(find.text('Leader Name *'), findsOneWidget);
    expect(find.text('Assembly Constituency *'), findsOneWidget);
    expect(find.text('Booth Number *'), findsOneWidget);
    expect(find.text('Booth Name *'), findsOneWidget);
    expect(find.text('Party *'), findsOneWidget);
    expect(find.text('Designation *'), findsOneWidget);
    expect(find.text('Country *'), findsOneWidget);
    expect(find.text('State *'), findsOneWidget);
    expect(find.text('District *'), findsOneWidget);
    expect(find.text('Contact Number *'), findsOneWidget);
    expect(find.text('Part No'), findsNothing);
    expect(find.text('Part Name'), findsNothing);
    expect(find.text('Select Language'), findsNothing);
    expect(find.text('English'), findsWidgets);
    expect(find.text('State / Region'), findsNothing);
    expect(find.text('Constituency / Area'), findsNothing);
    expect(find.text('Public Contact Details'), findsNothing);
    expect(find.text('Preferred Language'), findsNothing);

    expect(_dropdown(tester, 'profileCountry').initialValue, 'India');
    expect(_dropdown(tester, 'profileState').onChanged, isNotNull);
    expect(_dropdown(tester, 'profileDistrict').onChanged, isNull);

    final contact = _textField(tester, 'profileContact');
    expect(contact.keyboardType, TextInputType.phone);
  });

  testWidgets('country, state, and district dropdowns stay dependent', (
    tester,
  ) async {
    await _openProfile(tester);

    final country = find.byKey(const ValueKey('profileCountry'));
    await tester.ensureVisible(country);
    await tester.pumpAndSettle();
    await tester.tap(country);
    await tester.pumpAndSettle();
    expect(find.text('India'), findsWidgets);
    expect(find.text('Afghanistan'), findsNothing);
    expect(find.text('United States'), findsNothing);
    expect(find.text('Bengaluru Urban'), findsNothing);
    await tester.tap(find.text('India').last);
    await tester.pumpAndSettle();

    _dropdown(tester, 'profileCountry').onChanged!('India');
    await tester.pumpAndSettle();
    expect(_dropdown(tester, 'profileCountry').initialValue, 'India');
    expect(_dropdown(tester, 'profileState').onChanged, isNotNull);
    expect(_dropdown(tester, 'profileDistrict').onChanged, isNull);

    await _openDropdown(tester, 'profileState');
    expect(find.text('Andhra Pradesh'), findsWidgets);
    expect(find.text('Bengaluru Urban'), findsNothing);
    await _chooseMenuItem(tester, 'Karnataka');
    expect(_dropdown(tester, 'profileState').initialValue, 'Karnataka');

    await _openDropdown(tester, 'profileDistrict');
    expect(find.text('Pune'), findsNothing);
    await _chooseMenuItem(tester, 'Bengaluru Urban');
    expect(
      _dropdown(tester, 'profileDistrict').initialValue,
      'Bengaluru Urban',
    );

    await _openDropdown(tester, 'profileState');
    await _chooseMenuItem(tester, 'Maharashtra');
    expect(_dropdown(tester, 'profileState').initialValue, 'Maharashtra');
    expect(_dropdown(tester, 'profileDistrict').initialValue, isNull);
    expect(_dropdown(tester, 'profileDistrict').onChanged, isNotNull);

    await _openDropdown(tester, 'profileDistrict');
    expect(find.text('Bengaluru Urban'), findsNothing);
    await _chooseMenuItem(tester, 'Pune');
    expect(_dropdown(tester, 'profileDistrict').initialValue, 'Pune');
  });

  testWidgets('contact validation and part fields stay in the profile draft', (
    tester,
  ) async {
    await _openProfile(tester);

    await _enter(tester, 'profileContact', '12345');
    await _enter(tester, 'profilePartNo', '  12/A ');
    await _enter(tester, 'profilePartName', 'Booth 4');
    await _tapLabel(tester, 'Save & Continue');

    expect(find.text('Enter a valid contact number.'), findsOneWidget);
    expect(find.text('Leader Profile'), findsOneWidget);
    expect(find.text('Portfolio Website'), findsNothing);

    await _enter(tester, 'profileContact', '9876543210');
    await _tapLabel(tester, 'Save & Continue');
    expect(find.text('Portfolio Website'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    final draft =
        OnboardingScope.of(tester.element(find.text('Leader Profile'))).draft;
    expect(draft.publicContact, '9876543210');
    expect(draft.partNo, '12/A');
    expect(draft.partName, 'Booth 4');
    expect(draft.preferredLanguage, 'en');
  });

  testWidgets('saved location and language are restored', (tester) async {
    final controller = OnboardingController();
    addTearDown(controller.dispose);
    controller.draft
      ..country = 'India'
      ..stateRegion = 'Karnataka'
      ..constituency = 'Pune'
      ..preferredLanguage = 'hi'
      ..partNo = '15'
      ..partName = 'Central';

    await _setSurface(tester, const Size(1280, 900));
    await tester.pumpWidget(VoteBankerApp(controller: controller));
    await tester.pumpAndSettle();
    await _tapLabel(tester, 'Skip for now');

    expect(_dropdown(tester, 'profileCountry').initialValue, 'India');
    expect(_dropdown(tester, 'profileState').initialValue, 'Karnataka');
    expect(_dropdown(tester, 'profileDistrict').initialValue, isNull);
    expect(find.text('हिन्दी'), findsOneWidget);
    expect(controller.draft.constituency, isEmpty);
    expect(controller.draft.partNo, '15');
    expect(controller.draft.partName, 'Central');
    expect(controller.draft.preferredLanguage, 'hi');
  });

  testWidgets('kannada, english, and theme update the leader profile', (
    tester,
  ) async {
    await _openProfile(tester);
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('profileLeaderName')),
        matching: find.byType(TextField),
      ),
      'John',
    );

    await _chooseLanguage(tester, 'ಕನ್ನಡ');
    expect(find.text(knTranslations['basicProfile']!), findsOneWidget);
    expect(find.text(knTranslations['takePhoto']!), findsOneWidget);
    expect(find.text(knTranslations['locationSection']!), findsOneWidget);
    expect(find.text(knTranslations['contactSection']!), findsOneWidget);
    expect(find.text('Leader Profile'), findsNothing);
    expect(find.text('Take Photo'), findsNothing);
    expect(find.text('1 of 4'), findsNothing);
    expect(find.text('John'), findsOneWidget);

    await _chooseLanguage(tester, 'English');
    expect(find.text('Leader Profile'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('John'), findsOneWidget);

    await _tapLabel(tester, 'Take Photo');
    expect(find.text('Select from album'), findsOneWidget);
    expect(find.text('Take selfie'), findsOneWidget);
    Navigator.of(tester.element(find.text('Select from album'))).pop();
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Leader Profile'));
    expect(Theme.of(context).brightness, Brightness.light);

    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Leader Profile'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Leader Profile'))).brightness,
      Brightness.light,
    );
  });

  testWidgets('party dropdown shows grouped symbols and keeps the selection', (
    tester,
  ) async {
    await _openProfile(tester);
    await _openDropdown(tester, 'profileParty');

    expect(find.text('National Parties'), findsOneWidget);
    expect(find.text('Regional & State Parties'), findsOneWidget);
    expect(find.byType(Scrollable), findsWidgets);

    final header = tester.widget<DropdownMenuItem<String>>(
      find.ancestor(
        of: find.text('National Parties'),
        matching: find.byType(DropdownMenuItem<String>),
      ),
    );
    expect(header.enabled, isFalse);

    for (final party in PartyOption.all) {
      final name = find.text(party.name);
      await tester.scrollUntilVisible(
        name,
        80,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      final row = find.ancestor(of: name.last, matching: find.byType(Row));
      final symbol = find.descendant(
        of: row.first,
        matching: find.byType(PartySymbol),
      );
      expect(symbol, findsOneWidget);
      final symbolBox = tester.getRect(symbol);
      final nameBox = tester.getRect(name.last);
      expect(symbolBox.center.dx, lessThan(nameBox.left));
      expect((symbolBox.center.dy - nameBox.center.dy).abs(), lessThan(12));
      expect(symbolBox.width, lessThanOrEqualTo(nameBox.left));
    }

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    _dropdown(tester, 'profileParty').onChanged!('Bharatiya Janata Party');
    await tester.pumpAndSettle();
    expect(
      _dropdown(tester, 'profileParty').initialValue,
      'Bharatiya Janata Party',
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('profileParty')),
        matching: find.byType(PartySymbol),
      ),
      findsOneWidget,
    );
    expect(
      OnboardingScope.of(
        tester.element(find.text('Leader Profile')),
      ).draft.party,
      'Bharatiya Janata Party',
    );

    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpAndSettle();
    await _openDropdown(tester, 'profileParty');
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openProfile(WidgetTester tester) async {
  await _setSurface(tester, const Size(1280, 900));
  await tester.pumpWidget(const VoteBankerApp());
  await tester.pumpAndSettle();
  await _tapLabel(tester, 'Skip for now');
  expect(find.text('Leader Profile'), findsOneWidget);
}

DropdownButtonFormField<String> _dropdown(WidgetTester tester, String key) {
  return tester.widget<DropdownButtonFormField<String>>(
    find.byKey(ValueKey(key)),
  );
}

Future<void> _openDropdown(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _chooseMenuItem(WidgetTester tester, String label) async {
  final item = find.text(label);
  await tester.scrollUntilVisible(
    item,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(item.last);
  await tester.pumpAndSettle();
}

TextField _textField(WidgetTester tester, String key) {
  return tester.widget<TextField>(
    find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(TextField),
    ),
  );
}

Future<void> _enter(WidgetTester tester, String key, String value) async {
  final finder = find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
}

Future<void> _setSurface(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _chooseLanguage(WidgetTester tester, String nativeName) async {
  await tester.tap(find.byIcon(Icons.language));
  await tester.pumpAndSettle();
  final item = find.textContaining(nativeName);
  await tester.scrollUntilVisible(
    item,
    120,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
  await tester.tap(item.last);
  await tester.pumpAndSettle();
}

Future<void> _tapLabel(WidgetTester tester, String text) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
