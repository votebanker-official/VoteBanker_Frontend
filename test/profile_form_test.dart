import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/features/onboarding/data/contact_number.dart';
import 'package:votebanker/features/onboarding/data/location_catalog.dart';
import 'package:votebanker/features/onboarding/data/location_selection.dart';

void main() {
  test('contact number accepts empty, national, and international values', () {
    expect(isValidContactNumber(''), isTrue);
    expect(isValidContactNumber('   '), isTrue);
    expect(isValidContactNumber('9876543210'), isTrue);
    expect(isValidContactNumber('98765 43210'), isTrue);
    expect(isValidContactNumber('09876543210'), isTrue);
    expect(isValidContactNumber('+1 415 555 2671'), isTrue);
    expect(isValidContactNumber('+1 (415) 555-2671'), isTrue);
    expect(isValidContactNumber('+44 20 7946 0958'), isTrue);
    expect(isValidContactNumber('+44.20.7946.0958'), isTrue);
    expect(isValidContactNumber('0044 20 7946 0958'), isTrue);

    expect(isValidContactNumber('12345'), isFalse);
    expect(isValidContactNumber('abc'), isFalse);
    expect(isValidContactNumber('+123'), isFalse);
    expect(isValidContactNumber('++14155552671'), isFalse);
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
    },
  );
}
