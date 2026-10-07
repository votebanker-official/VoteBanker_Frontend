import 'political_party.dart';

/// Choices for the leader profile dropdowns. A saved value that is not in
/// the list is kept so an existing draft still displays.
abstract final class ProfileOptions {
  static const designations = <String>[
    'MLA',
    'MP',
    'Minister',
    'Chief Minister',
    'Mayor',
    'Councillor',
    'Party President',
    'Constituency Leader',
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
