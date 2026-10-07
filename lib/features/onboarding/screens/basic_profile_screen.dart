import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/services/selfie_capture.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/contact_number.dart';
import '../data/location_catalog.dart';
import '../data/profile_languages.dart';
import '../data/profile_options.dart';
import '../data/location_selection.dart';
import '../models/onboarding_draft.dart';
import '../state/onboarding_controller.dart';
import '../data/political_party.dart';
import '../widgets/onboarding_frame.dart';
import '../widgets/party_symbol.dart';

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
        ProfileLanguages.supports(draft.preferredLanguage)
            ? draft.preferredLanguage
            : 'en';
    draft.preferredLanguage = _preferredLanguage;
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
    if (_selection.country.isEmpty && catalog.countries.contains('India')) {
      _selection.country = 'India';
    }
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

  Future<void> _choosePhotoSource() async {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final camera = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: palette.surface,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.photo_library_outlined,
                  color: palette.accent,
                ),
                title: Text(l10n.selectFromAlbum),
                onTap: () => Navigator.of(context).pop(false),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: palette.accent),
                title: Text(l10n.takeSelfie),
                onTap: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );
      },
    );
    if (camera == null || !mounted) {
      return;
    }
    await _pickPhoto(camera: camera);
  }

  Future<void> _pickPhoto({required bool camera}) async {
    final l10n = AppLocalizations.of(context);
    try {
      if (camera) {
        final bytes = await captureSelfie(context);
        if (bytes == null || !mounted) {
          return;
        }
        OnboardingScope.of(context).draft.photoBytes = bytes;
        setState(() {});
        return;
      }
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

  void _deletePhoto() {
    OnboardingScope.of(context).draft.photoBytes = null;
    setState(() {});
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
    final wideBooth = MediaQuery.sizeOf(context).width >= 560;
    final designations = ProfileOptions.withSaved(
      ProfileOptions.designations,
      _designation.text,
    );
    final parties = ProfileOptions.withSaved(
      ProfileOptions.parties,
      _party.text,
    );

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProfileHeader(
          l10n: l10n,
          onBack: () {
            _commit();
            AppRouter.back(context, AppRoutes.login);
          },
        ),
        const SizedBox(height: 16),
        _PhotoCard(
          title: l10n.profilePhotoTitle,
          hint: l10n.profilePhotoHint,
          takeLabel: l10n.takePhoto,
          deleteLabel: l10n.deletePhoto,
          bytes: photo,
          onAdd: _choosePhotoSource,
          onDelete: photo == null ? null : _deletePhoto,
        ),
        const SizedBox(height: 16),
        AppTextField(
          key: const ValueKey('profileLeaderName'),
          label: '${l10n.fullName} *',
          hint: l10n.enterFullName,
          prefixIcon: const Icon(Icons.person_outline),
          controller: _leaderName,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onChanged: (value) => draft.leaderName = value,
        ),
        const SizedBox(height: 14),
        _ProfileDropdown(
          fieldKey: const ValueKey('profileDesignation'),
          label: '${l10n.designation} *',
          hint: l10n.selectDesignation,
          icon: Icons.work_outline,
          value: _shown(_designation.text, designations),
          options: designations,
          enabled: true,
          onChanged: (value) {
            setState(() => _designation.text = value ?? '');
            draft.designation = _designation.text;
          },
        ),
        const SizedBox(height: 14),
        _ProfileDropdown(
          fieldKey: const ValueKey('profileParty'),
          label: '${l10n.organization} *',
          hint: l10n.selectParty,
          icon: Icons.flag_outlined,
          value: _shown(_party.text, parties),
          options: parties,
          showPartySymbols: true,
          nationalPartiesLabel: l10n.nationalParties,
          regionalPartiesLabel: l10n.regionalParties,
          enabled: true,
          onChanged: (value) {
            setState(() => _party.text = value ?? '');
            draft.party = _party.text;
          },
        ),
        const SizedBox(height: 16),
        _SectionCard(
          icon: Icons.location_on_outlined,
          title: l10n.locationSection,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileDropdown(
                fieldKey: const ValueKey('profileCountry'),
                label: '${l10n.country} *',
                hint: l10n.selectCountry,
                icon: Icons.public,
                value: _shown(
                  _selection.country,
                  catalog?.countries ?? const [],
                ),
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
                label: '${l10n.stateRegion} *',
                hint: l10n.selectState,
                icon: Icons.location_on_outlined,
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
                label: '${l10n.constituency} *',
                hint: l10n.selectDistrict,
                icon: Icons.account_balance_outlined,
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
              AppTextField(
                key: const ValueKey('profileAssembly'),
                label: '${l10n.assemblyConstituency} *',
                hint: l10n.selectConstituency,
                prefixIcon: const Icon(Icons.groups_outlined),
                controller: _assemblyConstituency,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                onChanged: (value) => draft.assemblyConstituency = value,
              ),
              const SizedBox(height: 14),
              if (wideBooth)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _boothNumberField(l10n, draft)),
                    const SizedBox(width: 12),
                    Expanded(child: _boothNameField(l10n, draft)),
                  ],
                )
              else ...[
                _boothNumberField(l10n, draft),
                const SizedBox(height: 14),
                _boothNameField(l10n, draft),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          icon: Icons.phone_outlined,
          title: l10n.contactSection,
          child: KeyedSubtree(
            key: _contactAnchor,
            child: AppTextField(
              key: const ValueKey('profileContact'),
              label: '${l10n.publicContact} *',
              hint: l10n.enterMobile,
              prefixIcon: const Icon(Icons.phone_outlined),
              controller: _contactNumber,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.telephoneNumber],
              inputFormatters: [_phoneInput],
              errorText: _contactError,
              onChanged: (value) {
                draft.contactNumber = value;
                if (_contactError != null) {
                  final next =
                      isValidContactNumber(value) ? null : l10n.invalidContact;
                  if (next != _contactError) {
                    setState(() => _contactError = next);
                  }
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  _commit();
                  AppRouter.back(context, AppRoutes.login);
                },
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.back),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _saveAndContinue,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.saveAndContinue),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        Center(
          child: TextButton(
            onPressed: () {
              _commit();
              AppRouter.open(context, AppRoutes.domain);
            },
            child: Text(l10n.skipForNow),
          ),
        ),
      ],
    );

    return OnboardingFrame(
      child: context.palette.isDark ? form : AppCard(child: form),
    );
  }

  Widget _boothNumberField(AppLocalizations l10n, OnboardingDraft draft) {
    return AppTextField(
      key: const ValueKey('profilePartNo'),
      label: '${l10n.partNo} *',
      hint: l10n.enterBoothNumber,
      prefixIcon: const Icon(Icons.tag),
      controller: _boothNumber,
      textInputAction: TextInputAction.next,
      onChanged: (value) => draft.boothNumber = value,
    );
  }

  Widget _boothNameField(AppLocalizations l10n, OnboardingDraft draft) {
    return AppTextField(
      key: const ValueKey('profilePartName'),
      label: '${l10n.partName} *',
      hint: l10n.enterBoothName,
      prefixIcon: const Icon(Icons.home_work_outlined),
      controller: _boothName,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      onChanged: (value) => draft.boothName = value,
    );
  }

  String? _shown(String current, List<String> options) {
    return options.contains(current) ? current : null;
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.l10n, required this.onBack});

  final AppLocalizations l10n;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              tooltip: l10n.back,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            ClipOval(
              child: Image.asset(
                AppAssets.logo,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.appName, style: AppTextStyles.wordmark(context)),
                  Text(
                    l10n.profilePlatform,
                    style: AppTextStyles.descriptor(context),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(l10n.basicProfile, style: AppTextStyles.headline(context)),
        const SizedBox(height: 4),
        Text(l10n.profileDescription, style: AppTextStyles.muted(context)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(icon, color: palette.accent, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.headline(
                      context,
                    ).copyWith(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.title,
    required this.hint,
    required this.takeLabel,
    required this.deleteLabel,
    required this.onAdd,
    required this.onDelete,
    this.bytes,
  });

  final String title;
  final String hint;
  final String takeLabel;
  final String deleteLabel;
  final Uint8List? bytes;
  final VoidCallback onAdd;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 92,
              height: 92,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.background,
                      border: Border.all(color: palette.accent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: palette.accent.withValues(alpha: 0.35),
                          blurRadius: 12,
                        ),
                      ],
                      image:
                          bytes == null
                              ? null
                              : DecorationImage(
                                image: MemoryImage(bytes!),
                                fit: BoxFit.cover,
                              ),
                    ),
                    child: SizedBox(
                      width: 92,
                      height: 92,
                      child:
                          bytes == null
                              ? Icon(
                                Icons.person,
                                size: 40,
                                color: palette.textMuted,
                              )
                              : null,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: palette.accent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onAdd,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.photo_camera,
                            size: 14,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.headline(
                      context,
                    ).copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(hint, style: AppTextStyles.muted(context)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.photo_camera_outlined, size: 16),
                        label: Text(takeLabel),
                      ),
                      OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: Text(deleteLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileDropdown extends StatelessWidget {
  const _ProfileDropdown({
    required this.fieldKey,
    required this.label,
    required this.hint,
    required this.icon,
    required this.value,
    required this.options,
    required this.enabled,
    required this.onChanged,
    this.errorText,
    this.showPartySymbols = false,
    this.nationalPartiesLabel = '',
    this.regionalPartiesLabel = '',
  });

  final Key fieldKey;
  final String label;
  final String hint;
  final IconData icon;
  final String? value;
  final List<String> options;
  final bool enabled;
  final String? errorText;
  final ValueChanged<String?> onChanged;
  final bool showPartySymbols;
  final String nationalPartiesLabel;
  final String regionalPartiesLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTextStyles.label(
            context,
          ).copyWith(fontSize: 13, color: palette.text),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          key: fieldKey,
          value: value,
          isExpanded: true,
          hint: Text(hint),
          icon: Icon(Icons.keyboard_arrow_down, color: palette.textMuted),
          dropdownColor: palette.surfaceSecondary,
          menuMaxHeight: MediaQuery.sizeOf(context).height * 0.5,
          itemHeight: showPartySymbols ? 56 : kMinInteractiveDimension,
          decoration: InputDecoration(
            prefixIcon:
                showPartySymbols ? null : Icon(icon, color: palette.textMuted),
            errorText: errorText,
          ),
          items:
              showPartySymbols
                  ? _partyMenuItems(
                    options,
                    nationalPartiesLabel,
                    regionalPartiesLabel,
                    palette,
                  )
                  : [
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

class _PartyOptionLabel extends StatelessWidget {
  const _PartyOptionLabel({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PartySymbol(name),
        const SizedBox(width: PartySymbol.gap),
        Expanded(
          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

List<DropdownMenuItem<String>> _partyMenuItems(
  List<String> options,
  String nationalLabel,
  String regionalLabel,
  AppPalette palette,
) {
  final known = options.toSet();
  final saved =
      options.where((name) => PartyOption.findByName(name) == null).toList();

  DropdownMenuItem<String> party(String name) {
    return DropdownMenuItem<String>(
      value: name,
      child: _PartyOptionLabel(name: name),
    );
  }

  DropdownMenuItem<String> header(String id, String label) {
    return DropdownMenuItem<String>(
      enabled: false,
      value: id,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: palette.textMuted,
        ),
      ),
    );
  }

  return [
    for (final name in saved) party(name),
    if (PartyOption.national.any((party) => known.contains(party.name)))
      header('__national_parties__', nationalLabel),
    for (final partyOption in PartyOption.national)
      if (known.contains(partyOption.name)) party(partyOption.name),
    if (PartyOption.regional.any((party) => known.contains(party.name)))
      header('__regional_parties__', regionalLabel),
    for (final partyOption in PartyOption.regional)
      if (known.contains(partyOption.name)) party(partyOption.name),
  ];
}
