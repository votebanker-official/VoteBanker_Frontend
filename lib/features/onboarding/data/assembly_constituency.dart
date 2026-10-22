import 'dart:convert';

import 'package:flutter/services.dart';

/// One official assembly constituency returned by the location API.
class AssemblyConstituency {
  const AssemblyConstituency({
    required this.id,
    required this.number,
    required this.name,
    required this.stateId,
    required this.districtId,
  });

  final int id;
  final int number;
  final String name;
  final int stateId;
  final int districtId;

  /// ECI-style label, for example `1 - Ichchapuram`.
  String get label => '$number - $name';

  static AssemblyConstituency? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final number = raw['constituency_number'];
    final name = raw['name'];
    final stateId = raw['state_id'];
    final districtId = raw['district_id'];
    if (id is! int ||
        number is! int ||
        number < 1 ||
        name is! String ||
        name.trim().isEmpty ||
        stateId is! int ||
        districtId is! int) {
      return null;
    }
    return AssemblyConstituency(
      id: id,
      number: number,
      name: name.trim(),
      stateId: stateId,
      districtId: districtId,
    );
  }
}

enum AssemblyLookupStatus { ready, unavailable, failed }

class AssemblyLookup {
  const AssemblyLookup.ready(this.items) : status = AssemblyLookupStatus.ready;

  const AssemblyLookup.unavailable()
    : status = AssemblyLookupStatus.unavailable,
      items = const [];

  const AssemblyLookup.failed()
    : status = AssemblyLookupStatus.failed,
      items = const [];

  final AssemblyLookupStatus status;
  final List<AssemblyConstituency> items;

  static AssemblyLookup parseBody(int statusCode, String body) {
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      return const AssemblyLookup.failed();
    }
    if (decoded is! Map) return const AssemblyLookup.failed();
    if (statusCode == 503 ||
        decoded['error'] == 'assembly_constituency_catalog_unavailable') {
      return const AssemblyLookup.unavailable();
    }
    if (statusCode < 200 || statusCode >= 300) {
      return const AssemblyLookup.failed();
    }
    final data = decoded['data'];
    if (data is! List) return const AssemblyLookup.failed();
    final items = <AssemblyConstituency>[];
    final seen = <int>{};
    for (final row in data) {
      final item = AssemblyConstituency.fromJson(row);
      if (item == null || !seen.add(item.id)) continue;
      items.add(item);
    }
    items.sort((a, b) => a.number.compareTo(b.number));
    return AssemblyLookup.ready(items);
  }
}

/// Number or name prefix match. An empty query keeps [items] in order.
List<AssemblyConstituency> filterConstituencies(
  List<AssemblyConstituency> items,
  String query,
) {
  final prefix = query.trim().toLowerCase();
  if (prefix.isEmpty) return List<AssemblyConstituency>.from(items);
  return [
    for (final item in items)
      if (item.number.toString().startsWith(prefix) ||
          item.name.toLowerCase().startsWith(prefix) ||
          item.label.toLowerCase().startsWith(prefix))
        item,
  ];
}

typedef AssemblyLoader =
    Future<AssemblyLookup> Function({
      required String state,
      required String district,
    });

/// Constituencies bundled with the app, keyed by lowercase state and district.
///
/// The live location API does not serve this catalog yet. The profile uses
/// these rows when that request does not return a list.
class BundledAssemblyCatalog {
  static const assetPath = 'assets/data/assembly_constituencies.json';

  static Map<String, Map<String, List<AssemblyConstituency>>>? _cached;
  static Future<Map<String, Map<String, List<AssemblyConstituency>>>>?
  _pending;

  static Future<AssemblyLookup?> lookup({
    required String state,
    required String district,
  }) async {
    final catalog = await _load();
    final districts = catalog[state.trim().toLowerCase()];
    if (districts == null) return null;
    final items = districts[district.trim().toLowerCase()];
    if (items == null || items.isEmpty) {
      return const AssemblyLookup.unavailable();
    }
    return AssemblyLookup.ready(items);
  }

  static Future<Map<String, Map<String, List<AssemblyConstituency>>>>
  _load() {
    final cached = _cached;
    if (cached != null) return Future.value(cached);
    return _pending ??= _read();
  }

  static Future<Map<String, Map<String, List<AssemblyConstituency>>>>
  _read() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    final catalog = <String, Map<String, List<AssemblyConstituency>>>{};
    if (decoded is Map) {
      for (final state in decoded.entries) {
        if (state.key is! String || state.value is! Map) continue;
        final districts = <String, List<AssemblyConstituency>>{};
        for (final district in (state.value as Map).entries) {
          if (district.key is! String || district.value is! List) continue;
          final items = <AssemblyConstituency>[];
          for (final row in district.value as List) {
            final item = AssemblyConstituency.fromJson(row);
            if (item != null) items.add(item);
          }
          items.sort((a, b) => a.number.compareTo(b.number));
          districts[district.key] = List.unmodifiable(items);
        }
        catalog[state.key] = districts;
      }
    }
    _cached = catalog;
    return catalog;
  }
}

/// Loads assembly constituencies for one state and district.
///
/// [load] is the function the profile screen calls. Tests replace it.
class AssemblyConstituencies {
  static AssemblyLoader load = fetch;

  static Future<AssemblyLookup> fetch({
    required String state,
    required String district,
  }) async {
    final local = await BundledAssemblyCatalog.lookup(
      state: state,
      district: district,
    );
    return local ?? const AssemblyLookup.unavailable();
  }
}
