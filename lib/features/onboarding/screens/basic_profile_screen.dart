import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/services/auth_browser.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/utils/person_name.dart';
import '../../../core/services/selfie_capture.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/theme_toggle.dart';
import '../../website/services/portfolio_store.dart';
import '../../website/services/website_builder_store.dart';
import '../data/assembly_constituency.dart';
import '../data/contact_number.dart';
import '../data/location_catalog.dart';
import '../data/state_search.dart';
import '../data/profile_languages.dart';
import '../data/profile_options.dart';
import '../../privacy/legal_consent_line.dart';
import '../data/location_selection.dart';
import '../models/onboarding_draft.dart';
import '../state/onboarding_controller.dart';
import '../data/political_party.dart';
import '../widgets/assembly_constituency_field.dart';
import '../widgets/party_symbol.dart';
import '../widgets/searchable_state_dropdown.dart';

class BasicProfileScreen extends StatefulWidget {
  const BasicProfileScreen({super.key});

  @override
  State<BasicProfileScreen> createState() => _BasicProfileScreenState();
}

class _BasicProfileScreenState extends State<BasicProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  final _contactAnchor = GlobalKey();
  static const _phoneInput = IndianMobileNumberFormatter();
  final _selection = LocationSelection();
  var _ready = false;

  late final TextEditingController _leaderName;
  late final TextEditingController _email;
  late final TextEditingController _boothNumber;
  late final TextEditingController _boothName;
  late final TextEditingController _party;
  late final TextEditingController _designation;
  late final TextEditingController _contactNumber;
  late String _preferredLanguage;

  LocationCatalog? _catalog;
  String? _nameError;
  String? _partyError;
  String? _designationError;
  String? _countryError;
  String? _stateError;
  String? _districtError;
  String? _assemblyError;
  String? _boothNumberError;
  String? _boothNameError;
  String? _contactError;

  static const _fillFirst = 'Fill this field first';

  final _nameAnchor = GlobalKey();
  final _partyAnchor = GlobalKey();
  final _designationAnchor = GlobalKey();
  final _countryAnchor = GlobalKey();
  final _stateAnchor = GlobalKey();
  final _districtAnchor = GlobalKey();
  final _assemblyAnchor = GlobalKey();
  final _boothNumberAnchor = GlobalKey();
  final _boothNameAnchor = GlobalKey();

  /// Facebook name placed in the field before a saved profile comes back.
  String? _socialNamePrefill;

  /// Bumped when the user skips so a late GET /api/profile cannot fill the draft.
  int _profileLoadToken = 0;
  var _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) {
      return;
    }
    final draft = OnboardingScope.of(context).draft;
    if (draft.leaderName.trim().isEmpty) {
      final socialName = _accountDisplayName();
      if (socialName.isNotEmpty) {
        draft.leaderName = socialName;
        _socialNamePrefill = socialName;
      }
    }
    _leaderName = TextEditingController(text: draft.leaderName);
    _email = TextEditingController(
      text: AuthService.instance.session?.email.trim() ?? '',
    );
    _boothNumber = TextEditingController(text: draft.boothNumber);
    _boothName = TextEditingController(text: draft.boothName);
    _party = TextEditingController(text: draft.party);
    _designation = TextEditingController(text: draft.designation);
    final loginPhone = AuthService.instance.session?.phone ?? '';
    if (draft.contactNumber.trim().isEmpty && loginPhone.isNotEmpty) {
      draft.contactNumber = loginPhone;
    }
    _contactNumber = TextEditingController(
      text: extractIndianNationalNumber(draft.contactNumber),
    );
    _preferredLanguage =
        ProfileLanguages.supports(draft.preferredLanguage)
            ? draft.preferredLanguage
            : 'en';
    draft.preferredLanguage = _preferredLanguage;
    if (draft.email.trim().isEmpty) {
      draft.email = _email.text.trim();
    }
    _ready = true;
    unawaited(_prepareProfile(draft));
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

  Future<void> _prepareProfile(OnboardingDraft draft) async {
    final pending = AuthService.instance.takeSocialReturn();
    final error =
        pending.error ??
        AuthService.instance.socialLaunchError ??
        takeSessionValue('vb_auth_error');
    final ticket =
        (pending.ticket != null && pending.ticket!.isNotEmpty)
            ? pending.ticket
            : takeSessionValue('vb_auth_ticket');
    if (error != null && error.isNotEmpty) {
      AuthService.instance.socialLaunchError = null;
    }
    // #region agent log
    _profileDebugLog('C', 'leader profile social return', {
      'hasTicket': ticket != null && ticket.isNotEmpty,
      'hasError': error != null && error.isNotEmpty,
      'sessionEmailLength':
          (AuthService.instance.session?.email ?? '').trim().length,
      'sessionNameLength':
          (AuthService.instance.session?.fullName ?? '').trim().length,
    });
    // #endregion
    if ((ticket != null && ticket.isNotEmpty) ||
        (error != null && error.isNotEmpty)) {
      clearAuthQuery();
    }
    if (error != null && error.isNotEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-in failed. Please try again.'),
        ),
      );
      return;
    }
    if (ticket != null && ticket.isNotEmpty) {
      try {
        await AuthService.instance.exchangeSocialTicket(ticket);
      } on AuthException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
        return;
      }
      final fullName = _accountDisplayName();
      final email = AuthService.instance.session?.email.trim() ?? '';
      if (fullName.isNotEmpty && draft.leaderName.trim().isEmpty) {
        draft.leaderName = fullName;
        _socialNamePrefill ??= fullName;
      }
      if (_email.text.trim().isEmpty && email.isNotEmpty) {
        _email.text = email;
      }
      // #region agent log
      _profileDebugLog('D', 'profile after google ticket', {
        'hasSessionEmail': email.isNotEmpty,
        'sessionEmailLength': email.length,
        'hasSessionName': fullName.isNotEmpty,
        'sessionNameLength': fullName.length,
        'draftNameLength': draft.leaderName.trim().length,
        'emailFieldLength': _email.text.trim().length,
      });
      // #endregion
    }
    if (!mounted) return;
    if (_leaderName.text.trim().isEmpty && draft.leaderName.isNotEmpty) {
      setState(() => _leaderName.text = draft.leaderName);
    }
    await _loadSavedProfile(draft);
  }

  Future<void> _loadSavedProfile(OnboardingDraft draft) async {
    final loadToken = _profileLoadToken;
    // Guest "Skip for now" from login must not pull another account's profile.
    if (OnboardingScope.of(context).ignoreStoredWebsiteDrafts ||
        !AuthService.instance.isSignedIn) {
      return;
    }
    final profile = await ProfileService.instance.fetchProfile();
    if (!mounted || loadToken != _profileLoadToken) return;
    if (OnboardingScope.of(context).ignoreStoredWebsiteDrafts) return;
    final boothNumber = _boothNumber.text;
    final boothName = _boothName.text;
    final typedName = _leaderName.text.trim();
    final untouchedPrefill =
        typedName.isEmpty || typedName == _socialNamePrefill;
    if (untouchedPrefill) {
      // Let a name the leader already saved replace the Facebook prefill.
      draft.leaderName = '';
    }
    if (profile != null) {
      ProfileService.applyProfile(draft, profile);
    }
    final socialName = _accountDisplayName();
    final savedName =
        profile != null && profile['full_name'] is String
            ? (profile['full_name'] as String).trim()
            : '';
    if (draft.leaderName.trim().isEmpty && socialName.isNotEmpty) {
      draft.leaderName = socialName;
    }
    final sessionEmail = AuthService.instance.session?.email.trim() ?? '';
    if (_email.text.trim().isEmpty && sessionEmail.isNotEmpty) {
      _email.text = sessionEmail;
    }
    if (savedName.isEmpty && draft.leaderName.trim().isNotEmpty) {
      await ProfileService.instance.saveDraft(draft);
    }
    if (!mounted) return;
    if (untouchedPrefill &&
        draft.leaderName.isNotEmpty &&
        _leaderName.text.trim() != draft.leaderName) {
      _leaderName.text = draft.leaderName;
    }
    // #region agent log
    _profileDebugLog('B', 'saved profile applied to leader form', {
      'profileLoaded': profile != null,
      'savedNameLength':
          profile == null
              ? 0
              : (profile['full_name'] is String
                  ? (profile['full_name'] as String).trim().length
                  : 0),
      'profileHasEmailKey': profile != null && profile.containsKey('email'),
      'draftNameLength': draft.leaderName.trim().length,
      'fieldNameLength': _leaderName.text.trim().length,
      'emailFieldLength': _email.text.trim().length,
      'sessionEmailLength':
          (AuthService.instance.session?.email ?? '').trim().length,
    });
    // #endregion
    if (profile == null) {
      await _applyGooglePhoto(draft);
      if (!mounted) return;
      setState(() {
        if (untouchedPrefill && draft.leaderName.isNotEmpty) {
          _leaderName.text = draft.leaderName;
        }
        if (_email.text.trim().isEmpty && sessionEmail.isNotEmpty) {
          _email.text = sessionEmail;
        }
      });
      return;
    }
    OnboardingScope.of(context).syncLocaleFromDraft();
    if (ProfileLanguages.supports(draft.preferredLanguage)) {
      _preferredLanguage = draft.preferredLanguage;
    }
    final photoUrl = draft.profilePhotoUrl;
    if (photoUrl.isNotEmpty &&
        draft.photoBytes == null &&
        !draft.photoRemoved) {
      final bytes = await ProfileService.instance.downloadPhoto(photoUrl);
      if (!mounted || draft.photoRemoved || draft.photoPendingUpload) return;
      if (bytes != null) draft.photoBytes = bytes;
    } else {
      await _applyGooglePhoto(draft);
    }
    if (!mounted) return;
    setState(() {
      if (boothNumber.trim().isEmpty && draft.boothNumber.isNotEmpty) {
        _boothNumber.text = draft.boothNumber;
      }
      if (boothName.trim().isEmpty && draft.boothName.isNotEmpty) {
        _boothName.text = draft.boothName;
      }
      if (_leaderName.text.trim().isEmpty && draft.leaderName.isNotEmpty) {
        _leaderName.text = draft.leaderName;
      }
      final sessionEmail = AuthService.instance.session?.email.trim() ?? '';
      if (_email.text.trim().isEmpty && sessionEmail.isNotEmpty) {
        _email.text = sessionEmail;
      }
      if (_party.text.trim().isEmpty && draft.party.isNotEmpty) {
        _party.text = draft.party;
      }
      if (_designation.text.trim().isEmpty && draft.designation.isNotEmpty) {
        _designation.text = draft.designation;
      }
      if (_email.text.trim().isEmpty && draft.email.trim().isNotEmpty) {
        _email.text = draft.email.trim();
      }
      if (_contactNumber.text.trim().isEmpty &&
          draft.contactNumber.isNotEmpty) {
        _contactNumber.text = extractIndianNationalNumber(draft.contactNumber);
      }
      final catalog = _catalog;
      if (catalog != null) {
        _selection.restore(
          catalog: catalog,
          country: draft.country,
          state: draft.stateRegion,
          district: draft.constituency,
        );
      }
    });
  }

  /// Google display name, or the fetched email when Google sends no name.
  String _accountDisplayName() {
    final named = formatPersonName(
      AuthService.instance.session?.fullName ?? '',
    );
    if (named.isNotEmpty) return named;
    return AuthService.instance.session?.email.trim() ?? '';
  }

  Future<void> _applyGooglePhoto(OnboardingDraft draft) async {
    if (draft.photoBytes != null ||
        draft.profilePhotoUrl.isNotEmpty ||
        draft.photoRemoved) {
      return;
    }
    final avatar = AuthService.instance.session?.avatarUrl.trim() ?? '';
    if (!avatar.startsWith('https://')) return;
    final bytes = await ProfileService.instance.downloadPhoto(avatar);
    if (bytes == null ||
        !mounted ||
        draft.photoRemoved ||
        draft.photoBytes != null) {
      return;
    }
    draft
      ..photoBytes = bytes
      ..photoPendingUpload = true;
    await ProfileService.instance.saveDraft(draft);
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

  // #region agent log
  void _profileDebugLog(
    String hypothesisId,
    String message,
    Map<String, Object?> data,
  ) {
    http
        .post(
          Uri.parse(
            'http://127.0.0.1:7337/ingest/75959716-472f-4d0f-8b88-2b7d19c8618c',
          ),
          headers: const {
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': '6d3aea',
          },
          body: jsonEncode({
            'sessionId': '6d3aea',
            'runId': 'pre-fix',
            'hypothesisId': hypothesisId,
            'location': 'basic_profile_screen.dart',
            'message': message,
            'data': data,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }),
        )
        .timeout(const Duration(seconds: 2))
        .catchError((_) => http.Response('', 599));
  }
  // #endregion

  @override
  void dispose() {
    _leaderName.dispose();
    _email.dispose();
    _boothNumber.dispose();
    _boothName.dispose();
    _party.dispose();
    _designation.dispose();
    _contactNumber.dispose();
    super.dispose();
  }

  void _commit() {
    final draft = OnboardingScope.of(context).draft;
    final nextName = _leaderName.text.trim();
    final previousName = draft.leaderName.trim();
    final query = draft.domainQuery.trim();
    // Keep a website name the user typed themselves. Otherwise the search
    // follows the name from this form, including when that name changes.
    if (query.isEmpty || query == previousName) {
      if (query != nextName) {
        draft.selectedDomain = null;
      }
      draft.domainQuery = nextName;
    }
    draft
      ..leaderName = nextName
      ..assemblyConstituency = draft.assemblyConstituency.trim()
      ..boothNumber = _boothNumber.text.trim()
      ..boothName = _boothName.text.trim()
      ..party = _party.text.trim()
      ..designation = _designation.text.trim()
      ..email = _email.text.trim()
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
      _countryError = null;
      _syncLocation(draft);
    });
  }

  void _selectState(String? value) {
    final draft = OnboardingScope.of(context).draft;
    final previous = _selection.state;
    setState(() {
      _selection.selectState(value);
      _stateError = null;
      if (_selection.state != previous) {
        _clearAssembly(draft);
      }
      _syncLocation(draft);
    });
  }

  void _clearAssembly(OnboardingDraft draft) {
    draft
      ..assemblyConstituency = ''
      ..assemblyConstituencyId = null;
  }

  void _selectDistrict(String? value) {
    final draft = OnboardingScope.of(context).draft;
    final previous = _selection.district;
    setState(() {
      _selection.selectDistrict(value);
      _districtError = null;
      if (_selection.district != previous) {
        _clearAssembly(draft);
      }
      _syncLocation(draft);
    });
  }

  String? _choiceError(String current, List<String> options) {
    return _shown(current, options) == null ? _fillFirst : null;
  }

  String? _placeError({
    required String value,
    required LocationIssue field,
    required LocationIssue? invalid,
    required String invalidMessage,
  }) {
    if (value.trim().isEmpty) return _fillFirst;
    if (invalid == field) return invalidMessage;
    return null;
  }

  Future<void> _saveAndContinue() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final draft = OnboardingScope.of(context).draft;
    final catalog = _catalog;
    final parties = ProfileOptions.withSaved(
      ProfileOptions.parties,
      _party.text,
    );
    final designations = ProfileOptions.withSaved(
      ProfileOptions.designations,
      _designation.text,
    );
    final invalid = catalog == null ? null : _selection.issue(catalog);
    final contactText = _contactNumber.text.trim();
    final nameError = _leaderName.text.trim().isEmpty ? _fillFirst : null;
    final partyError = _choiceError(_party.text, parties);
    final designationError = _choiceError(_designation.text, designations);
    final countryError = _placeError(
      value: _selection.country,
      field: LocationIssue.country,
      invalid: invalid,
      invalidMessage: l10n.invalidSelection,
    );
    final stateError = _placeError(
      value: _selection.state,
      field: LocationIssue.state,
      invalid: invalid,
      invalidMessage: l10n.invalidSelection,
    );
    final districtError = _placeError(
      value: _selection.district,
      field: LocationIssue.district,
      invalid: invalid,
      invalidMessage: l10n.invalidSelection,
    );
    final assemblyError =
        draft.assemblyConstituency.trim().isEmpty ? _fillFirst : null;
    final boothNumberError =
        _boothNumber.text.trim().isEmpty ? _fillFirst : null;
    final boothNameError = _boothName.text.trim().isEmpty ? _fillFirst : null;
    final contactError =
        contactText.isEmpty
            ? _fillFirst
            : (isValidContactNumber(contactText) ? null : l10n.invalidContact);
    final missing = <(GlobalKey, String?)>[
      (_nameAnchor, nameError),
      (_partyAnchor, partyError),
      (_designationAnchor, designationError),
      (_countryAnchor, countryError),
      (_stateAnchor, stateError),
      (_districtAnchor, districtError),
      (_assemblyAnchor, assemblyError),
      (_boothNumberAnchor, boothNumberError),
      (_boothNameAnchor, boothNameError),
      (_contactAnchor, contactError),
    ].where((entry) => entry.$2 != null);

    setState(() {
      _nameError = nameError;
      _partyError = partyError;
      _designationError = designationError;
      _countryError = countryError;
      _stateError = stateError;
      _districtError = districtError;
      _assemblyError = assemblyError;
      _boothNumberError = boothNumberError;
      _boothNameError = boothNameError;
      _contactError = contactError;
    });
    if (missing.isNotEmpty) {
      _reveal(missing.first.$1);
      return;
    }
    setState(() => _saving = true);
    _commit();
    if (AuthService.instance.isSignedIn) {
      final saved = await ProfileService.instance.saveDraft(draft);
      if (!mounted) return;
      if (!saved) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile could not be saved. Please try again.'),
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() => _saving = false);
    AppRouter.open(context, AppRoutes.additionalProfile);
  }

  /// Leave the leader profile empty and continue. Drops auto-fetched or typed
  /// values for this step, and blocks cached website drafts from filling them
  /// back in on the next screens.
  void _skipForNow() {
    _profileLoadToken++;
    final onboarding = OnboardingScope.of(context);
    onboarding.clearForGuestSkip();
    // A signed-in skip must not save the cleared draft back to that account.
    AuthService.instance.openProfileAfterLogin = false;
    AuthService.instance.session = null;
    unawaited(AuthService.instance.signOut());
    unawaited(WebsiteBuilderStore.instance.clearLocal());
    unawaited(PortfolioStore.instance.clear());
    AppRouter.open(context, AppRoutes.website);
  }

  void _reveal(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = key.currentContext;
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

  Widget _buildPhonePrefix(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 14),
        Icon(Icons.phone_outlined, color: palette.textMuted),
        const SizedBox(width: 8),
        Text(
          '+91',
          style: AppTextStyles.body(
            context,
          ).copyWith(color: palette.text, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Container(width: 1, height: 20, color: palette.border),
        const SizedBox(width: 10),
      ],
    );
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
      final Uint8List? bytes;
      if (camera) {
        bytes = await captureSelfie(context);
      } else {
        final file = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          imageQuality: 85,
          requestFullMetadata: false,
        );
        bytes = file == null ? null : await file.readAsBytes();
      }
      if (bytes == null || !mounted) {
        return;
      }
      if (bytes.length > ProfileService.maxPhotoBytes ||
          ProfileService.photoContentType(bytes) == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.photoError)));
        return;
      }
      final draft = OnboardingScope.of(context).draft;
      draft
        ..photoBytes = bytes
        ..photoPendingUpload = true
        ..photoRemoved = false;
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
    final draft = OnboardingScope.of(context).draft;
    draft
      ..photoBytes = null
      ..profilePhotoUrl = ''
      ..photoPendingUpload = false
      ..photoRemoved = true;
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
    final designations = ProfileOptions.withSaved(
      ProfileOptions.designations,
      _designation.text,
    );
    final parties = ProfileOptions.withSaved(
      ProfileOptions.parties,
      _party.text,
    );

    final nameField = KeyedSubtree(
      key: _nameAnchor,
      child: AppTextField(
        key: const ValueKey('profileLeaderName'),
        label: '${l10n.fullName} *',
        hint: l10n.enterFullName,
        prefixIcon: const Icon(Icons.person_outline),
        controller: _leaderName,
        textCapitalization: TextCapitalization.words,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.name],
        errorText: _nameError,
        onChanged: (value) {
          draft.leaderName = value;
          if (_nameError != null && value.trim().isNotEmpty) {
            setState(() => _nameError = null);
          }
        },
      ),
    );
    final emailField = AppTextField(
      key: const ValueKey('profileEmail'),
      label: l10n.emailAddress,
      hint: l10n.emailAddress,
      prefixIcon: const Icon(Icons.mail_outline),
      controller: _email,
      readOnly: true,
      keyboardType: TextInputType.emailAddress,
    );
    final partyField = KeyedSubtree(
      key: _partyAnchor,
      child: _ProfileDropdown(
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
        searchable: true,
        searchHint: 'Search party',
        noResultsLabel: 'No results found',
        clearSearchLabel: l10n.clearStateSearch,
        prepareOptions: (options) => options,
        searchFieldKey: const ValueKey('partySearch'),
        clearButtonKey: const ValueKey('clearPartySearch'),
        emptyMessageKey: const ValueKey('noPartiesFound'),
        listKey: const ValueKey('partyMenuList'),
        filterOptions: (options, query) {
          final q = query.trim().toLowerCase();
          if (q.isEmpty) return options;
          return options.where((name) {
            final party = PartyOption.findByName(name);
            if (party != null) {
              return party.name.toLowerCase().contains(q) ||
                  party.abbreviation.toLowerCase().contains(q);
            }
            return name.toLowerCase().contains(q);
          }).toList();
        },
        onChanged: (value) {
          setState(() {
            _party.text = value ?? '';
            if (_party.text.trim().isNotEmpty) _partyError = null;
          });
          draft.party = _party.text;
        },
        errorText: _partyError,
      ),
    );
    final designationField = KeyedSubtree(
      key: _designationAnchor,
      child: _ProfileDropdown(
        fieldKey: const ValueKey('profileDesignation'),
        label: '${l10n.designation} *',
        hint: l10n.selectDesignation,
        icon: Icons.work_outline,
        value: _shown(_designation.text, designations),
        options: designations,
        enabled: true,
        searchable: true,
        searchHint: 'Search designation',
        noResultsLabel: 'No results found',
        clearSearchLabel: l10n.clearStateSearch,
        prepareOptions: (options) => options,
        searchFieldKey: const ValueKey('designationSearch'),
        clearButtonKey: const ValueKey('clearDesignationSearch'),
        emptyMessageKey: const ValueKey('noDesignationsFound'),
        listKey: const ValueKey('designationMenuList'),
        filterOptions: (options, query) {
          final q = query.trim().toLowerCase();
          if (q.isEmpty) return options;
          return options.where((o) => o.toLowerCase().contains(q)).toList();
        },
        onChanged: (value) {
          setState(() {
            _designation.text = value ?? '';
            if (_designation.text.trim().isNotEmpty) _designationError = null;
          });
          draft.designation = _designation.text;
        },
        errorText: _designationError,
      ),
    );
    final countryField = KeyedSubtree(
      key: _countryAnchor,
      child: _ProfileDropdown(
        fieldKey: const ValueKey('profileCountry'),
        label: '${l10n.country} *',
        hint: l10n.selectCountry,
        icon: Icons.public,
        value: _shown(_selection.country, catalog?.countries ?? const []),
        options: catalog?.countries ?? const [],
        enabled: countryEnabled,
        errorText: _countryError,
        onChanged: _selectCountry,
      ),
    );
    final stateField = KeyedSubtree(
      key: _stateAnchor,
      child: _ProfileDropdown(
        fieldKey: const ValueKey('profileState'),
        label: '${l10n.stateRegion} *',
        hint: l10n.selectState,
        icon: Icons.location_on_outlined,
        value: _shown(_selection.state, states),
        options: states,
        enabled: stateEnabled,
        searchable: true,
        searchHint: l10n.searchStates,
        noResultsLabel: l10n.noStatesFound,
        clearSearchLabel: l10n.clearStateSearch,
        errorText: _stateError,
        onChanged: _selectState,
      ),
    );
    final districtField = KeyedSubtree(
      key: _districtAnchor,
      child: _ProfileDropdown(
        fieldKey: const ValueKey('profileDistrict'),
        label: '${l10n.constituency} *',
        hint: l10n.selectDistrict,
        icon: Icons.account_balance_outlined,
        value: _shown(_selection.district, districts),
        options: districts,
        enabled: districtEnabled,
        searchable: true,
        searchHint: l10n.searchDistricts,
        noResultsLabel: l10n.noDistrictsFound,
        clearSearchLabel: l10n.clearStateSearch,
        prepareOptions: uniqueNames,
        searchFieldKey: const ValueKey('districtSearch'),
        clearButtonKey: const ValueKey('clearDistrictSearch'),
        emptyMessageKey: const ValueKey('noDistrictsFound'),
        listKey: const ValueKey('districtMenuList'),
        errorText: _districtError,
        onChanged: _selectDistrict,
      ),
    );
    final photoCard = _PhotoCard(
      title: l10n.profilePhotoTitle,
      hint: l10n.profilePhotoHint,
      takeLabel: l10n.takePhoto,
      deleteLabel: l10n.deletePhoto,
      bytes: photo,
      onAdd: _choosePhotoSource,
      onDelete: photo == null ? null : _deletePhoto,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 48 || constraints.maxHeight < 48) {
          return const SizedBox.shrink();
        }
        final wide = constraints.maxWidth >= 760;
        final desktop = constraints.maxWidth >= 1100;
        final palette = context.palette;
        final page =
            palette.isDark ? palette.background : const Color(0xFFF5F8FC);
        final gap = wide ? 16.0 : 14.0;
        Widget pair(Widget left, Widget right) {
          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [left, SizedBox(height: gap), right],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              SizedBox(width: gap),
              Expanded(child: right),
            ],
          );
        }

        return Scaffold(
          backgroundColor: page,
          body: SafeArea(
            child: Column(
              children: [
                _ProfileTopBar(
                  l10n: l10n,
                  photo: photo,
                  onBack: () {
                    _commit();
                    AppRouter.back(context, AppRoutes.login);
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      wide ? 28 : 16,
                      4,
                      wide ? 28 : 16,
                      32,
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: Theme.of(
                          context,
                        ).inputDecorationTheme.copyWith(
                          filled: true,
                          fillColor:
                              palette.isDark
                                  ? palette.surfaceSecondary
                                  : const Color(0xFFF7FAFE),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE3EDF6),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE3EDF6),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1200),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                height: wide ? 148 : 124,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: const [_LeaderBackdrop()],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.fromLTRB(
                                  wide ? 8 : 2,
                                  0,
                                  wide ? 8 : 2,
                                  16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 18),
                                    Text(
                                      l10n.basicProfile,
                                      style: TextStyle(
                                        fontSize: wide ? 30 : 24,
                                        height: 1.15,
                                        fontWeight: FontWeight.w800,
                                        color:
                                            palette.isDark
                                                ? palette.text
                                                : const Color(0xFF102A56),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      l10n.profileDescription,
                                      style: TextStyle(
                                        color: palette.textMuted,
                                        fontSize: wide ? 15 : 14,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 36,
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              wide
                                  ? IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(flex: 3, child: photoCard),
                                        SizedBox(width: gap),
                                        const Expanded(
                                          flex: 2,
                                          child: _QuoteCard(),
                                        ),
                                      ],
                                    ),
                                  )
                                  : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      photoCard,
                                      SizedBox(height: gap),
                                      const _QuoteCard(),
                                    ],
                                  ),
                              SizedBox(height: gap),
                              _SectionCard(
                                icon: Icons.badge_outlined,
                                title: l10n.line('personalInformation'),
                                subtitle: l10n.line('personalInformationBody'),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    pair(nameField, emailField),
                                    SizedBox(height: gap),
                                    pair(partyField, designationField),
                                  ],
                                ),
                              ),
                              SizedBox(height: gap),
                              _SectionCard(
                                icon: Icons.location_on_outlined,
                                title: l10n.locationSection,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    desktop
                                        ? Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(child: countryField),
                                            const SizedBox(width: 12),
                                            Expanded(child: stateField),
                                            const SizedBox(width: 12),
                                            Expanded(child: districtField),
                                          ],
                                        )
                                        : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            countryField,
                                            const SizedBox(height: 12),
                                            stateField,
                                            const SizedBox(height: 12),
                                            districtField,
                                          ],
                                        ),
                                    const SizedBox(height: 14),
                                    KeyedSubtree(
                                      key: _assemblyAnchor,
                                      child: _assemblyField(l10n, draft),
                                    ),
                                    const SizedBox(height: 14),
                                    pair(
                                      KeyedSubtree(
                                        key: _boothNumberAnchor,
                                        child: _boothNumberField(l10n, draft),
                                      ),
                                      KeyedSubtree(
                                        key: _boothNameAnchor,
                                        child: _boothNameField(l10n, draft),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: gap),
                              _SectionCard(
                                icon: Icons.phone_outlined,
                                title: l10n.contactSection,
                                child: KeyedSubtree(
                                  key: _contactAnchor,
                                  child: AppTextField(
                                    key: const ValueKey('profileContact'),
                                    label: '${l10n.publicContact} *',
                                    hint: 'Enter 10-digit mobile number',
                                    prefixIcon: _buildPhonePrefix(context),
                                    controller: _contactNumber,
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.done,
                                    autofillHints: const [
                                      AutofillHints.telephoneNumber,
                                    ],
                                    inputFormatters: const [_phoneInput],
                                    errorText: _contactError,
                                    onChanged: (value) {
                                      draft.contactNumber = value;
                                      if (_contactError == null) return;
                                      final text = value.trim();
                                      final next =
                                          text.isEmpty
                                              ? _fillFirst
                                              : (isValidContactNumber(text)
                                                  ? null
                                                  : l10n.invalidContact);
                                      if (next != _contactError) {
                                        setState(() => _contactError = next);
                                      }
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),
                              const LegalConsentLine(),
                              const SizedBox(height: 12),
                              Center(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: wide ? 320 : double.infinity,
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF2563EB),
                                          Color(0xFF10B981),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x262563EB),
                                          blurRadius: 14,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: FilledButton(
                                      style: FilledButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        disabledBackgroundColor:
                                            Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(52),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      onPressed:
                                          _saving ? null : _saveAndContinue,
                                      child:
                                          _saving
                                              ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.4,
                                                      color: Colors.white,
                                                    ),
                                              )
                                              : Text(l10n.saveAndContinue),
                                    ),
                                  ),
                                ),
                              ),
                              Center(
                                child: TextButton(
                                  onPressed: _skipForNow,
                                  child: Text(l10n.skipForNow),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _assemblyField(AppLocalizations l10n, OnboardingDraft draft) {
    final districtSelected = _selection.district.isNotEmpty;
    final saved = draft.assemblyConstituency.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${l10n.assemblyConstituency} *',
          style: AppTextStyles.label(
            context,
          ).copyWith(fontSize: 13, color: context.palette.text),
        ),
        const SizedBox(height: 8),
        AssemblyConstituencyField(
          fieldKey: const ValueKey('profileAssembly'),
          value: saved.isEmpty ? null : saved,
          enabled: districtSelected,
          stateName: _selection.state,
          districtName: _selection.district,
          hint: l10n.selectConstituency,
          manualHint: l10n.enterAssemblyConstituency,
          searchHint: l10n.searchConstituencies,
          noResultsLabel: l10n.noConstituenciesFound,
          clearSearchLabel: l10n.clearStateSearch,
          loadingLabel: l10n.loadingAssemblyConstituencies,
          onLoad:
              () => AssemblyConstituencies.load(
                state: _selection.state,
                district: _selection.district,
              ),
          errorText: _assemblyError,
          onChanged: (item) {
            if (item == null) return;
            setState(() {
              draft
                ..assemblyConstituency = item.label
                ..assemblyConstituencyId = item.id;
              _assemblyError = null;
            });
          },
          onTyped: (text) {
            draft
              ..assemblyConstituency = text
              ..assemblyConstituencyId = null;
            if (_assemblyError != null && text.trim().isNotEmpty) {
              setState(() => _assemblyError = null);
            }
          },
        ),
      ],
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
      errorText: _boothNumberError,
      onChanged: (value) {
        draft.boothNumber = value;
        if (_boothNumberError != null && value.trim().isNotEmpty) {
          setState(() => _boothNumberError = null);
        }
      },
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
      errorText: _boothNameError,
      onChanged: (value) {
        draft.boothName = value;
        if (_boothNameError != null && value.trim().isNotEmpty) {
          setState(() => _boothNameError = null);
        }
      },
    );
  }

  String? _shown(String current, List<String> options) {
    return options.contains(current) ? current : null;
  }
}

class _ProfileTopBar extends StatelessWidget {
  const _ProfileTopBar({required this.l10n, required this.onBack, this.photo});

  final AppLocalizations l10n;
  final VoidCallback onBack;
  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: l10n.back,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F2744)),
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
            child: Text(
              l10n.appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F2744),
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const ThemeToggle(),
          const SizedBox(width: 8),
          const LanguageSelector(),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFD7E6F5),
            backgroundImage: photo == null ? null : MemoryImage(photo!),
            child:
                photo == null
                    ? const Icon(
                      Icons.person,
                      color: Color(0xFF0F2744),
                      size: 18,
                    )
                    : null,
          ),
        ],
      ),
    );
  }
}

class _LeaderBackdrop extends StatelessWidget {
  const _LeaderBackdrop();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/profile/leader-profile-hero.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xD9F7FBFF),
                  Color(0x66F7FBFF),
                  Color(0x00FFFFFF),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3FFF8), Color(0xFFE7F8EF), Color(0xFFF4FBFF)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2744),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.format_quote_rounded,
            color: Color(0xFF10B981),
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            '“${AppLocalizations.of(context).line('profileQuote')}”',
            style: TextStyle(
              color:
                  context.palette.isDark
                      ? context.palette.text
                      : const Color(0xFF166534),
              fontSize: 18,
              height: 1.35,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.isDark ? palette.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withValues(alpha: 0.65)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2744),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.surfaceSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(icon, color: palette.accent, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color:
                              palette.isDark
                                  ? palette.text
                                  : const Color(0xFF102A56),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
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
    final diameter = MediaQuery.sizeOf(context).width < 760 ? 104.0 : 120.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.isDark ? palette.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border.withValues(alpha: 0.65)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F2744),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(diameter < 80 ? 12 : 16),
        child: Row(
          children: [
            SizedBox(
              width: diameter,
              height: diameter,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFE8F1FF),
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(color: Color(0x332563EB), blurRadius: 12),
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
                      width: diameter,
                      height: diameter,
                      child:
                          bytes == null
                              ? Icon(
                                Icons.person,
                                size: diameter * 0.44,
                                color: const Color(0xFF64748B),
                              )
                              : null,
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Material(
                      color: const Color(0xFF2563EB),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onAdd,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.photo_camera,
                            size: 18,
                            color: Colors.white,
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
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color:
                          palette.isDark
                              ? palette.text
                              : const Color(0xFF102A56),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: TextStyle(color: palette.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: onAdd,
                        icon: const Icon(Icons.photo_camera_outlined, size: 16),
                        label: Text(takeLabel),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F2744),
                          visualDensity: VisualDensity.compact,
                          side: const BorderSide(color: Color(0xFFD5E2EF)),
                          shape: const StadiumBorder(),
                        ),
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
    this.searchable = false,
    this.searchHint = '',
    this.noResultsLabel = '',
    this.clearSearchLabel = '',
    this.prepareOptions,
    this.filterOptions,
    this.searchFieldKey,
    this.clearButtonKey,
    this.emptyMessageKey,
    this.listKey,
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
  final bool searchable;
  final String searchHint;
  final String noResultsLabel;
  final String clearSearchLabel;
  final List<String> Function(List<String> options)? prepareOptions;
  final List<String> Function(List<String> options, String query)?
  filterOptions;
  final Key? searchFieldKey;
  final Key? clearButtonKey;
  final Key? emptyMessageKey;
  final Key? listKey;

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
        if (searchable)
          SearchableStateField(
            fieldKey: fieldKey,
            hint: hint,
            icon: icon,
            value: value,
            options: options,
            enabled: enabled,
            errorText: errorText,
            onChanged: onChanged,
            searchHint: searchHint,
            noResultsLabel: noResultsLabel,
            clearSearchLabel: clearSearchLabel,
            prepareOptions: prepareOptions,
            filterOptions: filterOptions,
            showPrefix: !showPartySymbols,
            selectedWidget:
                showPartySymbols && value != null
                    ? (context, val) => _PartyOptionLabel(name: val)
                    : null,
            menuContentBuilder:
                showPartySymbols
                    ? (context, visible, selected, onSelect, palette) =>
                        _partyMenuContent(
                          context: context,
                          visibleOptions: visible,
                          selected: selected,
                          onSelect: onSelect,
                          nationalLabel: nationalPartiesLabel,
                          regionalLabel: regionalPartiesLabel,
                          listKey: listKey ?? const ValueKey('partyMenuList'),
                          palette: palette,
                        )
                    : null,
            searchFieldKey: searchFieldKey ?? const ValueKey('stateSearch'),
            clearButtonKey:
                clearButtonKey ?? const ValueKey('clearStateSearch'),
            emptyMessageKey: emptyMessageKey ?? const ValueKey('noStatesFound'),
            listKey: listKey ?? const ValueKey('stateMenuList'),
          )
        else
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
                  showPartySymbols
                      ? null
                      : Icon(icon, color: palette.textMuted),
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

Widget _partyMenuContent({
  required BuildContext context,
  required List<String> visibleOptions,
  required String? selected,
  required ValueChanged<String> onSelect,
  required String nationalLabel,
  required String regionalLabel,
  required Key listKey,
  required AppPalette palette,
}) {
  final visibleSet = visibleOptions.toSet();
  final saved =
      visibleOptions
          .where((name) => PartyOption.findByName(name) == null)
          .toList();
  final national =
      PartyOption.national.where((p) => visibleSet.contains(p.name)).toList();
  final regional =
      PartyOption.regional.where((p) => visibleSet.contains(p.name)).toList();

  Widget header(String id, String label) {
    return Container(
      key: ValueKey(id),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      alignment: AlignmentDirectional.centerStart,
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

  Widget partyItem(String name) {
    return InkWell(
      onTap: () => onSelect(name),
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: name == selected ? palette.accent.withValues(alpha: 0.12) : null,
        alignment: AlignmentDirectional.centerStart,
        child: _PartyOptionLabel(name: name),
      ),
    );
  }

  return SingleChildScrollView(
    key: listKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final name in saved) partyItem(name),
        if (national.isNotEmpty) header('__national_parties__', nationalLabel),
        for (final party in national) partyItem(party.name),
        if (regional.isNotEmpty) header('__regional_parties__', regionalLabel),
        for (final party in regional) partyItem(party.name),
      ],
    ),
  );
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
