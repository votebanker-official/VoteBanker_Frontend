class AppLanguage {
  const AppLanguage(this.code, this.nativeName);

  final String code;

  /// Native script name. These stay the same in every UI language.
  final String nativeName;
}

abstract final class AppLanguages {
  static const all = <AppLanguage>[
    AppLanguage('en', 'English'),
    AppLanguage('kn', 'ಕನ್ನಡ'),
    AppLanguage('hi', 'हिन्दी'),
    AppLanguage('te', 'తెలుగు'),
    AppLanguage('ta', 'தமிழ்'),
    AppLanguage('ml', 'മലയാളം'),
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
    return all.any((language) => language.code == code);
  }
}
