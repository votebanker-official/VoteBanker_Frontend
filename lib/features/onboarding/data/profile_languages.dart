class ProfileLanguage {
  const ProfileLanguage(this.code, this.nativeName, this.englishName);

  final String code;
  final String nativeName;
  final String englishName;

  String get label => '$nativeName ($englishName)';
}

/// Languages offered on the leader profile. The app UI stays in the
/// translated locales; this list is only the preferred-language choice.
abstract final class ProfileLanguages {
  static const all = <ProfileLanguage>[
    ProfileLanguage('en', 'English', 'English'),
    ProfileLanguage('af', 'Afrikaans', 'Afrikaans'),
    ProfileLanguage('am', 'አማርኛ', 'Amharic'),
    ProfileLanguage('ar', 'العربية', 'Arabic'),
    ProfileLanguage('as', 'অসমীয়া', 'Assamese'),
    ProfileLanguage('az', 'Azərbaycan', 'Azerbaijani'),
    ProfileLanguage('bn', 'বাংলা', 'Bengali'),
    ProfileLanguage('bg', 'Български', 'Bulgarian'),
    ProfileLanguage('my', 'မြန်မာ', 'Burmese'),
    ProfileLanguage('ca', 'Català', 'Catalan'),
    ProfileLanguage('zh', '中文', 'Chinese'),
    ProfileLanguage('hr', 'Hrvatski', 'Croatian'),
    ProfileLanguage('cs', 'Čeština', 'Czech'),
    ProfileLanguage('da', 'Dansk', 'Danish'),
    ProfileLanguage('nl', 'Nederlands', 'Dutch'),
    ProfileLanguage('et', 'Eesti', 'Estonian'),
    ProfileLanguage('fil', 'Filipino', 'Filipino'),
    ProfileLanguage('fi', 'Suomi', 'Finnish'),
    ProfileLanguage('fr', 'Français', 'French'),
    ProfileLanguage('ka', 'ქართული', 'Georgian'),
    ProfileLanguage('de', 'Deutsch', 'German'),
    ProfileLanguage('el', 'Ελληνικά', 'Greek'),
    ProfileLanguage('gu', 'ગુજરાતી', 'Gujarati'),
    ProfileLanguage('ha', 'Hausa', 'Hausa'),
    ProfileLanguage('he', 'עברית', 'Hebrew'),
    ProfileLanguage('hi', 'हिन्दी', 'Hindi'),
    ProfileLanguage('hu', 'Magyar', 'Hungarian'),
    ProfileLanguage('is', 'Íslenska', 'Icelandic'),
    ProfileLanguage('ig', 'Igbo', 'Igbo'),
    ProfileLanguage('id', 'Bahasa Indonesia', 'Indonesian'),
    ProfileLanguage('ga', 'Gaeilge', 'Irish'),
    ProfileLanguage('it', 'Italiano', 'Italian'),
    ProfileLanguage('ja', '日本語', 'Japanese'),
    ProfileLanguage('kn', 'ಕನ್ನಡ', 'Kannada'),
    ProfileLanguage('kk', 'Қазақ', 'Kazakh'),
    ProfileLanguage('km', 'ខ្មែរ', 'Khmer'),
    ProfileLanguage('ko', '한국어', 'Korean'),
    ProfileLanguage('lo', 'ລາວ', 'Lao'),
    ProfileLanguage('lv', 'Latviešu', 'Latvian'),
    ProfileLanguage('lt', 'Lietuvių', 'Lithuanian'),
    ProfileLanguage('ms', 'Bahasa Melayu', 'Malay'),
    ProfileLanguage('ml', 'മലയാളം', 'Malayalam'),
    ProfileLanguage('mr', 'मराठी', 'Marathi'),
    ProfileLanguage('mn', 'Монгол', 'Mongolian'),
    ProfileLanguage('ne', 'नेपाली', 'Nepali'),
    ProfileLanguage('no', 'Norsk', 'Norwegian'),
    ProfileLanguage('or', 'ଓଡ଼ିଆ', 'Odia'),
    ProfileLanguage('ps', 'پښتو', 'Pashto'),
    ProfileLanguage('fa', 'فارسی', 'Persian'),
    ProfileLanguage('pl', 'Polski', 'Polish'),
    ProfileLanguage('pt', 'Português', 'Portuguese'),
    ProfileLanguage('pa', 'ਪੰਜਾਬੀ', 'Punjabi'),
    ProfileLanguage('ro', 'Română', 'Romanian'),
    ProfileLanguage('ru', 'Русский', 'Russian'),
    ProfileLanguage('sr', 'Српски', 'Serbian'),
    ProfileLanguage('si', 'සිංහල', 'Sinhala'),
    ProfileLanguage('sk', 'Slovenčina', 'Slovak'),
    ProfileLanguage('sl', 'Slovenščina', 'Slovenian'),
    ProfileLanguage('so', 'Soomaali', 'Somali'),
    ProfileLanguage('es', 'Español', 'Spanish'),
    ProfileLanguage('sw', 'Kiswahili', 'Swahili'),
    ProfileLanguage('sv', 'Svenska', 'Swedish'),
    ProfileLanguage('ta', 'தமிழ்', 'Tamil'),
    ProfileLanguage('te', 'తెలుగు', 'Telugu'),
    ProfileLanguage('th', 'ไทย', 'Thai'),
    ProfileLanguage('tr', 'Türkçe', 'Turkish'),
    ProfileLanguage('uk', 'Українська', 'Ukrainian'),
    ProfileLanguage('ur', 'اردو', 'Urdu'),
    ProfileLanguage('uz', 'Oʻzbek', 'Uzbek'),
    ProfileLanguage('vi', 'Tiếng Việt', 'Vietnamese'),
    ProfileLanguage('cy', 'Cymraeg', 'Welsh'),
    ProfileLanguage('yo', 'Yorùbá', 'Yoruba'),
    ProfileLanguage('zu', 'isiZulu', 'Zulu'),
  ];

  static bool supports(String code) {
    return all.any((language) => language.code == code);
  }
}
