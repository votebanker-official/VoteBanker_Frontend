import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../features/onboarding/data/profile_languages.dart';
import 'translations/en.dart';
import 'translations/indian.dart';
import 'translations/hi.dart';
import 'translations/kn.dart';
import 'translations/ml.dart';
import 'translations/ta.dart';
import 'translations/te.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static final supportedLocales = <Locale>[
    for (final language in ProfileLanguages.all) Locale(language.code),
  ];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(value != null, 'AppLocalizations was not found in this context.');
    return value!;
  }

  static final _catalog = <String, Map<String, String>>{
    'en': enTranslations,
    'kn': knTranslations,
    'hi': hiTranslations,
    'te': teTranslations,
    'ta': taTranslations,
    'ml': mlTranslations,
    ...indianTranslations,
  };

  String _t(String key) {
    final language = _catalog[locale.languageCode] ?? enTranslations;
    return language[key] ?? enTranslations[key] ?? key;
  }

  String stepProgress(int step, int total) {
    return _t(
      'stepProgress',
    ).replaceAll('{step}', '$step').replaceAll('{total}', '$total');
  }

  String get appName => _t('appName');
  String get descriptor => _t('descriptor');
  String get principle => _t('principle');
  String get skipForNow => _t('skipForNow');
  String get back => _t('back');
  String get next => _t('next');
  String get language => _t('language');
  String get welcomeTitle => _t('welcomeTitle');
  String get welcomeBody => _t('welcomeBody');
  String get continueWhatsApp => _t('continueWhatsApp');
  String get continueMobile => _t('continueMobile');
  String get continueEmail => _t('continueEmail');
  String get authLater => _t('authLater');
  String get basicProfile => _t('basicProfile');
  String get profileDescription => _t('profileDescription');
  String get profilePlatform => _t('profilePlatform');
  String get profilePhotoTitle => _t('profilePhotoTitle');
  String get profilePhotoHint => _t('profilePhotoHint');
  String get takePhoto => _t('takePhoto');
  String get selectFromAlbum => _t('selectFromAlbum');
  String get takeSelfie => _t('takeSelfie');
  String get capturePhoto => _t('capturePhoto');
  String get cameraUnavailable => _t('cameraUnavailable');
  String get deletePhoto => _t('deletePhoto');
  String get enterFullName => _t('enterFullName');
  String get selectDesignation => _t('selectDesignation');
  String get selectParty => _t('selectParty');
  String get nationalParties => _t('nationalParties');
  String get regionalParties => _t('regionalParties');
  String get locationSection => _t('locationSection');
  String get selectCountry => _t('selectCountry');
  String get selectState => _t('selectState');
  String get selectDistrict => _t('selectDistrict');
  String get selectConstituency => _t('selectConstituency');
  String get enterBoothNumber => _t('enterBoothNumber');
  String get enterBoothName => _t('enterBoothName');
  String get contactSection => _t('contactSection');
  String get enterMobile => _t('enterMobile');
  String get profileStep => _t('profileStep');
  String get fullName => _t('fullName');
  String get photo => _t('photo');
  String get designation => _t('designation');
  String get assemblyConstituency => _t('assemblyConstituency');
  String get organization => _t('organization');
  String get country => _t('country');
  String get stateRegion => _t('stateRegion');
  String get constituency => _t('constituency');
  String get publicContact => _t('publicContact');
  String get preferredLanguage => _t('preferredLanguage');
  String get partNo => _t('partNo');
  String get partName => _t('partName');
  String get invalidContact => _t('invalidContact');
  String get invalidSelection => _t('invalidSelection');
  String get selectLanguage => _t('selectLanguage');
  String get saveAndContinue => _t('saveAndContinue');
  String get addPhoto => _t('addPhoto');
  String get changePhoto => _t('changePhoto');
  String get optionalHint => _t('optionalHint');
  String get photoError => _t('photoError');
  String get domainTitle => _t('domainTitle');
  String get domainDescription => _t('domainDescription');
  String get searchPlaceholder => _t('searchPlaceholder');
  String get available => _t('available');
  String get add => _t('add');
  String get selected => _t('selected');
  String get whiteLabelTitle => _t('whiteLabelTitle');
  String get whiteLabelBody => _t('whiteLabelBody');
  String get domainEmpty => _t('domainEmpty');
  String get domainNeedLatin => _t('domainNeedLatin');
  String get perYear => _t('perYear');
  String get dashboard => _t('dashboard');
  String get dashboardSubtitle => _t('dashboardSubtitle');
  String get cardProfile => _t('cardProfile');
  String get cardDomain => _t('cardDomain');
  String get cardSocial => _t('cardSocial');
  String get cardContent => _t('cardContent');
  String get cardVrm => _t('cardVrm');
  String get cardVolunteers => _t('cardVolunteers');
  String get cardEvents => _t('cardEvents');
  String get cardIssues => _t('cardIssues');
  String get cardTeam => _t('cardTeam');
  String get cardAnalytics => _t('cardAnalytics');
  String get cardMarketplace => _t('cardMarketplace');
  String get comingLater => _t('comingLater');
  String get optionalLabel => _t('optionalLabel');
  String get websiteTitle => _t('websiteTitle');
  String get websiteBody => _t('websiteBody');
  String get templatePublic => _t('templatePublic');
  String get templatePublicBody => _t('templatePublicBody');
  String get templateWork => _t('templateWork');
  String get templateWorkBody => _t('templateWorkBody');
  String get templateIssue => _t('templateIssue');
  String get templateIssueBody => _t('templateIssueBody');
  String get websiteOffer => _t('websiteOffer');
  String get portfolioTemplates => _t('portfolioTemplates');
  String get portfolioMyWebsite => _t('portfolioMyWebsite');
  String get portfolioRecommended => _t('portfolioRecommended');
  String get portfolioNavHome => _t('portfolioNavHome');
  String get portfolioNavAbout => _t('portfolioNavAbout');
  String get portfolioNavVision => _t('portfolioNavVision');
  String get portfolioNavGallery => _t('portfolioNavGallery');
  String get portfolioNavContact => _t('portfolioNavContact');
  String get portfolioHeadlineModern => _t('portfolioHeadlineModern');
  String get portfolioSupportModern => _t('portfolioSupportModern');
  String get portfolioHeadlineTraditional => _t('portfolioHeadlineTraditional');
  String get portfolioSupportTraditional => _t('portfolioSupportTraditional');
  String get portfolioHeadlinePeople => _t('portfolioHeadlinePeople');
  String get portfolioSupportPeople => _t('portfolioSupportPeople');
  String get portfolioJoin => _t('portfolioJoin');
  String get portfolioModernCampaign => _t('portfolioModernCampaign');
  String get portfolioTraditionalCampaign => _t('portfolioTraditionalCampaign');
  String get portfolioPeopleCampaign => _t('portfolioPeopleCampaign');
  String get portfolioModern => _t('portfolioModern');
  String get portfolioModernBody => _t('portfolioModernBody');
  String get portfolioTraditional => _t('portfolioTraditional');
  String get portfolioTraditionalBody => _t('portfolioTraditionalBody');
  String get portfolioPeople => _t('portfolioPeople');
  String get portfolioPeopleBody => _t('portfolioPeopleBody');
  String get portfolioMakeYours => _t('portfolioMakeYours');
  String get portfolioMakeYoursBody => _t('portfolioMakeYoursBody');
  String get portfolioGetWebsite => _t('portfolioGetWebsite');
  String get portfolioOneTime => _t('portfolioOneTime');
  String get portfolioSkip => _t('portfolioSkip');
  String get portfolioNotReady => _t('portfolioNotReady');
  String get websiteLater => _t('websiteLater');
  String get socialTitle => _t('socialTitle');
  String get socialBody => _t('socialBody');
  String get socialInstagram => _t('socialInstagram');
  String get socialFacebook => _t('socialFacebook');
  String get socialMeta => _t('socialMeta');
  String get viewPlans => _t('viewPlans');
  String get socialLater => _t('socialLater');
  String get vrmTitle => _t('vrmTitle');
  String get vrmBody => _t('vrmBody');
  String get vrmPointContacts => _t('vrmPointContacts');
  String get vrmPointTeam => _t('vrmPointTeam');
  String get vrmPointIssues => _t('vrmPointIssues');
  String get vrmSetup => _t('vrmSetup');
  String get vrmLater => _t('vrmLater');
  String get readyTitle => _t('readyTitle');
  String get readyBody => _t('readyBody');
  String get goToDashboard => _t('goToDashboard');
  String get exploreFeatures => _t('exploreFeatures');
  String get joinNetwork => _t('joinNetwork');
  String get joinLater => _t('joinLater');
  String get cardCampaign => _t('cardCampaign');
  String get cardBilling => _t('cardBilling');
  String get cardSettings => _t('cardSettings');

  String welcomeBack(String name) {
    return _t('welcomeBack').replaceAll('{name}', name);
  }

  String line(String key) => _t(key);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ProfileLanguages.supports(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
