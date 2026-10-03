import 'location_catalog.dart';

enum LocationIssue { country, state, district }

/// Country, state, and district values for one profile form.
///
/// Changing the country clears the state and district. Changing the state
/// clears the district. Restoring a saved profile keeps a value only when
/// it belongs to the current parent list.
class LocationSelection {
  String country = '';
  String state = '';
  String district = '';

  void selectCountry(String? value) {
    final next = value ?? '';
    if (next == country) {
      return;
    }
    country = next;
    state = '';
    district = '';
  }

  void selectState(String? value) {
    final next = value ?? '';
    if (next == state) {
      return;
    }
    state = next;
    district = '';
  }

  void selectDistrict(String? value) {
    district = value ?? '';
  }

  void restore({
    required LocationCatalog catalog,
    required String country,
    required String state,
    required String district,
  }) {
    if (country.isEmpty || !catalog.countries.contains(country)) {
      this.country = '';
      this.state = '';
      this.district = '';
      return;
    }

    this.country = country;
    if (state.isEmpty || !catalog.statesOf(country).contains(state)) {
      this.state = '';
      this.district = '';
      return;
    }

    this.state = state;
    final districts = catalog.districtsOf(country, state);
    this.district = district.isNotEmpty && districts.contains(district)
        ? district
        : '';
  }

  LocationIssue? issue(LocationCatalog catalog) {
    if (country.isNotEmpty && !catalog.countries.contains(country)) {
      return LocationIssue.country;
    }
    if (state.isNotEmpty &&
        (country.isEmpty || !catalog.statesOf(country).contains(state))) {
      return LocationIssue.state;
    }
    if (district.isNotEmpty &&
        (state.isEmpty ||
            !catalog.districtsOf(country, state).contains(district))) {
      return LocationIssue.district;
    }
    return null;
  }
}
