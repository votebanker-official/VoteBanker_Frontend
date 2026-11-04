import 'political_party.dart';

/// Choices for the leader profile dropdowns. A saved value that is not in
/// the list is kept so an existing draft still displays.
abstract final class ProfileOptions {
  static const designations = <String>[
    'Constituency Leader',
    'Councillor',
    'Mayor',
    'Member of Legislative Assembly (MLA)',
    'State Minister',
    'Chief Minister',
    'Member of Parliament (MP)',
    'Union Minister',
    'Prime Minister',
  ];

  static List<String> get parties => PartyOption.names;

  static List<String> withSaved(List<String> options, String saved) {
    final value = saved.trim();
    if (value.isEmpty || options.contains(value)) {
      return options;
    }
    return [value, ...options];
  }
}
