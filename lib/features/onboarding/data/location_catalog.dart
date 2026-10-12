import 'dart:convert';

import 'package:flutter/services.dart';

/// Country, state, and district names for the profile form.
///
/// The lists are the Local Government Directory "All States of India" and
/// "All Districts of India" workbooks retrieved on 7 October 2026 from
/// https://lgdirectory.gov.in/downloadDirectory.do.
/// Assembly constituencies are not included. No official
/// district-to-constituency mapping was available to import.
class LocationCatalog {
  LocationCatalog._({
    required List<String> countries,
    required Map<String, List<String>> states,
    required Map<String, Map<String, List<String>>> districts,
  }) : countries = List.unmodifiable(countries),
       _states = states,
       _districts = districts;

  static const assetPath = 'assets/data/locations.json';

  static LocationCatalog? _cached;
  static Future<LocationCatalog>? _pending;

  /// Parsed catalog after [load] has completed. Null until then.
  static LocationCatalog? get instance => _cached;

  static Future<LocationCatalog> load() {
    final cached = _cached;
    if (cached != null) {
      return Future<LocationCatalog>.value(cached);
    }
    return _pending ??= _loadAsset();
  }

  static Future<LocationCatalog> _loadAsset() async {
    final raw = await rootBundle.loadString(assetPath);
    final catalog = parse(raw);
    _cached = catalog;
    return catalog;
  }

  static LocationCatalog parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Location catalog must be a list.');
    }

    final countries = <String>[];
    final states = <String, List<String>>{};
    final districts = <String, Map<String, List<String>>>{};

    for (final entry in decoded) {
      if (entry is! Map) {
        continue;
      }
      final name = entry['name'];
      if (name is! String ||
          name.isEmpty ||
          name != 'India' ||
          countries.contains(name)) {
        continue;
      }

      final stateNames = <String>[];
      final districtMap = <String, List<String>>{};
      final stateEntries = entry['states'];
      if (stateEntries is List) {
        for (final state in stateEntries) {
          if (state is! Map) {
            continue;
          }
          final stateName = state['name'];
          if (stateName is! String ||
              stateName.isEmpty ||
              stateNames.contains(stateName)) {
            continue;
          }
          stateNames.add(stateName);
          districtMap[stateName] = _names(state['districts']);
        }
      }

      countries.add(name);
      states[name] = List.unmodifiable(stateNames);
      districts[name] = districtMap;
    }

    return LocationCatalog._(
      countries: countries,
      states: states,
      districts: districts,
    );
  }

  static List<String> _names(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    final names = <String>[];
    for (final value in raw) {
      if (value is String && value.isNotEmpty && !names.contains(value)) {
        names.add(value);
      }
    }
    return List.unmodifiable(names);
  }

  final List<String> countries;

  final Map<String, List<String>> _states;
  final Map<String, Map<String, List<String>>> _districts;

  List<String> statesOf(String country) => _states[country] ?? const [];

  List<String> districtsOf(String country, String state) {
    return _districts[country]?[state] ?? const [];
  }
}
