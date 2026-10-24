import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../models/website_builder_draft.dart';
import '../models/website_template_catalog.dart';
import '../services/website_builder_api.dart';
import '../services/website_builder_store.dart';
import '../utils/website_validators.dart';
import '../widgets/builder_form_fields.dart';
import '../widgets/builder_progress_bar.dart';
import '../widgets/website_builder_preview.dart';

/// Multi-step website builder: info → content → design → preview → publish.
class WebsiteBuilderScreen extends StatefulWidget {
  const WebsiteBuilderScreen({
    this.continueOnboarding = true,
    this.initialStep = 1,
    super.key,
  });

  final bool continueOnboarding;
  final int initialStep;

  @override
  State<WebsiteBuilderScreen> createState() => _WebsiteBuilderScreenState();
}

class _WebsiteBuilderScreenState extends State<WebsiteBuilderScreen> {
  static const _totalSteps = 5;
  static const _labels = [
    'Basics',
    'Content',
    'Design',
    'Preview',
    'Publish',
  ];

  late int _step;
  late WebsiteBuilderDraft _draft;
  var _ready = false;
  var _publishing = false;
  String? _publishError;

  // Controllers for basic + design fields
  late final TextEditingController _fullName;
  late final TextEditingController _designation;
  late final TextEditingController _constituency;
  late final TextEditingController _district;
  late final TextEditingController _state;
  late final TextEditingController _party;
  late final TextEditingController _shortIntro;
  late final TextEditingController _biography;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _officeAddress;
  late final TextEditingController _facebook;
  late final TextEditingController _instagram;
  late final TextEditingController _youtube;
  late final TextEditingController _twitter;
  late final TextEditingController _linkedin;
  late final TextEditingController _websiteName;

  // Template-specific
  late final TextEditingController _education;
  late final TextEditingController _experience;
  late final TextEditingController _journey;
  late final TextEditingController _expertise;
  late final TextEditingController _officialDesignation;
  late final TextEditingController _term;
  late final TextEditingController _previousPositions;
  late final TextEditingController _publicService;
  late final TextEditingController _officeName;
  late final TextEditingController _visitingHours;
  late final TextEditingController _officialPhone;
  late final TextEditingController _officialEmail;
  late final TextEditingController _communityIntro;
  late final TextEditingController _aboutLeader;
  late final TextEditingController _goals;
  late final TextEditingController _priorities;
  late final TextEditingController _areasServed;
  late final TextEditingController _citizenAssistance;
  late final TextEditingController _serviceInstructions;
  late final TextEditingController _videoUrl;

  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep.clamp(1, _totalSteps);
    _draft = WebsiteBuilderDraft();
    _initControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  void _initControllers() {
    _fullName = TextEditingController();
    _designation = TextEditingController();
    _constituency = TextEditingController();
    _district = TextEditingController();
    _state = TextEditingController();
    _party = TextEditingController();
    _shortIntro = TextEditingController();
    _biography = TextEditingController();
    _phone = TextEditingController();
    _email = TextEditingController();
    _officeAddress = TextEditingController();
    _facebook = TextEditingController();
    _instagram = TextEditingController();
    _youtube = TextEditingController();
    _twitter = TextEditingController();
    _linkedin = TextEditingController();
    _websiteName = TextEditingController();
    _education = TextEditingController();
    _experience = TextEditingController();
    _journey = TextEditingController();
    _expertise = TextEditingController();
    _officialDesignation = TextEditingController();
    _term = TextEditingController();
    _previousPositions = TextEditingController();
    _publicService = TextEditingController();
    _officeName = TextEditingController();
    _visitingHours = TextEditingController();
    _officialPhone = TextEditingController();
    _officialEmail = TextEditingController();
    _communityIntro = TextEditingController();
    _aboutLeader = TextEditingController();
    _goals = TextEditingController();
    _priorities = TextEditingController();
    _areasServed = TextEditingController();
    _citizenAssistance = TextEditingController();
    _serviceInstructions = TextEditingController();
    _videoUrl = TextEditingController();
  }

  Future<void> _bootstrap() async {
    final session = OnboardingScope.of(context);
    final stored = await WebsiteBuilderStore.instance.loadPreferred();
    final draft = stored ?? WebsiteBuilderDraft();

    final template = WebsiteTemplates.normalize(
      session.draft.websiteTemplate ?? draft.templateId,
    );
    draft.selectTemplate(template);
    session.draft.websiteTemplate = template;

    // Seed empty fields from the leader profile — never invent content.
    if (draft.fullName.isEmpty) draft.fullName = session.draft.leaderName.trim();
    if (draft.designation.isEmpty) {
      draft.designation = session.draft.designation.trim();
    }
    if (draft.constituency.isEmpty) {
      draft.constituency = session.draft.assemblyConstituency.trim();
    }
    draft.applyPartyFromProfile(session.draft.party);
    if (draft.district.isEmpty) draft.district = session.draft.district.trim();
    if (draft.state.isEmpty) draft.state = session.draft.state.trim();
    if (draft.phone.isEmpty) draft.phone = session.draft.contactNumber.trim();
    if (!draft.profilePhoto.hasImage && session.draft.photoBytes != null) {
      draft.profilePhoto = MediaRef(
        base64: base64Encode(session.draft.photoBytes!),
      );
    }
    if (draft.design.websiteName.isEmpty && session.draft.selectedDomain != null) {
      draft.design.websiteName = session.draft.selectedDomain!;
    }

    session.websiteBuilder = draft;
    _draft = draft;
    _hydrateControllers();
    if (!mounted) return;
    setState(() => _ready = true);
  }

  void _hydrateControllers() {
    _fullName.text = _draft.fullName;
    _designation.text = _draft.designation;
    _constituency.text = _draft.constituency;
    _district.text = _draft.district;
    _state.text = _draft.state;
    _party.text = _draft.party;
    _shortIntro.text = _draft.shortIntro;
    _biography.text = _draft.biography;
    _phone.text = _draft.phone;
    _email.text = _draft.email;
    _officeAddress.text = _draft.officeAddress;
    _facebook.text = _draft.facebookUrl;
    _instagram.text = _draft.instagramUrl;
    _youtube.text = _draft.youtubeUrl;
    _twitter.text = _draft.twitterUrl;
    _linkedin.text = _draft.linkedinUrl;
    _websiteName.text = _draft.design.websiteName;
    _education.text = _draft.education;
    _experience.text = _draft.professionalExperience;
    _journey.text = _draft.politicalJourney;
    _expertise.text = _draft.expertise;
    _officialDesignation.text = _draft.officialDesignation;
    _term.text = _draft.termOfOffice;
    _previousPositions.text = _draft.previousPositions;
    _publicService.text = _draft.publicServiceExperience;
    _officeName.text = _draft.officeName;
    _visitingHours.text = _draft.visitingHours;
    _officialPhone.text = _draft.officialPhone;
    _officialEmail.text = _draft.officialEmail;
    _communityIntro.text = _draft.communityIntro;
    _aboutLeader.text = _draft.aboutLeader;
    _goals.text = _draft.goalsVision;
    _priorities.text = _draft.localPriorities;
    _areasServed.text = _draft.areasServed;
    _citizenAssistance.text = _draft.citizenAssistance;
    _serviceInstructions.text = _draft.serviceInstructions;
  }

  @override
  void dispose() {
    for (final c in [
      _fullName,
      _designation,
      _constituency,
      _district,
      _state,
      _party,
      _shortIntro,
      _biography,
      _phone,
      _email,
      _officeAddress,
      _facebook,
      _instagram,
      _youtube,
      _twitter,
      _linkedin,
      _websiteName,
      _education,
      _experience,
      _journey,
      _expertise,
      _officialDesignation,
      _term,
      _previousPositions,
      _publicService,
      _officeName,
      _visitingHours,
      _officialPhone,
      _officialEmail,
      _communityIntro,
      _aboutLeader,
      _goals,
      _priorities,
      _areasServed,
      _citizenAssistance,
      _serviceInstructions,
      _videoUrl,
    ]) {
      c.dispose();
    }
    WebsiteBuilderStore.instance.disposeTimer();
    super.dispose();
  }

  void _syncDraft() {
    _draft
      ..fullName = _fullName.text.trim()
      ..designation = _designation.text.trim()
      ..constituency = _constituency.text.trim()
      ..district = _district.text.trim()
      ..state = _state.text.trim()
      ..party = _party.text.trim()
      ..shortIntro = _shortIntro.text.trim()
      ..biography = _biography.text.trim()
      ..phone = _phone.text.trim()
      ..email = _email.text.trim()
      ..officeAddress = _officeAddress.text.trim()
      ..facebookUrl = _facebook.text.trim()
      ..instagramUrl = _instagram.text.trim()
      ..youtubeUrl = _youtube.text.trim()
      ..twitterUrl = _twitter.text.trim()
      ..linkedinUrl = _linkedin.text.trim()
      ..education = _education.text.trim()
      ..professionalExperience = _experience.text.trim()
      ..politicalJourney = _journey.text.trim()
      ..expertise = _expertise.text.trim()
      ..officialDesignation = _officialDesignation.text.trim()
      ..termOfOffice = _term.text.trim()
      ..previousPositions = _previousPositions.text.trim()
      ..publicServiceExperience = _publicService.text.trim()
      ..officeName = _officeName.text.trim()
      ..visitingHours = _visitingHours.text.trim()
      ..officialPhone = _officialPhone.text.trim()
      ..officialEmail = _officialEmail.text.trim()
      ..communityIntro = _communityIntro.text.trim()
      ..aboutLeader = _aboutLeader.text.trim()
      ..goalsVision = _goals.text.trim()
      ..localPriorities = _priorities.text.trim()
      ..areasServed = _areasServed.text.trim()
      ..citizenAssistance = _citizenAssistance.text.trim()
      ..serviceInstructions = _serviceInstructions.text.trim();
    _draft.design.websiteName = _websiteName.text.trim();
    _draft.status = WebsiteStatus.draft;
    OnboardingScope.of(context).websiteBuilder = _draft;
    OnboardingScope.of(context).draft.websiteTemplate = _draft.templateId;
  }

  void _onChanged() {
    _syncDraft();
    WebsiteBuilderStore.instance.scheduleAutosave(_draft);
    setState(() {});
  }

  Future<void> _saveDraftExplicit() async {
    _syncDraft();
    await WebsiteBuilderStore.instance.saveNow(_draft);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).line('wbDraftSaved'))),
    );
  }

  bool _validateStep(int step) {
    _errors.clear();
    if (step == 1) {
      _errors['fullName'] =
          WebsiteValidators.requiredText(_fullName.text, label: 'Full name');
      _errors['designation'] = WebsiteValidators.requiredText(
        _designation.text,
        label: 'Designation',
      );
      _errors['constituency'] = WebsiteValidators.requiredText(
        _constituency.text,
        label: 'Constituency / area',
      );
      _errors['shortIntro'] = WebsiteValidators.requiredText(
        _shortIntro.text,
        label: 'Short introduction',
      );
      _errors['email'] = WebsiteValidators.email(_email.text);
      _errors['phone'] = WebsiteValidators.phone(_phone.text);
      _errors['facebook'] = WebsiteValidators.url(_facebook.text);
      _errors['instagram'] = WebsiteValidators.url(_instagram.text);
      _errors['youtube'] = WebsiteValidators.url(_youtube.text);
      _errors['twitter'] = WebsiteValidators.url(_twitter.text);
      _errors['linkedin'] = WebsiteValidators.url(_linkedin.text);
    }
    if (step == 3) {
      _errors['websiteName'] = WebsiteValidators.requiredText(
        _websiteName.text,
        label: 'Website name',
      );
    }
    _errors.removeWhere((_, value) => value == null);
    return _errors.isEmpty;
  }

  Future<void> _next() async {
    _syncDraft();
    if (!_validateStep(_step)) {
      setState(() {});
      return;
    }
    await WebsiteBuilderStore.instance.saveNow(_draft);
    if (_step >= _totalSteps) return;
    setState(() => _step += 1);
  }

  void _back() {
    _syncDraft();
    if (_step <= 1) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _step -= 1);
  }

  Future<void> _goPurchase() async {
    _syncDraft();
    if (!_draft.canPublish) {
      setState(() {
        _publishError = _draft.publishBlockingReasons().join(' ');
      });
      return;
    }
    _draft.status = WebsiteStatus.pendingPayment;
    await WebsiteBuilderStore.instance.saveNow(_draft);
    if (!mounted) return;
    AppRouter.open(context, AppRoutes.websitePurchase);
  }

  Future<void> _tryPublish() async {
    _syncDraft();
    if (!_draft.canPublish) {
      setState(() {
        _publishError = _draft.publishBlockingReasons().join(' ');
      });
      return;
    }
    setState(() {
      _publishing = true;
      _publishError = null;
    });
    await WebsiteBuilderStore.instance.saveNow(_draft);
    final result = await WebsiteBuilderApi.instance.publish(_draft);
    if (!mounted) return;
    setState(() => _publishing = false);
    if (result.error != null) {
      setState(() {
        _publishError = switch (result.error) {
          'payment_required' =>
            AppLocalizations.of(context).line('wbPaymentRequired'),
          'sign_in_required' =>
            AppLocalizations.of(context).line('wbSignInRequired'),
          'validation_failed' => _draft.publishBlockingReasons().join(' '),
          _ => AppLocalizations.of(context).line('wbPublishFailed'),
        };
      });
      return;
    }
    if (result.draft != null) {
      _draft = result.draft!;
      OnboardingScope.of(context).websiteBuilder = _draft;
      await WebsiteBuilderStore.instance.saveLocal(_draft);
    }
    setState(() {});
  }

  Future<void> _pickGallery() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1400,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _draft.gallery = [
        ..._draft.gallery,
        MediaRef(base64: base64Encode(bytes)),
      ];
      _onChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    if (!_ready) {
      return Scaffold(
        backgroundColor: palette.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(l10n.line('wbBuilderTitle')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _back,
        ),
        actions: [
          ValueListenableBuilder<WebsiteSaveState>(
            valueListenable: WebsiteBuilderStore.instance.saveState,
            builder: (context, state, _) {
              final label = switch (state) {
                WebsiteSaveState.saving => l10n.line('wbSaving'),
                WebsiteSaveState.saved => l10n.line('wbSaved'),
                WebsiteSaveState.error => l10n.line('wbSaveError'),
                _ => '',
              };
              if (label.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(label, style: AppTextStyles.muted(context)),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BuilderProgressBar(
              step: _step,
              total: _totalSteps,
              labels: _labels,
            ),
            const SizedBox(height: 16),
            Text(
              WebsiteTemplateCatalog.byId(_draft.templateId).name,
              style: AppTextStyles.muted(context),
            ),
            const SizedBox(height: 12),
            if (_step == 1) _buildBasics(),
            if (_step == 2) _buildContent(),
            if (_step == 3) _buildDesign(),
            if (_step == 4) _buildPreviewStep(),
            if (_step == 5) _buildPublishStep(l10n),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: _step == 1 ? l10n.back : l10n.line('wbPrevious'),
                    onPressed: _back,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: _step == _totalSteps
                        ? l10n.line('wbSaveDraft')
                        : l10n.next,
                    onPressed: _step == _totalSteps
                        ? _saveDraftExplicit
                        : _next,
                  ),
                ),
              ],
            ),
            if (widget.continueOnboarding && _step == _totalSteps) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _syncDraft();
                  unawaited(WebsiteBuilderStore.instance.saveNow(_draft));
                  AppRouter.open(context, AppRoutes.social);
                },
                child: Text(l10n.skipForNow),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BuilderSectionHeader(
          'Basic information',
          subtitle: 'Shared by all templates. Required fields are marked *.',
        ),
        BuilderTextField(
          controller: _fullName,
          label: 'Full Name',
          hint: 'Enter your full name',
          requiredField: true,
          errorText: _errors['fullName'],
          onChanged: (_) => _onChanged(),
        ),
        BuilderTextField(
          controller: _designation,
          label: 'Designation',
          hint: 'e.g. MLA, Councillor, Community Leader',
          requiredField: true,
          errorText: _errors['designation'],
          onChanged: (_) => _onChanged(),
        ),
        BuilderPhotoPicker(
          label: 'Profile Photo',
          media: _draft.profilePhoto,
          requiredField: true,
          round: true,
          onChanged: (media) {
            _draft.profilePhoto = media;
            _onChanged();
          },
        ),
        BuilderPhotoPicker(
          label: 'Cover Photo',
          media: _draft.coverPhoto,
          onChanged: (media) {
            _draft.coverPhoto = media;
            _onChanged();
          },
        ),
        BuilderTextField(
          controller: _constituency,
          label: 'Constituency / Village / Ward',
          hint: 'Enter your constituency or service area',
          requiredField: true,
          errorText: _errors['constituency'],
          onChanged: (_) => _onChanged(),
        ),
        BuilderTextField(
          controller: _district,
          label: 'District / City',
          hint: 'District or city',
          onChanged: (_) => _onChanged(),
        ),
        BuilderTextField(
          controller: _state,
          label: 'State',
          hint: 'State',
          onChanged: (_) => _onChanged(),
        ),
        BuilderTextField(
          controller: _party,
          label: 'Political Party / Organization',
          hint: 'Party or organization name',
          onChanged: (_) => _onChanged(),
        ),
        BuilderTextField(
          controller: _shortIntro,
          label: 'Short Introduction',
          hint: 'Write a short introduction about yourself',
          requiredField: true,
          maxLines: 3,
          errorText: _errors['shortIntro'],
          onChanged: (_) => _onChanged(),
        ),
        BuilderTextField(
          controller: _biography,
          label: 'Full Biography',
          hint: 'Describe your background, experience, and public service',
          maxLines: 5,
          onChanged: (_) => _onChanged(),
        ),
        BuilderTextField(
          controller: _phone,
          label: 'Public Contact Number',
          hint: '10-digit mobile or +91…',
          keyboardType: TextInputType.phone,
          errorText: _errors['phone'],
          onChanged: (_) => _onChanged(),
        ),
        BuilderTextField(
          controller: _email,
          label: 'Official Email Address',
          hint: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
          errorText: _errors['email'],
          onChanged: (_) => _onChanged(),
        ),
        BuilderTextField(
          controller: _officeAddress,
          label: 'Office Address',
          hint: 'Office or public address',
          maxLines: 2,
          onChanged: (_) => _onChanged(),
        ),
        BuilderTextField(
          controller: _facebook,
          label: 'Facebook URL',
          hint: 'https://facebook.com/…',
          errorText: _errors['facebook'],
          onChanged: (_) => _onChanged(),
        ),
        BuilderTextField(
          controller: _instagram,
          label: 'Instagram URL',
          hint: 'https://instagram.com/…',
          errorText: _errors['instagram'],
          onChanged: (_) => _onChanged(),
        ),
        BuilderTextField(
          controller: _youtube,
          label: 'YouTube URL',
          hint: 'https://youtube.com/…',
          errorText: _errors['youtube'],
          onChanged: (_) => _onChanged(),
        ),
        BuilderTextField(
          controller: _twitter,
          label: 'X (Twitter) URL',
          hint: 'https://x.com/…',
          errorText: _errors['twitter'],
          onChanged: (_) => _onChanged(),
        ),
        BuilderTextField(
          controller: _linkedin,
          label: 'LinkedIn URL',
          hint: 'https://linkedin.com/in/…',
          errorText: _errors['linkedin'],
          onChanged: (_) => _onChanged(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final template = _draft.templateId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (template == WebsiteTemplates.professional) ...[
          const BuilderSectionHeader('Professional background'),
          BuilderTextField(
            controller: _education,
            label: 'Education and Qualifications',
            maxLines: 3,
            onChanged: (_) => _onChanged(),
          ),
          BuilderTextField(
            controller: _experience,
            label: 'Professional Experience',
            maxLines: 3,
            onChanged: (_) => _onChanged(),
          ),
          BuilderTextField(
            controller: _journey,
            label: 'Political Journey',
            maxLines: 3,
            onChanged: (_) => _onChanged(),
          ),
          BuilderTextField(
            controller: _expertise,
            label: 'Areas of Expertise or Public Service',
            maxLines: 3,
            onChanged: (_) => _onChanged(),
          ),
        ],
        if (template == WebsiteTemplates.official) ...[
          const BuilderSectionHeader('Official profile'),
          BuilderTextField(
            controller: _officialDesignation,
            label: 'Official Designation',
            hint: 'Only enter designations you hold',
            onChanged: (_) => _onChanged(),
          ),
          BuilderTextField(
            controller: _term,
            label: 'Term of Office',
            onChanged: (_) => _onChanged(),
          ),
          BuilderTextField(
            controller: _previousPositions,
            label: 'Previous Positions Held',
            maxLines: 3,
            onChanged: (_) => _onChanged(),
          ),
          BuilderTextField(
            controller: _publicService,
            label: 'Public Service Experience',
            maxLines: 3,
            onChanged: (_) => _onChanged(),
          ),
          const BuilderSectionHeader('Office information'),
          BuilderTextField(
            controller: _officeName,
            label: 'Office Name',
            onChanged: (_) => _onChanged(),
          ),
          BuilderTextField(
            controller: _visitingHours,
            label: 'Public Visiting Hours',
            onChanged: (_) => _onChanged(),
          ),
          BuilderTextField(
            controller: _officialPhone,
            label: 'Official Phone Number',
            keyboardType: TextInputType.phone,
            onChanged: (_) => _onChanged(),
          ),
          BuilderTextField(
            controller: _officialEmail,
            label: 'Official Email Address',
            keyboardType: TextInputType.emailAddress,
            onChanged: (_) => _onChanged(),
          ),
        ],
        if (template == WebsiteTemplates.community) ...[
          const BuilderSectionHeader('Community information'),
          BuilderTextField(
            controller: _communityIntro,
            label: 'Community Introduction',
            maxLines: 3,
            onChanged: (_) => _onChanged(),
          ),
          BuilderTextField(
            controller: _aboutLeader,
            label: 'About the Leader or Organization',
            maxLines: 3,
            onChanged: (_) => _onChanged(),
          ),
          BuilderTextField(
            controller: _goals,
            label: 'Community Goals and Vision',
            maxLines: 3,
            onChanged: (_) => _onChanged(),
          ),
          BuilderTextField(
            controller: _priorities,
            label: 'Local Priorities and Needs',
            maxLines: 3,
            onChanged: (_) => _onChanged(),
          ),
          BuilderTextField(
            controller: _areasServed,
            label: 'Villages, Wards, or Areas Served',
            maxLines: 2,
            onChanged: (_) => _onChanged(),
          ),
          const BuilderSectionHeader('Citizen services'),
          BuilderTextField(
            controller: _citizenAssistance,
            label: 'Citizen Assistance Information',
            maxLines: 3,
            onChanged: (_) => _onChanged(),
          ),
          BuilderTextField(
            controller: _serviceInstructions,
            label: 'Public Service Request Instructions',
            maxLines: 3,
            onChanged: (_) => _onChanged(),
          ),
          Text(
            'Grievance submission is unavailable until the backend supports it.',
            style: AppTextStyles.muted(context),
          ),
        ],
        const BuilderSectionHeader('Achievements'),
        if (_draft.achievements.isEmpty)
          const EmptyEntriesHint('No achievements yet. Add one below.'),
        for (var i = 0; i < _draft.achievements.length; i++)
          _achievementEditor(i),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _draft.achievements = [
                  ..._draft.achievements,
                  AchievementEntry(),
                ];
                _onChanged();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add achievement'),
          ),
        ),
        const BuilderSectionHeader('Development projects'),
        if (_draft.projects.isEmpty)
          const EmptyEntriesHint('No projects yet. Add one below.'),
        for (var i = 0; i < _draft.projects.length; i++) _projectEditor(i),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _draft.projects = [..._draft.projects, ProjectEntry()];
                _onChanged();
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add project'),
          ),
        ),
        if (template == WebsiteTemplates.official ||
            template == WebsiteTemplates.community) ...[
          const BuilderSectionHeader('Announcements / updates'),
          if (_draft.announcements.isEmpty)
            const EmptyEntriesHint('No announcements yet.'),
          for (var i = 0; i < _draft.announcements.length; i++)
            _announcementEditor(i),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _draft.announcements = [
                    ..._draft.announcements,
                    AnnouncementEntry(),
                  ];
                  _onChanged();
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add announcement'),
            ),
          ),
        ],
        if (template == WebsiteTemplates.community) ...[
          const BuilderSectionHeader('Community events'),
          if (_draft.events.isEmpty)
            const EmptyEntriesHint('No events yet.'),
          for (var i = 0; i < _draft.events.length; i++) _eventEditor(i),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _draft.events = [..._draft.events, EventEntry()];
                  _onChanged();
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Add event'),
            ),
          ),
        ],
        const BuilderSectionHeader('Media gallery'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _draft.gallery.length; i++)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 84,
                      height: 84,
                      child: _draft.gallery[i].bytes != null
                          ? Image.memory(
                              _draft.gallery[i].bytes!,
                              fit: BoxFit.cover,
                            )
                          : const ColoredBox(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        setState(() {
                          _draft.gallery = [..._draft.gallery]..removeAt(i);
                          _onChanged();
                        });
                      },
                    ),
                  ),
                ],
              ),
          ],
        ),
        TextButton.icon(
          onPressed: _pickGallery,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Add gallery photo'),
        ),
        BuilderTextField(
          controller: _videoUrl,
          label: 'Add video URL',
          hint: 'https://youtube.com/…',
          onChanged: (_) {},
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {
              final err = WebsiteValidators.url(_videoUrl.text);
              if (err != null || _videoUrl.text.trim().isEmpty) return;
              setState(() {
                _draft.videoUrls = [
                  ..._draft.videoUrls,
                  _videoUrl.text.trim(),
                ];
                _videoUrl.clear();
                _onChanged();
              });
            },
            child: const Text('Add video URL'),
          ),
        ),
        for (var i = 0; i < _draft.videoUrls.length; i++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_draft.videoUrls[i]),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                setState(() {
                  _draft.videoUrls = [..._draft.videoUrls]..removeAt(i);
                  _onChanged();
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _achievementEditor(int index) {
    final item = _draft.achievements[index];
    return _EntryCard(
      onRemove: () {
        setState(() {
          _draft.achievements = [..._draft.achievements]..removeAt(index);
          _onChanged();
        });
      },
      child: Column(
        children: [
          TextFormField(
            initialValue: item.title,
            decoration: const InputDecoration(
              labelText: 'Achievement title',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              item.title = v;
              _onChanged();
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item.description,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              item.description = v;
              _onChanged();
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item.dateOrYear,
            decoration: const InputDecoration(
              labelText: 'Date or year',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              item.dateOrYear = v;
              _onChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _projectEditor(int index) {
    final item = _draft.projects[index];
    return _EntryCard(
      onRemove: () {
        setState(() {
          _draft.projects = [..._draft.projects]..removeAt(index);
          _onChanged();
        });
      },
      child: Column(
        children: [
          TextFormField(
            initialValue: item.name,
            decoration: const InputDecoration(
              labelText: 'Project name',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              item.name = v;
              _onChanged();
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item.description,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              item.description = v;
              _onChanged();
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item.location,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              item.location = v;
              _onChanged();
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: ProjectStatus.normalize(item.status),
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: [
              for (final status in ProjectStatus.all)
                DropdownMenuItem(
                  value: status,
                  child: Text(status[0].toUpperCase() + status.substring(1)),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              item.status = value;
              _onChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _announcementEditor(int index) {
    final item = _draft.announcements[index];
    return _EntryCard(
      onRemove: () {
        setState(() {
          _draft.announcements = [..._draft.announcements]..removeAt(index);
          _onChanged();
        });
      },
      child: Column(
        children: [
          TextFormField(
            initialValue: item.title,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              item.title = v;
              _onChanged();
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item.description,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              item.description = v;
              _onChanged();
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item.publicationDate,
            decoration: const InputDecoration(
              labelText: 'Publication date',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              item.publicationDate = v;
              _onChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _eventEditor(int index) {
    final item = _draft.events[index];
    return _EntryCard(
      onRemove: () {
        setState(() {
          _draft.events = [..._draft.events]..removeAt(index);
          _onChanged();
        });
      },
      child: Column(
        children: [
          TextFormField(
            initialValue: item.name,
            decoration: const InputDecoration(
              labelText: 'Event name',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              item.name = v;
              _onChanged();
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item.description,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              item.description = v;
              _onChanged();
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item.dateTime,
            decoration: const InputDecoration(
              labelText: 'Date and time',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              item.dateTime = v;
              _onChanged();
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: item.venue,
            decoration: const InputDecoration(
              labelText: 'Venue',
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              item.venue = v;
              _onChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesign() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BuilderSectionHeader(
          'Customize design',
          subtitle: 'Colors and fonts keep each template recognizable.',
        ),
        BuilderTextField(
          controller: _websiteName,
          label: 'Website Name',
          hint: 'e.g. rameshkumar.in',
          requiredField: true,
          errorText: _errors['websiteName'],
          onChanged: (_) => _onChanged(),
        ),
        BuilderPhotoPicker(
          label: 'Website Logo',
          media: _draft.design.logo,
          onChanged: (media) {
            _draft.design.logo = media;
            _onChanged();
          },
        ),
        BuilderPhotoPicker(
          label: 'Hero / cover image',
          media: _draft.design.heroImage,
          onChanged: (media) {
            _draft.design.heroImage = media;
            _onChanged();
          },
        ),
        Text('Primary color', style: AppTextStyles.headline(context)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final color in const [
              0xFF1D4ED8,
              0xFF1E3A5F,
              0xFF0F766E,
              0xFF111827,
            ])
              _ColorDot(
                color: color,
                selected: _draft.design.primaryColor == color,
                onTap: () {
                  _draft.design.primaryColor = color;
                  _onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Secondary color', style: AppTextStyles.headline(context)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final color in const [
              0xFFF08A24,
              0xFFC9A227,
              0xFF2563EB,
              0xFF22C55E,
            ])
              _ColorDot(
                color: color,
                selected: _draft.design.secondaryColor == color,
                onTap: () {
                  _draft.design.secondaryColor = color;
                  _onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Font', style: AppTextStyles.headline(context)),
        Wrap(
          spacing: 8,
          children: [
            for (final font in const ['system', 'serif', 'mono'])
              ChoiceChip(
                label: Text(font),
                selected: _draft.design.fontKey == font,
                onSelected: (_) {
                  _draft.design.fontKey = font;
                  _onChanged();
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Section visibility', style: AppTextStyles.headline(context)),
        for (final entry in const [
          ('about', 'About'),
          ('background', 'Background'),
          ('achievements', 'Achievements'),
          ('projects', 'Projects'),
          ('announcements', 'Announcements'),
          ('events', 'Events'),
          ('services', 'Citizen services'),
          ('office', 'Office'),
          ('gallery', 'Gallery'),
          ('contact', 'Contact'),
        ])
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(entry.$2),
            value: _draft.design.sectionVisibility[entry.$1] != false,
            onChanged: (value) {
              _draft.design.sectionVisibility[entry.$1] = value;
              _onChanged();
            },
          ),
        Text('Social visibility', style: AppTextStyles.headline(context)),
        for (final entry in const [
          ('facebook', 'Facebook'),
          ('instagram', 'Instagram'),
          ('youtube', 'YouTube'),
          ('twitter', 'X'),
          ('linkedin', 'LinkedIn'),
        ])
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(entry.$2),
            value: _draft.design.socialVisibility[entry.$1] != false,
            onChanged: (value) {
              _draft.design.socialVisibility[entry.$1] = value;
              _onChanged();
            },
          ),
        const SizedBox(height: 12),
        WebsiteBuilderPreview(draft: _draft, compact: true),
      ],
    );
  }

  Widget _buildPreviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const BuilderSectionHeader(
          'Preview your website',
          subtitle: 'Only sections with your content are shown.',
        ),
        WebsiteBuilderPreview(draft: _draft),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => setState(() => _step = 1),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Edit basic information'),
        ),
        OutlinedButton.icon(
          onPressed: () => setState(() => _step = 2),
          icon: const Icon(Icons.article_outlined),
          label: const Text('Edit content'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.dashboard_customize_outlined),
          label: const Text('Back to website preview'),
        ),
      ],
    );
  }

  Widget _buildPublishStep(AppLocalizations l10n) {
    final published = _draft.status == WebsiteStatus.published;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BuilderSectionHeader(
          published ? 'Website published' : 'Purchase and publish',
          subtitle: published
              ? 'Your website status is published.'
              : 'Save your draft, complete payment, then publish.',
        ),
        WebsiteBuilderPreview(draft: _draft, compact: true),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: context.palette.border),
            borderRadius: BorderRadius.circular(16),
            color: context.palette.surface,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.line('wbPlanTitle'),
                    style: AppTextStyles.headline(context)),
                const SizedBox(height: 6),
                Text(l10n.line('wbPlanBody'),
                    style: AppTextStyles.muted(context)),
                const SizedBox(height: 8),
                Text(
                  '₹999',
                  style: AppTextStyles.headline(context).copyWith(fontSize: 28),
                ),
              ],
            ),
          ),
        ),
        if (_publishError != null) ...[
          const SizedBox(height: 12),
          Text(
            _publishError!,
            style: AppTextStyles.body(context)
                .copyWith(color: context.palette.danger),
          ),
        ],
        if (published && (_draft.publishedUrl ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          SelectableText(
            _draft.publishedUrl!,
            style: AppTextStyles.body(context),
          ),
        ],
        const SizedBox(height: 12),
        PrimaryButton(
          label: l10n.portfolioGetWebsite,
          onPressed: _publishing ? null : _goPurchase,
        ),
        const SizedBox(height: 8),
        SecondaryButton(
          label: l10n.line('wbPublish'),
          onPressed: _publishing ? () {} : _tryPublish,
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _saveDraftExplicit,
          child: Text(l10n.line('wbSaveDraft')),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.line('wbPaymentNote'),
          style: AppTextStyles.muted(context),
        ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.child, required this.onRemove});

  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: context.palette.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Remove entry?'),
                        content: const Text(
                          'This cannot be undone for this draft session.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) onRemove();
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final int color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Color(color),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}
