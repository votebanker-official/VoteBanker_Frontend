import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../../onboarding/widgets/onboarding_actions.dart';
import '../../onboarding/widgets/onboarding_frame.dart';
import '../models/website_draft.dart';
import '../widgets/website_language_field.dart';

class WebsiteQuestionsScreen extends StatefulWidget {
  const WebsiteQuestionsScreen({super.key});

  @override
  State<WebsiteQuestionsScreen> createState() => _WebsiteQuestionsScreenState();
}

class _WebsiteQuestionsScreenState extends State<WebsiteQuestionsScreen> {
  final _picker = ImagePicker();
  static const _fillFirst = 'Fill this field first';

  var _page = 0;
  var _ready = false;
  List<TextEditingController> _controllers = [];
  List<String?> _errors = [];
  List<_QuestionPage> _pages = [];
  String? _logoError;
  String? _photosError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) {
      return;
    }
    final onboarding = OnboardingScope.of(context);
    final website = onboarding.website;
    final session = AuthService.instance.session;
    website.applyLoginName(
      signedIn: session != null,
      loginName: session?.fullName ?? '',
      profileName: onboarding.draft.fullName,
    );
    _pages = _questionPages(website);
    _controllers = [
      for (final page in _pages)
        for (final field in page.fields) TextEditingController(text: field.read()),
    ];
    _errors = List<String?>.filled(_controllers.length, null);
    _ready = true;
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  int _controllerIndex(_QuestionPage page, int fieldIndex) {
    var index = 0;
    for (final item in _pages) {
      if (identical(item, page)) {
        return index + fieldIndex;
      }
      index += item.fields.length;
    }
    return 0;
  }

  void _writePage(_QuestionPage page) {
    for (var i = 0; i < page.fields.length; i++) {
      page.fields[i].write(_controllers[_controllerIndex(page, i)].text.trim());
    }
  }

  void _continue(_QuestionPage page, {required bool last}) {
    if (!_requirePage(page)) return;
    if (last) {
      AppRouter.open(context, AppRoutes.websiteSections);
      return;
    }
    setState(() => _page += 1);
  }

  bool _requirePage(_QuestionPage page) {
    if (page.media) {
      final website = OnboardingScope.of(context).website;
      final logoMissing = website.logo == null;
      final photosMissing = website.photos.isEmpty;
      setState(() {
        _logoError = logoMissing ? _fillFirst : null;
        _photosError = photosMissing ? _fillFirst : null;
      });
      return !logoMissing && !photosMissing;
    }
    _writePage(page);
    final next = List<String?>.from(_errors);
    var missing = false;
    for (var i = 0; i < page.fields.length; i++) {
      final index = _controllerIndex(page, i);
      final empty = _controllers[index].text.trim().isEmpty;
      next[index] = empty ? _fillFirst : null;
      missing = missing || empty;
    }
    setState(() => _errors = next);
    return !missing;
  }

  Future<void> _pick(void Function(Uint8List bytes) save) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (image == null) {
        return;
      }
      final bytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() {
        save(bytes);
        final website = OnboardingScope.of(context).website;
        if (website.logo != null) _logoError = null;
        if (website.photos.isNotEmpty) _photosError = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).photoError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final website = OnboardingScope.of(context).website;
    final page = _pages[_page];
    final last = _page == _pages.length - 1;

    return OnboardingFrame(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingHeader(
              compact: true,
              title: l10n.line(page.titleKey),
              description: l10n.line('questionsBody'),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.line('questionProgress').replaceAll('{step}', '${_page + 1}').replaceAll('{total}', '${_pages.length}'),
              style: AppTextStyles.principle(context),
            ),
            const SizedBox(height: 16),
            if (page.media)
              _MediaFields(
                website: website,
                logoError: _logoError,
                photosError: _photosError,
                onLogo: () => _pick((bytes) => website.logo = bytes),
                onPhoto: () => _pick((bytes) {
                  if (website.photos.length < 3) {
                    website.photos.add(bytes);
                  }
                }),
              )
            else
              for (var i = 0; i < page.fields.length; i++) ...[
                WebsiteAnswerField(
                  label: l10n.line(page.fields[i].labelKey),
                  maxLines: page.fields[i].maxLines,
                  controller: _controllers[_controllerIndex(page, i)],
                  errorText: _errors[_controllerIndex(page, i)],
                  onChanged: (value) {
                    final index = _controllerIndex(page, i);
                    if (value.trim().isEmpty || _errors[index] == null) {
                      return;
                    }
                    setState(() => _errors[index] = null);
                  },
                ),
                const SizedBox(height: 12),
              ],
            OnboardingActions(
              backLabel: l10n.back,
              onBack: () {
                _writePage(page);
                if (_page == 0) {
                  AppRouter.back(context, AppRoutes.websiteInfo);
                  return;
                }
                setState(() => _page -= 1);
              },
              primaryLabel: last ? l10n.line('continueAction') : l10n.next,
              onPrimary: () => _continue(page, last: last),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestionPage {
  const _QuestionPage(this.titleKey, this.fields, {this.media = false});

  final String titleKey;
  final List<_Field> fields;
  final bool media;
}

class _Field {
  const _Field(this.labelKey, this.read, this.write, {this.maxLines = 1});

  final String labelKey;
  final String Function() read;
  final void Function(String value) write;
  final int maxLines;
}

List<_QuestionPage> _questionPages(WebsiteDraft website) {
  return [
    _QuestionPage('qPageIdentity', [
      _Field('qFullName', () => website.fullName, (value) => website.fullName = value),
      _Field('qTitle', () => website.publicTitle, (value) => website.publicTitle = value),
      _Field('qOrganization', () => website.organization, (value) => website.organization = value),
    ]),
    _QuestionPage('qPageStory', [
      _Field('qIntro', () => website.introduction, (value) => website.introduction = value, maxLines: 3),
      _Field('qAbout', () => website.about, (value) => website.about = value, maxLines: 4),
      _Field('qVision', () => website.vision, (value) => website.vision = value, maxLines: 3),
      _Field('qMission', () => website.mission, (value) => website.mission = value, maxLines: 3),
    ]),
    _QuestionPage('qPageWork', [
      _Field('qWork', () => website.achievements, (value) => website.achievements = value, maxLines: 4),
      _Field('qPriorities', () => website.priorities, (value) => website.priorities = value, maxLines: 3),
      _Field('qCta', () => website.callToAction, (value) => website.callToAction = value, maxLines: 2),
    ]),
    _QuestionPage('qPageContact', [
      _Field('qContact', () => website.publicContact, (value) => website.publicContact = value, maxLines: 2),
      _Field('qAddress', () => website.address, (value) => website.address = value, maxLines: 2),
      _Field('qPhone', () => website.phone, (value) => website.phone = value),
      _Field('qEmail', () => website.email, (value) => website.email = value),
      _Field('qSocial', () => website.socialLinks, (value) => website.socialLinks = value, maxLines: 2),
      _Field('qLinks', () => website.publicLinks, (value) => website.publicLinks = value, maxLines: 2),
    ]),
    const _QuestionPage('qPageMedia', [], media: true),
  ];
}

class _MediaFields extends StatelessWidget {
  const _MediaFields({
    required this.website,
    required this.onLogo,
    required this.onPhoto,
    this.logoError,
    this.photosError,
  });

  final WebsiteDraft website;
  final VoidCallback onLogo;
  final VoidCallback onPhoto;
  final String? logoError;
  final String? photosError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${l10n.line('qLogo')} *', style: AppTextStyles.label(context)),
        const SizedBox(height: 8),
        _ImageButton(
          bytes: website.logo,
          label: l10n.addPhoto,
          onPressed: onLogo,
        ),
        if (logoError != null) _FieldError(logoError!),
        const SizedBox(height: 16),
        Text('${l10n.line('qPhotos')} *', style: AppTextStyles.label(context)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final photo in website.photos)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(photo, width: 72, height: 72, fit: BoxFit.cover),
              ),
            _ImageButton(label: l10n.addPhoto, onPressed: onPhoto),
          ],
        ),
        if (photosError != null) _FieldError(photosError!),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _FieldError extends StatelessWidget {
  const _FieldError(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message,
        style: AppTextStyles.body(context).copyWith(
          color: context.palette.danger,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _ImageButton extends StatelessWidget {
  const _ImageButton({
    required this.label,
    required this.onPressed,
    this.bytes,
  });

  final String label;
  final VoidCallback onPressed;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(bytes == null ? Icons.add_a_photo_outlined : Icons.check, color: context.palette.accent),
      label: Text(label),
    );
  }
}
