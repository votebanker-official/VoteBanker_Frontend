import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:votebanker/app/app.dart';
import 'package:votebanker/features/onboarding/data/location_catalog.dart';
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

    expect(find.text('Assembly Constituency'), findsOneWidget);
    expect(find.text('Organization / Party / Affiliation'), findsOneWidget);
    expect(find.text('Country'), findsOneWidget);
    expect(find.text('State'), findsOneWidget);
    expect(find.text('District'), findsOneWidget);
    expect(find.text('Contact Number'), findsOneWidget);
    expect(find.text('Part No'), findsOneWidget);
    expect(find.text('Part Name'), findsOneWidget);
    expect(find.text('Select Language'), findsOneWidget);
    expect(find.text('Designation'), findsNothing);
    expect(find.text('State / Region'), findsNothing);
    expect(find.text('Constituency / Area'), findsNothing);
    expect(find.text('Public Contact Details'), findsNothing);
    expect(find.text('Preferred Language'), findsNothing);

    expect(_dropdown(tester, 'profileLanguage').initialValue, 'en');
    expect(_dropdown(tester, 'profileState').onChanged, isNull);
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
    expect(find.text('Afghanistan'), findsWidgets);
    expect(find.text('Bangalore Urban'), findsNothing);
    await tester.tap(find.text('Afghanistan').last);
    await tester.pumpAndSettle();

    _dropdown(tester, 'profileCountry').onChanged!('India');
    await tester.pumpAndSettle();
    expect(_dropdown(tester, 'profileCountry').initialValue, 'India');
    expect(_dropdown(tester, 'profileState').onChanged, isNotNull);
    expect(_dropdown(tester, 'profileDistrict').onChanged, isNull);

    await _openDropdown(tester, 'profileState');
    expect(find.text('Andhra Pradesh'), findsWidgets);
    expect(find.text('Bangalore Urban'), findsNothing);
    await _chooseMenuItem(tester, 'Karnataka');
    expect(_dropdown(tester, 'profileState').initialValue, 'Karnataka');

    await _openDropdown(tester, 'profileDistrict');
    expect(find.text('Pune'), findsNothing);
    await _chooseMenuItem(tester, 'Bangalore Urban');
    expect(_dropdown(tester, 'profileDistrict').initialValue, 'Bangalore Urban');

    _dropdown(tester, 'profileCountry').onChanged!('United States');
    await tester.pumpAndSettle();
    expect(_dropdown(tester, 'profileState').initialValue, isNull);
    expect(_dropdown(tester, 'profileDistrict').initialValue, isNull);
    expect(_dropdown(tester, 'profileDistrict').onChanged, isNull);

    await _openDropdown(tester, 'profileState');
    await _chooseMenuItem(tester, 'California');
    expect(_dropdown(tester, 'profileState').initialValue, 'California');

    await _openDropdown(tester, 'profileDistrict');
    await _chooseMenuItem(tester, 'Los Angeles County');
    expect(_dropdown(tester, 'profileDistrict').initialValue, 'Los Angeles County');

    await _openDropdown(tester, 'profileState');
    await _chooseMenuItem(tester, 'Texas');
    expect(_dropdown(tester, 'profileState').initialValue, 'Texas');
    expect(_dropdown(tester, 'profileDistrict').initialValue, isNull);
    expect(_dropdown(tester, 'profileDistrict').onChanged, isNotNull);
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
    expect(find.text('Basic Profile'), findsOneWidget);
    expect(find.text('Domain Name Search'), findsNothing);

    await _enter(tester, 'profileContact', '9876543210');
    await _tapLabel(tester, 'Save & Continue');
    expect(find.text('Domain Name Search'), findsOneWidget);

    await _tapLabel(tester, 'Back');
    final draft = OnboardingScope.of(
      tester.element(find.text('Basic Profile')),
    ).draft;
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
    expect(_dropdown(tester, 'profileLanguage').initialValue, 'hi');
    expect(controller.draft.constituency, isEmpty);
    expect(controller.draft.partNo, '15');
    expect(controller.draft.partName, 'Central');
    expect(controller.draft.preferredLanguage, 'hi');
  });
}

Future<void> _openProfile(WidgetTester tester) async {
  await _setSurface(tester, const Size(1280, 900));
  await tester.pumpWidget(const VoteBankerApp());
  await tester.pumpAndSettle();
  await _tapLabel(tester, 'Skip for now');
  expect(find.text('Basic Profile'), findsOneWidget);
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

Future<void> _tapLabel(WidgetTester tester, String text) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump();
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
