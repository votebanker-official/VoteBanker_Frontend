import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization/app_languages.dart';
import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../state/onboarding_controller.dart';
import '../widgets/onboarding_actions.dart';
import '../widgets/onboarding_frame.dart';

class BasicProfileScreen extends StatefulWidget {
  const BasicProfileScreen({super.key});

  @override
  State<BasicProfileScreen> createState() => _BasicProfileScreenState();
}

class _BasicProfileScreenState extends State<BasicProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  var _ready = false;

  late final TextEditingController _fullName;
  late final TextEditingController _designation;
  late final TextEditingController _organization;
  late final TextEditingController _country;
  late final TextEditingController _stateRegion;
  late final TextEditingController _constituency;
  late final TextEditingController _publicContact;
  late String _preferredLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) {
      return;
    }
    final draft = OnboardingScope.of(context).draft;
    _fullName = TextEditingController(text: draft.fullName);
    _designation = TextEditingController(text: draft.designation);
    _organization = TextEditingController(text: draft.organization);
    _country = TextEditingController(text: draft.country);
    _stateRegion = TextEditingController(text: draft.stateRegion);
    _constituency = TextEditingController(text: draft.constituency);
    _publicContact = TextEditingController(text: draft.publicContact);
    _preferredLanguage = draft.preferredLanguage;
    _ready = true;
  }

  @override
  void dispose() {
    _fullName.dispose();
    _designation.dispose();
    _organization.dispose();
    _country.dispose();
    _stateRegion.dispose();
    _constituency.dispose();
    _publicContact.dispose();
    super.dispose();
  }

  void _commit() {
    final draft = OnboardingScope.of(context).draft;
    draft
      ..fullName = _fullName.text.trim()
      ..designation = _designation.text.trim()
      ..organization = _organization.text.trim()
      ..country = _country.text.trim()
      ..stateRegion = _stateRegion.text.trim()
      ..constituency = _constituency.text.trim()
      ..publicContact = _publicContact.text.trim()
      ..preferredLanguage = _preferredLanguage;
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
        requestFullMetadata: false,
      );
      if (file == null || !mounted) {
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      OnboardingScope.of(context).draft.photoBytes = bytes;
      setState(() {});
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.photoError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = OnboardingScope.of(context).draft;
    final photo = draft.photoBytes;

    return OnboardingFrame(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingHeader(
              compact: true,
              title: l10n.basicProfile,
              description: l10n.profileDescription,
            ),
            const SizedBox(height: 8),
            Text(l10n.optionalHint, style: AppTextStyles.muted(context)),
            const SizedBox(height: 20),
            _PhotoPicker(
              label: l10n.photo,
              actionLabel: photo == null ? l10n.addPhoto : l10n.changePhoto,
              bytes: photo,
              onPick: _pickPhoto,
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: l10n.fullName,
              controller: _fullName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              onChanged: (value) => draft.fullName = value,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.designation,
              controller: _designation,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (value) => draft.designation = value,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.organization,
              controller: _organization,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.organizationName],
              onChanged: (value) => draft.organization = value,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.country,
              controller: _country,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.countryName],
              onChanged: (value) => draft.country = value,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.stateRegion,
              controller: _stateRegion,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.addressState],
              onChanged: (value) => draft.stateRegion = value,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.constituency,
              controller: _constituency,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (value) => draft.constituency = value,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.publicContact,
              controller: _publicContact,
              textInputAction: TextInputAction.next,
              onChanged: (value) => draft.publicContact = value,
            ),
            const SizedBox(height: 14),
            Text(
              l10n.preferredLanguage,
              style: AppTextStyles.label(context).copyWith(
                fontSize: 13,
                color: context.palette.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _preferredLanguage.isEmpty ? null : _preferredLanguage,
              isExpanded: true,
              hint: Text(l10n.selectLanguage),
              dropdownColor: context.palette.surfaceSecondary,
              items: [
                for (final language in AppLanguages.all)
                  DropdownMenuItem<String>(
                    value: language.code,
                    child: Text(language.nativeName),
                  ),
              ],
              onChanged: (value) {
                draft.preferredLanguage = value ?? '';
                setState(() => _preferredLanguage = value ?? '');
              },
            ),
            const SizedBox(height: 22),
            OnboardingActions(
              backLabel: l10n.back,
              onBack: () {
                _commit();
                AppRouter.back(context, AppRoutes.login);
              },
              primaryLabel: l10n.saveAndContinue,
              onPrimary: () {
                _commit();
                AppRouter.open(context, AppRoutes.domain);
              },
              skipLabel: l10n.skipForNow,
              onSkip: () {
                _commit();
                AppRouter.open(context, AppRoutes.domain);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.label,
    required this.actionLabel,
    required this.onPick,
    this.bytes,
  });

  final String label;
  final String actionLabel;
  final Uint8List? bytes;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      children: [
        Text(label, style: AppTextStyles.label(context)),
        const SizedBox(height: 10),
        Semantics(
          button: true,
          label: actionLabel,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPick,
              child: Ink(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.surfaceSecondary,
                  border: Border.all(color: palette.accent, width: 1.4),
                  image: bytes == null
                      ? null
                      : DecorationImage(
                          image: MemoryImage(bytes!),
                          fit: BoxFit.cover,
                        ),
                ),
                child: bytes == null
                    ? Icon(
                        Icons.add_a_photo_outlined,
                        color: palette.accent,
                        size: 28,
                      )
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          actionLabel,
          style: AppTextStyles.label(context).copyWith(color: palette.accent),
        ),
      ],
    );
  }
}
