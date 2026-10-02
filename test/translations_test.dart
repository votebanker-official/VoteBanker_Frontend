import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/app/localization/app_languages.dart';
import 'package:votebanker/app/localization/translations/en.dart';
import 'package:votebanker/app/localization/translations/hi.dart';
import 'package:votebanker/app/localization/translations/kn.dart';
import 'package:votebanker/app/localization/translations/ml.dart';
import 'package:votebanker/app/localization/translations/ta.dart';
import 'package:votebanker/app/localization/translations/te.dart';

void main() {
  test('every locale translates every English string', () {
    final expected = enTranslations.keys.toSet();
    expect(expected, isNotEmpty);

    final catalogs = {
      'kn': knTranslations,
      'hi': hiTranslations,
      'te': teTranslations,
      'ta': taTranslations,
      'ml': mlTranslations,
    };

    for (final entry in catalogs.entries) {
      expect(entry.value.keys.toSet(), expected, reason: entry.key);
      for (final value in entry.value.values) {
        expect(value.trim(), isNotEmpty, reason: entry.key);
      }
    }
  });

  test('language menu uses the six native names', () {
    expect(
      AppLanguages.all.map((language) => language.code).toList(),
      ['en', 'kn', 'hi', 'te', 'ta', 'ml'],
    );
    expect(
      AppLanguages.all.map((language) => language.nativeName).toList(),
      ['English', 'ಕನ್ನಡ', 'हिन्दी', 'తెలుగు', 'தமிழ்', 'മലയാളം'],
    );
  });
}
