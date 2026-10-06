class ProfileLanguage {
  const ProfileLanguage(this.code, this.nativeName, this.englishName);

  final String code;
  final String nativeName;
  final String englishName;

  String get label => '$nativeName ($englishName)';
}

/// Languages offered in the app. English is first and is the default when
/// nothing has been saved. Every entry is an Indian language.
abstract final class ProfileLanguages {
  static const all = <ProfileLanguage>[
    ProfileLanguage('en', 'English', 'English'),
    ProfileLanguage('as', 'অসমীয়া', 'Assamese'),
    ProfileLanguage('bn', 'বাংলা', 'Bengali'),
    ProfileLanguage('brx', 'बर’', 'Bodo'),
    ProfileLanguage('doi', 'डोगरी', 'Dogri'),
    ProfileLanguage('gu', 'ગુજરાતી', 'Gujarati'),
    ProfileLanguage('hi', 'हिन्दी', 'Hindi'),
    ProfileLanguage('kn', 'ಕನ್ನಡ', 'Kannada'),
    ProfileLanguage('ks', 'کٲشُر', 'Kashmiri'),
    ProfileLanguage('kok', 'कोंकणी', 'Konkani'),
    ProfileLanguage('mai', 'मैथिली', 'Maithili'),
    ProfileLanguage('ml', 'മലയാളം', 'Malayalam'),
    ProfileLanguage('mni', 'মৈতৈলোন্', 'Manipuri'),
    ProfileLanguage('mr', 'मराठी', 'Marathi'),
    ProfileLanguage('ne', 'नेपाली', 'Nepali'),
    ProfileLanguage('or', 'ଓଡ଼ିଆ', 'Odia'),
    ProfileLanguage('pa', 'ਪੰਜਾਬੀ', 'Punjabi'),
    ProfileLanguage('sa', 'संस्कृतम्', 'Sanskrit'),
    ProfileLanguage('sat', 'ᱥᱟᱱᱛᱟᱲᱤ', 'Santali'),
    ProfileLanguage('sd', 'سنڌي', 'Sindhi'),
    ProfileLanguage('ta', 'தமிழ்', 'Tamil'),
    ProfileLanguage('te', 'తెలుగు', 'Telugu'),
    ProfileLanguage('ur', 'اردو', 'Urdu'),
  ];

  static bool supports(String code) {
    return all.any((language) => language.code == code);
  }
}
