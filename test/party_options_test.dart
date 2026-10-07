import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/features/onboarding/data/political_party.dart';

void main() {
  test('the selector lists 6 national and 14 regional parties', () {
    expect(PartyOption.all, hasLength(20));
    expect(PartyOption.national, hasLength(6));
    expect(PartyOption.regional, hasLength(14));
    expect(PartyOption.names.toSet(), hasLength(20));
  });

  test('every party has a symbol asset and an abbreviation', () {
    for (final party in PartyOption.all) {
      expect(party.symbolAsset, startsWith('assets/images/parties/'));
      expect(
        party.symbolAsset.endsWith('.svg') ||
            party.symbolAsset.endsWith('.png'),
        isTrue,
      );
      expect(party.symbolName.trim(), isNotEmpty);
      expect(party.abbreviation.trim(), isNotEmpty);
      expect(PartyOption.symbolFor(party.name), party.symbolAsset);
    }
    expect(
      PartyOption.national.every((party) => party.homeState == null),
      isTrue,
    );
    expect(
      PartyOption.regional.every((party) => party.homeState != null),
      isTrue,
    );
  });

  test('search matches a party name or abbreviation', () {
    expect(PartyOption.search('BJP').map((party) => party.name), [
      'Bharatiya Janata Party',
    ]);
    expect(
      PartyOption.search('tmc').single.name,
      'All India Trinamool Congress',
    );
    expect(PartyOption.search(''), PartyOption.all);
  });
}
