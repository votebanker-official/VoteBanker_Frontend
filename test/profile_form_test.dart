import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/core/services/profile_service.dart';
import 'package:votebanker/features/onboarding/data/assembly_constituency.dart';
import 'package:votebanker/features/onboarding/data/contact_number.dart';
import 'package:votebanker/features/onboarding/data/location_catalog.dart';
import 'package:votebanker/features/onboarding/data/location_selection.dart';
import 'package:votebanker/features/onboarding/data/state_search.dart';
import 'package:votebanker/features/onboarding/models/onboarding_draft.dart';

void main() {
  test('contact number accepts only valid 10-digit Indian mobile numbers', () {
    // Valid 10-digit Indian numbers starting with 6, 7, 8, or 9
    expect(isValidContactNumber('9876543210'), isTrue);
    expect(isValidContactNumber('8123456789'), isTrue);
    expect(isValidContactNumber('7012345678'), isTrue);
    expect(isValidContactNumber('6901234567'), isTrue);
    expect(isValidContactNumber('98765 43210'), isTrue);

    // Existing saved formats with +91 or trunk 0
    expect(isValidContactNumber('+919876543210'), isTrue);
    expect(isValidContactNumber('+91 98765 43210'), isTrue);
    expect(isValidContactNumber('09876543210'), isTrue);

    // Empty or blank input (required field)
    expect(isValidContactNumber(''), isFalse);
    expect(isValidContactNumber('   '), isFalse);

    // Fewer than 10 digits
    expect(isValidContactNumber('12345'), isFalse);
    expect(isValidContactNumber('98765'), isFalse);
    expect(isValidContactNumber('987654321'), isFalse);

    // More than 10 digits
    expect(isValidContactNumber('98765432101'), isFalse);
    expect(isValidContactNumber('9876543210123'), isFalse);

    // Invalid starting digits (must start with 6, 7, 8, or 9)
    expect(isValidContactNumber('5876543210'), isFalse);
    expect(isValidContactNumber('1234567890'), isFalse);
    expect(isValidContactNumber('0123456789'), isFalse);
    expect(isValidContactNumber('2345678901'), isFalse);
    expect(isValidContactNumber('3456789012'), isFalse);
    expect(isValidContactNumber('4567890123'), isFalse);

    // Non-numeric input
    expect(isValidContactNumber('abc'), isFalse);
    expect(isValidContactNumber('98765abcde'), isFalse);
    expect(isValidContactNumber('+123'), isFalse);
    expect(isValidContactNumber('++14155552671'), isFalse);

    // International numbers outside India
    expect(isValidContactNumber('+1 415 555 2671'), isFalse);
    expect(isValidContactNumber('+44 20 7946 0958'), isFalse);
  });

  test('extractIndianNationalNumber extracts 10 digits without country code duplication', () {
    expect(extractIndianNationalNumber('+919876543210'), '9876543210');
    expect(extractIndianNationalNumber('+91 98765 43210'), '9876543210');
    expect(extractIndianNationalNumber('09876543210'), '9876543210');
    expect(extractIndianNationalNumber('9876543210'), '9876543210');
    expect(extractIndianNationalNumber('919876543210'), '9876543210');
    expect(extractIndianNationalNumber(''), '');
  });

  test('IndianMobileNumberFormatter enforces digitsOnly, 10-digit limit, and handles paste', () {
    const formatter = IndianMobileNumberFormatter();

    // Normal typing of digits
    final typed = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '98765'),
    );
    expect(typed.text, '98765');

    // Reject non-numeric characters
    final withLetters = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: 'abc98765xyz'),
    );
    expect(withLetters.text, '98765');

    // Caps at 10 digits
    final overLimit = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '9876543210999'),
    );
    expect(overLimit.text, '9876543210');

    // Pasting number with +91 country code prefix
    final pastedWithCountryCode = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '+91 98765 43210'),
    );
    expect(pastedWithCountryCode.text, '9876543210');

    // Pasting number with trunk 0 prefix
    final pastedWithTrunk = formatter.formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(text: '09876543210'),
    );
    expect(pastedWithTrunk.text, '9876543210');
  });

  test('country and state changes clear the child selections', () {
    final catalog = LocationCatalog.parse('''
[
  {"name":"India","states":[
    {"name":"Karnataka","districts":["Bagalkot","Mysore"]},
    {"name":"Maharashtra","districts":["Pune"]}
  ]},
  {"name":"Nepal","states":[]}
]
''');
    final selection =
        LocationSelection()
          ..selectCountry('India')
          ..selectState('Karnataka')
          ..selectDistrict('Mysore');

    selection.selectCountry('India');
    expect(selection.state, 'Karnataka');
    expect(selection.district, 'Mysore');

    selection.selectState('Maharashtra');
    expect(selection.district, isEmpty);

    selection
      ..selectDistrict('Pune')
      ..selectCountry('Nepal');
    expect(selection.country, 'Nepal');
    expect(selection.state, isEmpty);
    expect(selection.district, isEmpty);
    expect(catalog.countries, ['India']);
    expect(selection.issue(catalog), LocationIssue.country);

    selection.restore(
      catalog: catalog,
      country: 'India',
      state: 'Karnataka',
      district: 'Pune',
    );
    expect(selection.country, 'India');
    expect(selection.state, 'Karnataka');
    expect(selection.district, isEmpty);

    selection.restore(
      catalog: catalog,
      country: 'Nowhere',
      state: 'Karnataka',
      district: 'Mysore',
    );
    expect(selection.country, isEmpty);
    expect(selection.state, isEmpty);
    expect(selection.district, isEmpty);
  });

  test(
    'bundled catalog uses state names and that state\'s districts',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final catalog = await LocationCatalog.load();

      expect(catalog.countries, ['India']);

      final indiaStates = catalog.statesOf('India');
      final karnataka = catalog.districtsOf('India', 'Karnataka');
      final maharashtra = catalog.districtsOf('India', 'Maharashtra');
      expect(indiaStates, hasLength(36));
      expect(indiaStates, containsAll(['Karnataka', 'Telangana', 'Ladakh']));
      expect(karnataka, contains('Bengaluru Urban'));
      expect(karnataka, isNot(contains('Pune')));
      expect(karnataka, isNot(contains('Electronic City')));
      expect(maharashtra, contains('Pune'));
      expect(maharashtra, isNot(contains('Pune Division')));
      expect(maharashtra, isNot(contains('Bengaluru Urban')));
      for (final district in karnataka) {
        expect(indiaStates, isNot(contains(district)));
      }

      expect(catalog.statesOf('United States'), isEmpty);
      expect(catalog.districtsOf('United States', 'California'), isEmpty);

      const indianStates = <String>[
        'Andhra Pradesh',
        'Arunachal Pradesh',
        'Assam',
        'Bihar',
        'Chhattisgarh',
        'Goa',
        'Gujarat',
        'Haryana',
        'Himachal Pradesh',
        'Jharkhand',
        'Karnataka',
        'Kerala',
        'Madhya Pradesh',
        'Maharashtra',
        'Manipur',
        'Meghalaya',
        'Mizoram',
        'Nagaland',
        'Odisha',
        'Punjab',
        'Rajasthan',
        'Sikkim',
        'Tamil Nadu',
        'Telangana',
        'Tripura',
        'Uttar Pradesh',
        'Uttarakhand',
        'West Bengal',
      ];
      const unionTerritories = <String>[
        'Andaman And Nicobar Islands',
        'Chandigarh',
        'Delhi',
        'Jammu And Kashmir',
        'Ladakh',
        'Lakshadweep',
        'Puducherry',
        'The Dadra And Nagar Haveli And Daman And Diu',
      ];
      expect(indianStates, hasLength(28));
      expect(indiaStates, containsAll(indianStates));
      expect(indiaStates, containsAll(unionTerritories));

      final ordered = prioritizeStates(indiaStates);
      expect(ordered.take(4).toList(), priorityProfileStates);
      expect(ordered.toSet(), indiaStates.toSet());
      expect(ordered, hasLength(indiaStates.length));
      final rest = ordered.skip(4).toList();
      final sorted = [...rest]
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      expect(rest, sorted);
      expect(ordered.where((name) => name == 'Karnataka'), ['Karnataka']);

      expect(statesMatchingPrefix(ordered, 'K'), ['Karnataka', 'Kerala']);
      expect(statesMatchingPrefix(ordered, 'k'), ['Karnataka', 'Kerala']);
      expect(statesMatchingPrefix(ordered, 'ka'), ['Karnataka']);
      expect(statesMatchingPrefix(ordered, 'KA'), ['Karnataka']);
      expect(statesMatchingPrefix(ordered, '  M '), [
        'Maharashtra',
        'Madhya Pradesh',
        'Manipur',
        'Meghalaya',
        'Mizoram',
      ]);
      expect(statesMatchingPrefix(ordered, 'pradesh'), isEmpty);
      expect(statesMatchingPrefix(ordered, 'nataka'), isEmpty);
      expect(statesMatchingPrefix(ordered, 'zzz'), isEmpty);
      expect(statesMatchingPrefix(ordered, '   '), ordered);
      expect(prioritizeStates(const ['Kerala', 'Goa', 'Kerala', 'karnataka']), [
        'karnataka',
        'Kerala',
        'Goa',
      ]);

      final karnatakaDistricts = uniqueNames(
        catalog.districtsOf('India', 'Karnataka'),
      );
      expect(karnatakaDistricts, isNot(contains('Pune')));
      expect(karnatakaDistricts.toSet(), hasLength(karnatakaDistricts.length));
      expect(statesMatchingPrefix(karnatakaDistricts, 'D'), [
        'Dakshina Kannada',
        'Davanagere',
        'Dharwad',
      ]);
      expect(
        statesMatchingPrefix(karnatakaDistricts, 'd'),
        statesMatchingPrefix(karnatakaDistricts, 'D'),
      );
      expect(statesMatchingPrefix(karnatakaDistricts, 'B'), [
        'Bagalkote',
        'Ballari',
        'Belagavi',
        'Bengaluru Rural',
        'Bengaluru South',
        'Bengaluru Urban',
        'Bidar',
      ]);
      expect(statesMatchingPrefix(karnatakaDistricts, 'urban'), isEmpty);
      expect(statesMatchingPrefix(karnatakaDistricts, 'kannada'), isEmpty);
      expect(
        statesMatchingPrefix(karnatakaDistricts, '   '),
        karnatakaDistricts,
      );
      expect(uniqueNames(const ['Dharwad', 'Dharwad', 'Davanagere']), [
        'Dharwad',
        'Davanagere',
      ]);
    },
  );

  test('selected district is included in the saved profile payload', () {
    final draft =
        OnboardingDraft()
          ..country = 'India'
          ..stateRegion = 'Karnataka'
          ..constituency = 'Dharwad';
    final payload = ProfileService.profilePayload(draft);
    expect(payload['state_region'], 'Karnataka');
    expect(payload['constituency'], 'Dharwad');
    expect(payload.containsKey('assembly_constituency_id'), isFalse);
    draft.assemblyConstituencyId = 1;
    expect(ProfileService.profilePayload(draft)['assembly_constituency_id'], 1);

    final loaded = OnboardingDraft();
    ProfileService.applyProfile(loaded, {
      'state_region': 'Karnataka',
      'constituency': 'Dharwad',
    });
    expect(loaded.stateRegion, 'Karnataka');
    expect(loaded.constituency, 'Dharwad');
  });

  test('constituency search matches a number or name prefix', () {
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

    expect(filterConstituencies(items, '  I ').map((item) => item.label), [
      '1 - Ichchapuram',
    ]);
    expect(filterConstituencies(items, '1').map((item) => item.label), [
      '1 - Ichchapuram',
      '10 - Tekkali',
    ]);
    expect(filterConstituencies(items, 'asa'), isEmpty);
    expect(filterConstituencies(items, '   '), items);

    final unavailable = AssemblyLookup.parseBody(
      503,
      '{"error":"assembly_constituency_catalog_unavailable","data":[]}',
    );
    expect(unavailable.status, AssemblyLookupStatus.unavailable);
    expect(unavailable.items, isEmpty);

    final ready = AssemblyLookup.parseBody(
      200,
      '{"data":[{"id":1,"state_id":28,"district_id":519,"constituency_number":1,"name":"Ichchapuram"}]}',
    );
    expect(ready.items.single.label, '1 - Ichchapuram');
  });

  test('the bundled catalog lists Dharwad constituencies by number', () async {
    final lookup = await BundledAssemblyCatalog.lookup(
      state: 'Karnataka',
      district: 'Dharwad',
    );
    expect(
      lookup?.items.map((item) => item.label).toList(),
      [
        '69 - Navalgund',
        '70 - Kundgol',
        '71 - Dharwad',
        '72 - Hubli-Dharwad-East(SC)',
        '73 - Hubli-Dharwad-Central',
        '74 - Hubli-Dharwad- West',
        '75 - Kalghatgi',
      ],
    );
  });
}
