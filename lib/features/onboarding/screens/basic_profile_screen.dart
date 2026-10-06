import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../data/contact_number.dart';
import '../data/location_catalog.dart';
import '../data/location_selection.dart';
import '../models/onboarding_draft.dart';
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
  final _contactAnchor = GlobalKey();
  final _phoneInput = FilteringTextInputFormatter.allow(
    RegExp(r'[0-9+\-().\s]'),
  );
  final _selection = LocationSelection();
  var _ready = false;

  late final TextEditingController _leaderName;
  late final TextEditingController _assemblyConstituency;
  late final TextEditingController _boothNumber;
  late final TextEditingController _boothName;
  late final TextEditingController _party;
  late final TextEditingController _designation;
  late final TextEditingController _contactNumber;
  late String _preferredLanguage;

  LocationCatalog? _catalog;
  String? _contactError;
  LocationIssue? _locationIssue;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) {
      return;
    }
    final draft = OnboardingScope.of(context).draft;
    _leaderName = TextEditingController(text: draft.leaderName);
    _assemblyConstituency = TextEditingController(
      text: draft.assemblyConstituency,
    );
    _boothNumber = TextEditingController(text: draft.boothNumber);
    _boothName = TextEditingController(text: draft.boothName);
    _party = TextEditingController(text: draft.party);
    _designation = TextEditingController(text: draft.designation);
    _contactNumber = TextEditingController(text: draft.contactNumber);
    _preferredLanguage =
        draft.preferredLanguage.trim().isEmpty ? 'en' : draft.preferredLanguage;
    if (draft.preferredLanguage.trim().isEmpty) {
      draft.preferredLanguage = 'en';
    }
    _ready = true;
    final readyCatalog = LocationCatalog.instance;
    if (readyCatalog != null) {
      _applyCatalog(readyCatalog, draft);
    } else {
      unawaited(_loadLocations(draft));
    }
  }

  void _applyCatalog(LocationCatalog catalog, OnboardingDraft draft) {
    _catalog = catalog;
    _selection.restore(
      catalog: catalog,
      country: draft.country,
      state: draft.stateRegion,
      district: draft.constituency,
    );
    draft
      ..country = _selection.country
      ..stateRegion = _selection.state
      ..constituency = _selection.district;
  }

  Future<void> _loadLocations(OnboardingDraft draft) async {
    try {
      final catalog = await LocationCatalog.load();
      if (!mounted) {
        return;
      }
      setState(() => _applyCatalog(catalog, draft));
    } catch (_) {
      // The rest of the form still works if the bundled list cannot be read.
    }
  }

  @override
  void dispose() {
    _leaderName.dispose();
    _assemblyConstituency.dispose();
    _boothNumber.dispose();
    _boothName.dispose();
    _party.dispose();
    _designation.dispose();
    _contactNumber.dispose();
    super.dispose();
  }

  void _commit() {
    final draft = OnboardingScope.of(context).draft;
    draft
      ..leaderName = _leaderName.text.trim()
      ..assemblyConstituency = _assemblyConstituency.text.trim()
      ..boothNumber = _boothNumber.text.trim()
      ..boothName = _boothName.text.trim()
      ..party = _party.text.trim()
      ..designation = _designation.text.trim()
      ..contactNumber = _contactNumber.text.trim();
    if (draft.preferredLanguage.trim().isEmpty) {
      draft.preferredLanguage = _preferredLanguage;
    }
    final catalog = _catalog;
    if (catalog != null) {
      draft
        ..country = _selection.country
        ..stateRegion = _selection.state
        ..constituency = _selection.district;
    }
  }

  void _syncLocation(OnboardingDraft draft) {
    draft
      ..country = _selection.country
      ..stateRegion = _selection.state
      ..constituency = _selection.district;
  }

  void _selectCountry(String? value) {
    final draft = OnboardingScope.of(context).draft;
    setState(() {
      _selection.selectCountry(value);
      _locationIssue = null;
      _syncLocation(draft);
    });
  }

  void _selectState(String? value) {
    final draft = OnboardingScope.of(context).draft;
    setState(() {
      _selection.selectState(value);
      _locationIssue = null;
      _syncLocation(draft);
    });
  }

  void _selectDistrict(String? value) {
    final draft = OnboardingScope.of(context).draft;
    setState(() {
      _selection.selectDistrict(value);
      _locationIssue = null;
      _syncLocation(draft);
    });
  }

  void _saveAndContinue() {
    final l10n = AppLocalizations.of(context);
    final contactError =
        isValidContactNumber(_contactNumber.text) ? null : l10n.invalidContact;
    final catalog = _catalog;
    final locationIssue = catalog == null ? null : _selection.issue(catalog);
    if (contactError != null || locationIssue != null) {
      setState(() {
        _contactError = contactError;
        _locationIssue = locationIssue;
      });
      if (contactError != null) {
        _revealContact();
      }
      return;
    }
    _commit();
    AppRouter.open(context, AppRoutes.website);
  }

  void _revealContact() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = _contactAnchor.currentContext;
      if (target == null || !target.mounted) {
        return;
      }
      Scrollable.ensureVisible(
        target,
        alignment: 0.2,
        duration: const Duration(milliseconds: 200),
      );
    });
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.photoError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = OnboardingScope.of(context).draft;
    final photo = draft.photoBytes;
    final catalog = _catalog;
    final states =
        catalog == null
            ? const <String>[]
            : catalog.statesOf(_selection.country);
    final districts =
        catalog == null
            ? const <String>[]
            : catalog.districtsOf(_selection.country, _selection.state);
    final countryEnabled = catalog != null && catalog.countries.isNotEmpty;
    final stateEnabled =
        countryEnabled && _selection.country.isNotEmpty && states.isNotEmpty;
    final districtEnabled =
        stateEnabled && _selection.state.isNotEmpty && districts.isNotEmpty;
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
              controller: _leaderName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              onChanged: (value) => draft.leaderName = value,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.assemblyConstituency,
              controller: _assemblyConstituency,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (value) => draft.assemblyConstituency = value,
            ),
            const SizedBox(height: 14),
            AppTextField(
              key: const ValueKey('profilePartNo'),
              label: l10n.partNo,
              controller: _boothNumber,
              textInputAction: TextInputAction.next,
              onChanged: (value) => draft.boothNumber = value,
            ),
            const SizedBox(height: 14),
            AppTextField(
              key: const ValueKey('profilePartName'),
              label: l10n.partName,
              controller: _boothName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (value) => draft.boothName = value,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: l10n.organization,
              controller: _party,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.organizationName],
              onChanged: (value) => draft.party = value,
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
            _ProfileDropdown(
              fieldKey: const ValueKey('profileCountry'),
              label: l10n.country,
              hint: l10n.selectLanguage,
              value: _shown(_selection.country, catalog?.countries ?? const []),
              options: catalog?.countries ?? const [],
              enabled: countryEnabled,
              errorText:
                  _locationIssue == LocationIssue.country
                      ? l10n.invalidSelection
                      : null,
              onChanged: _selectCountry,
            ),
            const SizedBox(height: 14),
            _ProfileDropdown(
              fieldKey: const ValueKey('profileState'),
              label: l10n.stateRegion,
              hint: l10n.selectLanguage,
              value: _shown(_selection.state, states),
              options: states,
              enabled: stateEnabled,
              errorText:
                  _locationIssue == LocationIssue.state
                      ? l10n.invalidSelection
                      : null,
              onChanged: _selectState,
            ),
            const SizedBox(height: 14),
            _ProfileDropdown(
              fieldKey: const ValueKey('profileDistrict'),
              label: l10n.constituency,
              hint: l10n.selectLanguage,
              value: _shown(_selection.district, districts),
              options: districts,
              enabled: districtEnabled,
              errorText:
                  _locationIssue == LocationIssue.district
                      ? l10n.invalidSelection
                      : null,
              onChanged: _selectDistrict,
            ),
            const SizedBox(height: 14),
            KeyedSubtree(
              key: _contactAnchor,
              child: AppTextField(
                key: const ValueKey('profileContact'),
                label: l10n.publicContact,
                controller: _contactNumber,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                inputFormatters: [_phoneInput],
                errorText: _contactError,
                onChanged: (value) {
                  draft.contactNumber = value;
                  if (_contactError != null) {
                    final next =
                        isValidContactNumber(value)
                            ? null
                            : l10n.invalidContact;
                    if (next != _contactError) {
                      setState(() => _contactError = next);
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 22),
            OnboardingActions(
              backLabel: l10n.back,
              onBack: () {
                _commit();
                AppRouter.back(context, AppRoutes.login);
              },
              primaryLabel: l10n.saveAndContinue,
              onPrimary: _saveAndContinue,
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

  String? _shown(String current, List<String> options) {
    return options.contains(current) ? current : null;
  }
}

class _ProfileDropdown extends StatelessWidget {
  const _ProfileDropdown({
    required this.fieldKey,
    required this.label,
    required this.hint,
    required this.value,
    required this.options,
    required this.enabled,
    required this.onChanged,
    this.errorText,
  });

  final Key fieldKey;
  final String label;
  final String hint;
  final String? value;
  final List<String> options;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTextStyles.label(
            context,
          ).copyWith(fontSize: 13, color: context.palette.textMuted),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: fieldKey,
          value: value,
          isExpanded: true,
          hint: Text(hint),
          dropdownColor: context.palette.surfaceSecondary,
          menuMaxHeight: 320,
          decoration: InputDecoration(errorText: errorText),
          items: [
            for (final option in options)
              DropdownMenuItem<String>(
                value: option,
                child: Text(
                  option,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: enabled ? onChanged : null,
        ),
      ],
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
                  image:
                      bytes == null
                          ? null
                          : DecorationImage(
                            image: MemoryImage(bytes!),
                            fit: BoxFit.cover,
                          ),
                ),
                child:
                    bytes == null
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
