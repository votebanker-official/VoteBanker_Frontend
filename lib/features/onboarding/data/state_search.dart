/// States kept at the top of the leader profile menu, in display order.
const priorityProfileStates = <String>[
  'Karnataka',
  'Maharashtra',
  'Tamil Nadu',
  'Kerala',
];

/// Priority states first, then every other name A–Z, with no duplicates.
///
/// Names that are not in [states] are skipped, so the menu never invents a
/// state. Matching against the priority list ignores case, and the spelling
/// from [states] is the one shown.
List<String> prioritizeStates(List<String> states) {
  final remaining = <String>[];
  final seen = <String>{};
  for (final state in states) {
    if (state.isEmpty || !seen.add(state)) {
      continue;
    }
    remaining.add(state);
  }
  remaining.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  final ordered = <String>[];
  for (final priority in priorityProfileStates) {
    final index = remaining.indexWhere(
      (state) => state.toLowerCase() == priority.toLowerCase(),
    );
    if (index == -1) {
      continue;
    }
    ordered.add(remaining.removeAt(index));
  }
  ordered.addAll(remaining);
  return ordered;
}

/// Drops empty and repeated names while keeping the first spelling and order.
List<String> uniqueNames(List<String> names) {
  final seen = <String>{};
  return [
    for (final name in names)
      if (name.isNotEmpty && seen.add(name)) name,
  ];
}

/// States whose names begin with [query], ignoring case and outer spaces.
///
/// An empty query returns [states] in its current order. A match must start
/// at the first character, so a letter in the middle of a name does not match.
List<String> statesMatchingPrefix(List<String> states, String query) {
  final prefix = query.trim().toLowerCase();
  if (prefix.isEmpty) {
    return List<String>.from(states);
  }
  return [
    for (final state in states)
      if (state.toLowerCase().startsWith(prefix)) state,
  ];
}
