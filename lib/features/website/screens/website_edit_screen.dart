import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../../onboarding/widgets/onboarding_frame.dart';
import '../models/website_draft.dart';

class WebsiteEditScreen extends StatefulWidget {
  const WebsiteEditScreen({super.key});

  @override
  State<WebsiteEditScreen> createState() => _WebsiteEditScreenState();
}

class _WebsiteEditScreenState extends State<WebsiteEditScreen> {
  final _picker = ImagePicker();
  var _ready = false;
  late WebsiteDraft _website;
  late final TextEditingController _name;
  late final TextEditingController _title;
  late final TextEditingController _organization;
  late final TextEditingController _description;
  late final TextEditingController _about;
  late final TextEditingController _vision;
  late final TextEditingController _mission;
  late final TextEditingController _priorities;
  late final TextEditingController _achievements;
  late final TextEditingController _events;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _social;
  late final TextEditingController _action;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) {
      return;
    }
    _website = OnboardingScope.of(context).website;
    _name = TextEditingController(text: _website.fullName);
    _title = TextEditingController(text: _website.publicTitle);
    _organization = TextEditingController(text: _website.organization);
    _description = TextEditingController(text: _website.description);
    _about = TextEditingController(text: _website.about);
    _vision = TextEditingController(text: _website.vision);
    _mission = TextEditingController(text: _website.mission);
    _priorities = TextEditingController(text: _website.priorities);
    _achievements = TextEditingController(text: _website.achievements);
    _events = TextEditingController(text: _website.eventsNote);
    _phone = TextEditingController(text: _website.phone);
    _email = TextEditingController(text: _website.email);
    _address = TextEditingController(text: _website.address);
    _social = TextEditingController(text: _website.socialLinks);
    _action = TextEditingController(text: _website.callToAction);
    _ready = true;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _title,
      _organization,
      _description,
      _about,
      _vision,
      _mission,
      _priorities,
      _achievements,
      _events,
      _phone,
      _email,
      _address,
      _social,
      _action,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _update() async {
    _website
      ..fullName = _name.text.trim()
      ..publicTitle = _title.text.trim()
      ..organization = _organization.text.trim()
      ..description = _description.text.trim()
      ..about = _about.text.trim()
      ..vision = _vision.text.trim()
      ..mission = _mission.text.trim()
      ..priorities = _priorities.text.trim()
      ..achievements = _achievements.text.trim()
      ..eventsNote = _events.text.trim()
      ..phone = _phone.text.trim()
      ..email = _email.text.trim()
      ..address = _address.text.trim()
      ..socialLinks = _social.text.trim()
      ..callToAction = _action.text.trim();
    final services = OnboardingScope.of(context).websiteServices;
    _website.preview = await services.generation.generate(_website);
    if (!mounted) {
      return;
    }
    AppRouter.back(context, AppRoutes.websitePreview);
  }

  Future<void> _pickLogo() async {
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
      setState(() => _website.logo = bytes);
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
    if (!_ready) {
      return const SizedBox.shrink();
    }

    return OnboardingFrame(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingHeader(
              compact: true,
              title: l10n.line('editWebsite'),
              description: l10n.line('addWorkPrompt'),
            ),
            const SizedBox(height: 16),
            AppTextField(controller: _name, label: l10n.line('qFullName')),
            const SizedBox(height: 12),
            AppTextField(controller: _title, label: l10n.line('qTitle')),
            const SizedBox(height: 12),
            AppTextField(controller: _organization, label: l10n.line('qOrganization')),
            const SizedBox(height: 12),
            AppTextField(controller: _description, label: l10n.line('websiteInfoTitle'), maxLines: 4),
            const SizedBox(height: 12),
            AppTextField(controller: _about, label: l10n.line('qAbout'), maxLines: 4),
            const SizedBox(height: 12),
            AppTextField(controller: _vision, label: l10n.line('qVision'), maxLines: 3),
            const SizedBox(height: 12),
            AppTextField(controller: _mission, label: l10n.line('qMission'), maxLines: 3),
            const SizedBox(height: 12),
            AppTextField(controller: _priorities, label: l10n.line('qPriorities'), maxLines: 3),
            const SizedBox(height: 12),
            AppTextField(controller: _achievements, label: l10n.line('qWork'), maxLines: 4),
            const SizedBox(height: 12),
            AppTextField(controller: _events, label: l10n.line('secEvents'), maxLines: 3),
            const SizedBox(height: 12),
            AppTextField(controller: _action, label: l10n.line('qCta'), maxLines: 2),
            const SizedBox(height: 12),
            AppTextField(controller: _phone, label: l10n.line('qPhone')),
            const SizedBox(height: 12),
            AppTextField(controller: _email, label: l10n.line('qEmail')),
            const SizedBox(height: 12),
            AppTextField(controller: _address, label: l10n.line('qAddress'), maxLines: 2),
            const SizedBox(height: 12),
            AppTextField(controller: _social, label: l10n.line('qSocial'), maxLines: 2),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickLogo,
              icon: Icon(_website.logo == null ? Icons.add_a_photo_outlined : Icons.check),
              label: Text(l10n.line('qLogo')),
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: l10n.line('updatePreview'), onPressed: _update),
          ],
        ),
      ),
    );
  }
}
