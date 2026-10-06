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

  test('language menu is English first, then the Indian languages', () {
    expect(AppLanguages.all.map((language) => language.code).toList(), [
      'en',
      'as',
      'bn',
      'brx',
      'doi',
      'gu',
      'hi',
      'kn',
      'ks',
      'kok',
      'mai',
      'ml',
      'mni',
      'mr',
      'ne',
      'or',
      'pa',
      'sa',
      'sat',
      'sd',
      'ta',
      'te',
      'ur',
    ]);
    expect(AppLanguages.all.first.nativeName, 'English');
    expect(
      AppLanguages.all.map((language) => language.code),
      isNot(
        containsAll(['fr', 'es', 'de', 'ar', 'zh', 'ja', 'ko', 'pt', 'ru']),
      ),
    );
  });
}
