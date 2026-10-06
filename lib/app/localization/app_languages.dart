import '../../features/onboarding/data/profile_languages.dart';

class AppLanguage {
  const AppLanguage(this.code, this.nativeName);

  final String code;

  /// Native script name. These stay the same in every UI language.
  final String nativeName;
}

/// Same Indian language list as [ProfileLanguages], English first.
abstract final class AppLanguages {
  static final all = <AppLanguage>[
    for (final language in ProfileLanguages.all)
      AppLanguage(language.code, language.nativeName),
  ];

  static String nativeName(String code) {
    for (final language in all) {
      if (language.code == code) {
        return language.nativeName;
      }
    }
    return all.first.nativeName;
  }

  static bool supports(String code) {
    return ProfileLanguages.supports(code);
  }
}
