import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:votebanker/app/app.dart';
import 'package:votebanker/app/localization/translations/hi.dart';
import 'package:votebanker/app/localization/translations/kn.dart';
import 'package:votebanker/features/onboarding/data/assembly_constituency.dart';
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
    expect(_stateEnabled(tester), isTrue);
    expect(_districtEnabled(tester), isFalse);

    final contact = _textField(tester, 'profileContact');
    expect(contact.keyboardType, TextInputType.phone);
    expect(contact.decoration?.hintText, 'Enter 10-digit mobile number');
    expect(find.text('+91'), findsWidgets);
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
    expect(_stateEnabled(tester), isTrue);
    expect(_districtEnabled(tester), isFalse);

    await _openDropdown(tester, 'profileState');
    expect(find.text('Andhra Pradesh'), findsWidgets);
    expect(find.text('Bengaluru Urban'), findsNothing);
    await _chooseMenuItem(tester, 'Karnataka');
    _expectState(tester, 'Karnataka');

    await _openDropdown(tester, 'profileDistrict');
    expect(find.text('Pune'), findsNothing);
    await _chooseMenuItem(tester, 'Bengaluru Urban');
    _expectDistrict(tester, 'Bengaluru Urban');

    final draft =
        OnboardingScope.of(tester.element(find.text('Leader Profile'))).draft;
    draft.assemblyConstituency = 'Shivajinagar';
    await _enter(tester, 'profilePartNo', '12');
    await _enter(tester, 'profilePartName', 'Central Booth');
    await _openDropdown(tester, 'profileState');
    await _chooseMenuItem(tester, 'Maharashtra');
    _expectState(tester, 'Maharashtra');
    expect(draft.assemblyConstituency, isEmpty);
    _expectAssembly(tester, null);
    expect(_textField(tester, 'profilePartNo').controller!.text, '12');
    expect(
      _textField(tester, 'profilePartName').controller!.text,
      'Central Booth',
    );
    _expectDistrict(tester, null);
    expect(_districtEnabled(tester), isTrue);

    await _openDropdown(tester, 'profileDistrict');
    expect(find.text('Bengaluru Urban'), findsNothing);
    await _chooseMenuItem(tester, 'Pune');
    _expectDistrict(tester, 'Pune');
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
    expect(find.text('Portfolio Template'), findsNothing);

    await _enter(tester, 'profileContact', '9876543210');
    await _tapLabel(tester, 'Save & Continue');
    expect(find.text('Portfolio Template'), findsOneWidget);

    final draft = OnboardingScope.of(
      tester.element(find.text('Portfolio Template')),
    ).draft;
    expect(draft.publicContact, '9876543210');
    expect(draft.partNo, '12/A');
    expect(draft.partName, 'Booth 4');
    expect(draft.preferredLanguage, 'en');
  });

  testWidgets(
    'Indian contact number field enforces +91 prefix, 10-digit capping, starting digit validation, and paste formatting',
    (tester) async {
      await _openProfile(tester);

      // Verify UI components
      final contactField = _textField(tester, 'profileContact');
      expect(contactField.decoration?.hintText, 'Enter 10-digit mobile number');
      expect(contactField.keyboardType, TextInputType.phone);
      expect(find.text('+91'), findsWidgets);
      expect(find.byIcon(Icons.phone_outlined), findsWidgets);

      // Formatting: non-numeric characters are stripped
      await _enter(tester, 'profileContact', '98ab-76 543');
      expect(_textField(tester, 'profileContact').controller!.text, '9876543');

      // Formatting: typing or entering > 10 digits is capped to 10
      await _enter(tester, 'profileContact', '9876543210999');
      expect(_textField(tester, 'profileContact').controller!.text, '9876543210');

      // Formatting: entering with +91 strips prefix to 10 digits
      await _enter(tester, 'profileContact', '+919876543210');
      expect(_textField(tester, 'profileContact').controller!.text, '9876543210');

      // Formatting: entering with trunk 0 strips prefix to 10 digits
      await _enter(tester, 'profileContact', '09876543210');
      expect(_textField(tester, 'profileContact').controller!.text, '9876543210');

      // Validation: empty contact number rejected on submit
      await _enter(tester, 'profileContact', '');
      await _tapLabel(tester, 'Save & Continue');
      expect(find.text('Enter a valid contact number.'), findsOneWidget);

      // Validation: fewer than 10 digits rejected on submit
      await _enter(tester, 'profileContact', '98765');
      await _tapLabel(tester, 'Save & Continue');
      expect(find.text('Enter a valid contact number.'), findsOneWidget);

      // Validation: 10 digits starting with invalid digit (0–5) rejected on submit
      await _enter(tester, 'profileContact', '5876543210');
      await _tapLabel(tester, 'Save & Continue');
      expect(find.text('Enter a valid contact number.'), findsOneWidget);

      // Validation: 10 digits starting with 6–9 accepted on submit
      await _enter(tester, 'profileContact', '6876543210');
      await _tapLabel(tester, 'Save & Continue');
      expect(find.text('Portfolio Template'), findsOneWidget);
    },
  );

  testWidgets('saved location and language are restored', (tester) async {
    final controller = OnboardingController();
    addTearDown(controller.dispose);
    controller.draft
      ..country = 'India'
      ..stateRegion = 'Karnataka'
      ..constituency = 'Pune'
      ..preferredLanguage = 'hi'
      ..partNo = '15'
      ..partName = 'Central'
      ..contactNumber = '+91 98765 43210';

    await _setSurface(tester, const Size(1280, 900));
    await tester.pumpWidget(VoteBankerApp(controller: controller));
    await tester.pumpAndSettle();
    // Preferred language is applied to MaterialApp on startup.
    await _tapLabel(tester, hiTranslations['skipForNow']!);

    expect(_dropdown(tester, 'profileCountry').initialValue, 'India');
    _expectState(tester, 'Karnataka');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('profileDistrict')),
        matching: find.text(hiTranslations['selectDistrict']!),
      ),
      findsOneWidget,
    );
    expect(find.text('हिन्दी'), findsOneWidget);
    expect(_textField(tester, 'profileContact').controller!.text, '9876543210');
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
    expect(find.byKey(const ValueKey('partySearch')), findsNothing);

    await _openDropdown(tester, 'profileParty');
    expect(find.byKey(const ValueKey('partySearch')), findsOneWidget);
    expect(find.text('National Parties'), findsOneWidget);
    expect(find.text('Regional & State Parties'), findsOneWidget);
    expect(find.byType(Scrollable), findsWidgets);

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

    // Search partial case-insensitive text
    await tester.enterText(find.byKey(const ValueKey('partySearch')), 'janata');
    await tester.pump();
    expect(find.text('Bharatiya Janata Party'), findsOneWidget);
    expect(find.text('Janata Dal (United)'), findsOneWidget);
    expect(find.text('Biju Janata Dal'), findsOneWidget);
    expect(find.text('Indian National Congress'), findsNothing);

    // Search by abbreviation
    await tester.enterText(find.byKey(const ValueKey('partySearch')), 'TMC');
    await tester.pump();
    expect(find.text('All India Trinamool Congress'), findsOneWidget);
    expect(find.text('Bharatiya Janata Party'), findsNothing);

    // Clear search
    expect(find.byKey(const ValueKey('clearPartySearch')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('clearPartySearch')));
    await tester.pump();
    expect(find.text('Bharatiya Janata Party'), findsOneWidget);
    expect(find.text('Indian National Congress'), findsOneWidget);

    // No results found
    await tester.enterText(
      find.byKey(const ValueKey('partySearch')),
      'NonExistentParty123',
    );
    await tester.pump();
    expect(find.text('No results found'), findsOneWidget);
    expect(find.byKey(const ValueKey('noPartiesFound')), findsOneWidget);
    expect(find.text('Bharatiya Janata Party'), findsNothing);

    // Clear and select
    await tester.tap(find.byKey(const ValueKey('clearPartySearch')));
    await tester.pump();
    await _chooseMenuItem(tester, 'Bharatiya Janata Party');
    expect(find.byKey(const ValueKey('partySearch')), findsNothing);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('profileParty')),
        matching: find.byType(PartySymbol),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('profileParty')),
        matching: find.text('Bharatiya Janata Party'),
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
    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
  });

  testWidgets(
    'designation dropdown supports searching, partial match, clearing, and selecting',
    (tester) async {
      await _openProfile(tester);
      expect(find.byKey(const ValueKey('designationSearch')), findsNothing);

      await _openDropdown(tester, 'profileDesignation');
      expect(find.byKey(const ValueKey('designationSearch')), findsOneWidget);
      expect(find.text('MLA'), findsOneWidget);
      expect(find.text('MP'), findsOneWidget);
      expect(find.text('Minister'), findsOneWidget);
      expect(find.text('Chief Minister'), findsOneWidget);

      // Search partial text (case-insensitive)
      await tester.enterText(
        find.byKey(const ValueKey('designationSearch')),
        'min',
      );
      await tester.pump();
      expect(find.text('Minister'), findsOneWidget);
      expect(find.text('Chief Minister'), findsOneWidget);
      expect(find.text('MLA'), findsNothing);
      expect(find.text('MP'), findsNothing);

      // Clear search
      expect(
        find.byKey(const ValueKey('clearDesignationSearch')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('clearDesignationSearch')));
      await tester.pump();
      expect(find.text('MLA'), findsOneWidget);
      expect(find.text('Councillor'), findsOneWidget);

      // No results found
      await tester.enterText(
        find.byKey(const ValueKey('designationSearch')),
        'NonExistentDesignation',
      );
      await tester.pump();
      expect(find.text('No results found'), findsOneWidget);
      expect(find.byKey(const ValueKey('noDesignationsFound')), findsOneWidget);
      expect(find.text('MLA'), findsNothing);

      // Clear and select
      await tester.tap(find.byKey(const ValueKey('clearDesignationSearch')));
      await tester.pump();
      await _chooseMenuItem(tester, 'Councillor');
      expect(find.byKey(const ValueKey('designationSearch')), findsNothing);

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('profileDesignation')),
          matching: find.text('Councillor'),
        ),
        findsOneWidget,
      );
      expect(
        OnboardingScope.of(
          tester.element(find.text('Leader Profile')),
        ).draft.designation,
        'Councillor',
      );

      await tester.binding.setSurfaceSize(const Size(390, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpAndSettle();
      await _openDropdown(tester, 'profileDesignation');
      expect(tester.takeException(), isNull);
      await tester.tapAt(const Offset(8, 8));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('state menu prioritizes states and filters by prefix', (
    tester,
  ) async {
    await _openProfile(tester);
    expect(find.byKey(const ValueKey('stateSearch')), findsNothing);

    await _openDropdown(tester, 'profileState');
    expect(find.byKey(const ValueKey('stateSearch')), findsOneWidget);
    expect(_menuNames(tester).take(4).toList(), [
      'Karnataka',
      'Maharashtra',
      'Tamil Nadu',
      'Kerala',
    ]);
    expect(_menuNames(tester), hasLength(36));
    expect(_menuNames(tester).where((name) => name == 'Karnataka'), [
      'Karnataka',
    ]);
    expect(_menuNames(tester), contains('Ladakh'));

    await tester.enterText(find.byKey(const ValueKey('stateSearch')), 'K');
    await tester.pump();
    expect(_menuNames(tester), ['Karnataka', 'Kerala']);

    await tester.enterText(find.byKey(const ValueKey('stateSearch')), 'ka');
    await tester.pump();
    expect(_menuNames(tester), ['Karnataka']);

    await tester.enterText(find.byKey(const ValueKey('stateSearch')), 'KA');
    await tester.pump();
    expect(_menuNames(tester), ['Karnataka']);

    await tester.enterText(find.byKey(const ValueKey('stateSearch')), 'M');
    await tester.pump();
    expect(_menuNames(tester), [
      'Maharashtra',
      'Madhya Pradesh',
      'Manipur',
      'Meghalaya',
      'Mizoram',
    ]);

    await tester.enterText(
      find.byKey(const ValueKey('stateSearch')),
      'pradesh',
    );
    await tester.pump();
    expect(find.text('No states found'), findsOneWidget);
    expect(find.byKey(const ValueKey('stateMenuList')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('clearStateSearch')));
    await tester.pump();
    expect(_menuNames(tester), hasLength(36));
    expect(_menuNames(tester).take(4).toList(), [
      'Karnataka',
      'Maharashtra',
      'Tamil Nadu',
      'Kerala',
    ]);

    await tester.enterText(find.byKey(const ValueKey('stateSearch')), 'k');
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('stateMenuList')),
        matching: find.text('Kerala'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stateSearch')), findsNothing);
    _expectState(tester, 'Kerala');

    await _openDropdown(tester, 'profileDistrict');
    expect(find.text('Pune'), findsNothing);
    await _chooseMenuItem(tester, 'Thiruvananthapuram');
    _expectDistrict(tester, 'Thiruvananthapuram');

    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpAndSettle();
    await _openDropdown(tester, 'profileState');
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('stateSearch')), findsOneWidget);
  });

  testWidgets('district menu filters the selected state by prefix', (
    tester,
  ) async {
    await _openProfile(tester);
    expect(find.byKey(const ValueKey('districtSearch')), findsNothing);
    expect(_districtEnabled(tester), isFalse);

    await _openDropdown(tester, 'profileState');
    await _chooseMenuItem(tester, 'Karnataka');
    final draft =
        OnboardingScope.of(tester.element(find.text('Leader Profile'))).draft;
    draft
      ..assemblyConstituency = '1 - Ichchapuram'
      ..assemblyConstituencyId = 1;
    await _enter(tester, 'profilePartNo', '12');
    await _enter(tester, 'profilePartName', 'Central Booth');

    await _openDropdown(tester, 'profileDistrict');
    expect(find.byKey(const ValueKey('districtSearch')), findsOneWidget);
    expect(find.byKey(const ValueKey('stateSearch')), findsNothing);
    final karnataka = _menuNames(tester, 'districtMenuList');
    expect(
      karnataka,
      containsAll([
        'Dharwad',
        'Dakshina Kannada',
        'Bengaluru Urban',
        'Bengaluru Rural',
      ]),
    );
    expect(karnataka, isNot(contains('Pune')));
    expect(karnataka.toSet(), hasLength(karnataka.length));

    await tester.enterText(find.byKey(const ValueKey('districtSearch')), 'D');
    await tester.pump();
    expect(_menuNames(tester, 'districtMenuList'), [
      'Dakshina Kannada',
      'Davanagere',
      'Dharwad',
    ]);

    await tester.enterText(find.byKey(const ValueKey('districtSearch')), 'd');
    await tester.pump();
    expect(_menuNames(tester, 'districtMenuList'), [
      'Dakshina Kannada',
      'Davanagere',
      'Dharwad',
    ]);

    await tester.enterText(find.byKey(const ValueKey('districtSearch')), 'B');
    await tester.pump();
    expect(_menuNames(tester, 'districtMenuList'), [
      'Bagalkote',
      'Ballari',
      'Belagavi',
      'Bengaluru Rural',
      'Bengaluru South',
      'Bengaluru Urban',
      'Bidar',
    ]);

    await tester.enterText(
      find.byKey(const ValueKey('districtSearch')),
      'urban',
    );
    await tester.pump();
    expect(find.text('No districts found'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('districtSearch')),
      'kannada',
    );
    await tester.pump();
    expect(find.text('No districts found'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('clearDistrictSearch')));
    await tester.pump();
    expect(_menuNames(tester, 'districtMenuList'), karnataka);

    await tester.enterText(find.byKey(const ValueKey('districtSearch')), 'Dh');
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('districtMenuList')),
        matching: find.text('Dharwad'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('districtSearch')), findsNothing);
    _expectDistrict(tester, 'Dharwad');
    expect(draft.assemblyConstituency, isEmpty);
    expect(draft.assemblyConstituencyId, isNull);
    _expectAssembly(tester, null);
    expect(_textField(tester, 'profilePartNo').controller!.text, '12');
    expect(
      _textField(tester, 'profilePartName').controller!.text,
      'Central Booth',
    );
    expect(
      OnboardingScope.of(
        tester.element(find.text('Leader Profile')),
      ).draft.constituency,
      'Dharwad',
    );

    await tester.binding.setSurfaceSize(const Size(390, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpAndSettle();
    await _openDropdown(tester, 'profileDistrict');
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('districtSearch')), findsOneWidget);
  });

  testWidgets('saved district for the selected state is restored', (
    tester,
  ) async {
    final controller = OnboardingController();
    addTearDown(controller.dispose);
    controller.draft
      ..country = 'India'
      ..stateRegion = 'Karnataka'
      ..constituency = 'Dharwad'
      ..boothNumber = '15'
      ..boothName = 'Central';

    await _setSurface(tester, const Size(1280, 900));
    await tester.pumpWidget(VoteBankerApp(controller: controller));
    await tester.pumpAndSettle();
    await _tapLabel(tester, 'Skip for now');

    _expectState(tester, 'Karnataka');
    _expectDistrict(tester, 'Dharwad');
    expect(controller.draft.constituency, 'Dharwad');
    expect(controller.draft.boothNumber, '15');
    expect(controller.draft.boothName, 'Central');
  });

  testWidgets(
    'assembly menu searches number or name for the selected district',
    (tester) async {
      final previous = AssemblyConstituencies.load;
      addTearDown(() => AssemblyConstituencies.load = previous);
      const items = [
        AssemblyConstituency(
          id: 1,
          number: 1,
          name: 'Ichchapuram',
          stateId: 28,
          districtId: 519,
        ),
        AssemblyConstituency(
          id: 2,
          number: 2,
          name: 'Palasa',
          stateId: 28,
          districtId: 519,
        ),
        AssemblyConstituency(
          id: 10,
          number: 10,
          name: 'Tekkali',
          stateId: 28,
          districtId: 519,
        ),
      ];
      AssemblyConstituencies.load = ({
        required String state,
        required String district,
      }) async {
        expect(state, 'Andhra Pradesh');
        expect(district, isIn(['Srikakulam', 'Visakhapatnam']));
        return AssemblyLookup.ready(items);
      };

      await _openProfile(tester);
      expect(_assemblyEnabled(tester), isFalse);
      expect(find.text('1 - Ichchapuram'), findsNothing);

      await _openDropdown(tester, 'profileState');
      await _chooseMenuItem(tester, 'Andhra Pradesh');
      expect(_assemblyEnabled(tester), isFalse);

      await _openDropdown(tester, 'profileDistrict');
      await _chooseMenuItem(tester, 'Srikakulam');
      expect(_assemblyEnabled(tester), isTrue);
      await _openAssemblyMenu(tester);
      expect(_assemblyLabels(tester), [
        '1 - Ichchapuram',
        '2 - Palasa',
        '10 - Tekkali',
      ]);

      await tester.enterText(find.byKey(const ValueKey('assemblySearch')), 'i');
      await tester.pump();
      expect(_assemblyLabels(tester), ['1 - Ichchapuram']);

      await tester.enterText(find.byKey(const ValueKey('assemblySearch')), '1');
      await tester.pump();
      expect(_assemblyLabels(tester), ['1 - Ichchapuram', '10 - Tekkali']);

      await tester.enterText(
        find.byKey(const ValueKey('assemblySearch')),
        'asa',
      );
      await tester.pump();
      expect(find.text('No constituencies found'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('clearAssemblySearch')));
      await tester.pump();
      expect(_assemblyLabels(tester), [
        '1 - Ichchapuram',
        '2 - Palasa',
        '10 - Tekkali',
      ]);

      await tester.tap(find.text('1 - Ichchapuram'));
      await tester.pumpAndSettle();
      _expectAssembly(tester, '1 - Ichchapuram');
      final draft =
          OnboardingScope.of(tester.element(find.text('Leader Profile'))).draft;
      expect(draft.assemblyConstituencyId, 1);
      expect(draft.assemblyConstituency, '1 - Ichchapuram');

      await _openDropdown(tester, 'profileDistrict');
      await _chooseMenuItem(tester, 'Visakhapatnam');
      _expectAssembly(tester, null);
      expect(draft.assemblyConstituency, isEmpty);
      expect(draft.assemblyConstituencyId, isNull);
    },
  );

  testWidgets('a district with no list accepts a typed constituency', (
    tester,
  ) async {
    final previous = AssemblyConstituencies.load;
    addTearDown(() => AssemblyConstituencies.load = previous);
    AssemblyConstituencies.load = ({
      required String state,
      required String district,
    }) async {
      return const AssemblyLookup.unavailable();
    };

    await _openProfile(tester);
    await _openDropdown(tester, 'profileState');
    await _chooseMenuItem(tester, 'Karnataka');
    await _openDropdown(tester, 'profileDistrict');
    await _chooseMenuItem(tester, 'Dharwad');
    expect(find.byKey(const ValueKey('assemblyLoadError')), findsNothing);
    expect(find.byKey(const ValueKey('assemblyMenuList')), findsNothing);

    final manual = find.byKey(const ValueKey('profileAssemblyManual'));
    expect(manual, findsOneWidget);
    await tester.enterText(manual, '69 - Navalgund');
    await tester.pump();

    final draft =
        OnboardingScope.of(tester.element(find.text('Leader Profile'))).draft;
    expect(draft.assemblyConstituency, '69 - Navalgund');
    expect(draft.assemblyConstituencyId, isNull);
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

bool _stateEnabled(WidgetTester tester) {
  return tester
          .widget<InkWell>(find.byKey(const ValueKey('profileState')))
          .onTap !=
      null;
}

bool _districtEnabled(WidgetTester tester) {
  return tester
          .widget<InkWell>(find.byKey(const ValueKey('profileDistrict')))
          .onTap !=
      null;
}

void _expectState(WidgetTester tester, String value) {
  expect(
    find.descendant(
      of: find.byKey(const ValueKey('profileState')),
      matching: find.text(value),
    ),
    findsOneWidget,
  );
}

bool _assemblyEnabled(WidgetTester tester) {
  return tester
          .widget<InkWell>(find.byKey(const ValueKey('profileAssembly')))
          .onTap !=
      null;
}

void _expectAssembly(WidgetTester tester, String? value) {
  final field = find.byKey(const ValueKey('profileAssembly'));
  expect(
    find.descendant(
      of: field,
      matching: find.text(value ?? 'Select assembly constituency'),
    ),
    findsOneWidget,
  );
}

List<String> _assemblyLabels(WidgetTester tester) {
  final menu = find.byKey(const ValueKey('assemblyMenuList'));
  return tester
      .widgetList<Text>(find.descendant(of: menu, matching: find.byType(Text)))
      .map((text) => text.data)
      .whereType<String>()
      .toList();
}

Future<void> _openAssemblyMenu(WidgetTester tester) async {
  final finder = find.byKey(const ValueKey('profileAssembly'));
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void _expectDistrict(WidgetTester tester, String? value) {
  final field = find.byKey(const ValueKey('profileDistrict'));
  expect(
    find.descendant(of: field, matching: find.text(value ?? 'Select district')),
    findsOneWidget,
  );
}

List<String> _menuNames(
  WidgetTester tester, [
  String listKey = 'stateMenuList',
]) {
  final menu = find.byKey(ValueKey(listKey));
  return tester
      .widgetList<Text>(find.descendant(of: menu, matching: find.byType(Text)))
      .map((text) => text.data)
      .whereType<String>()
      .toList();
}

Finder _openOptionMenu() {
  for (final key in [
    'designationMenuList',
    'partyMenuList',
    'stateMenuList',
    'districtMenuList',
  ]) {
    final menu = find.byKey(ValueKey(key));
    if (menu.evaluate().isNotEmpty) {
      return menu;
    }
  }
  return find.byKey(const ValueKey('districtMenuList'));
}

Future<void> _chooseMenuItem(WidgetTester tester, String label) async {
  final menu = _openOptionMenu();
  final menuOpen = menu.evaluate().isNotEmpty;
  final item =
      menuOpen
          ? find.descendant(of: menu, matching: find.text(label))
          : find.text(label);
  if (menuOpen) {
    await tester.ensureVisible(item);
  } else {
    await tester.scrollUntilVisible(
      item,
      300,
      scrollable: find.byType(Scrollable).last,
    );
  }
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
