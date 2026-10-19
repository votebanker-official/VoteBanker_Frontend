import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/primary_button.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../models/portfolio_config.dart';
import '../services/portfolio_store.dart';
import '../widgets/portfolio_live_preview.dart';

/// Customizes the selected template. Website edits stay separate from the profile.
class WebsiteDetailsScreen extends StatefulWidget {
  const WebsiteDetailsScreen({
    required this.profile,
    required this.fallbackHeadline,
    required this.fallbackSupport,
    this.continueOnboarding = true,
    super.key,
  });

  final PortfolioProfileFacts profile;
  final String fallbackHeadline;
  final String fallbackSupport;
  final bool continueOnboarding;

  @override
  State<WebsiteDetailsScreen> createState() => _WebsiteDetailsScreenState();
}

class _WebsiteDetailsScreenState extends State<WebsiteDetailsScreen> {
  final _picker = ImagePicker();
  PortfolioDesign? _design;
  late final TextEditingController _title;
  late final TextEditingController _tagline;
  late final TextEditingController _about;
  late final TextEditingController _vision;
  late final TextEditingController _achievements;
  late final TextEditingController _news;
  late final TextEditingController _contact;
  late final TextEditingController _social;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_design != null) return;
    final session = OnboardingScope.of(context);
    final design = session.portfolio.active.copy();
    _prefill(design, session);
    _design = design;
    _title = TextEditingController(text: design.title);
    _tagline = TextEditingController(text: design.tagline);
    _about = TextEditingController(text: design.about);
    _vision = TextEditingController(text: design.vision);
    _achievements = TextEditingController(text: design.achievements);
    _news = TextEditingController(text: design.news);
    _contact = TextEditingController(text: design.contact);
    _social = TextEditingController(text: design.socialLinks);
  }

  void _prefill(PortfolioDesign design, OnboardingController session) {
    final draft = session.draft;
    if (design.title.trim().isEmpty) {
      design.title = draft.leaderName.trim();
    }
    if (design.contact.trim().isEmpty) {
      design.contact = [
        draft.contactNumber.trim(),
        [
          draft.district,
          draft.state,
          draft.country,
        ].where((value) => value.trim().isNotEmpty).join(', '),
      ].where((value) => value.isNotEmpty).join('\n');
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _tagline,
      _about,
      _vision,
      _achievements,
      _news,
      _contact,
      _social,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  PortfolioDesign get design => _design!;

  void _sync() {
    design
      ..title = _title.text.trim()
      ..tagline = _tagline.text.trim()
      ..about = _about.text.trim()
      ..vision = _vision.text.trim()
      ..achievements = _achievements.text.trim()
      ..news = _news.text.trim()
      ..contact = _contact.text.trim()
      ..socialLinks = _social.text.trim();
  }

  Future<void> _save() async {
    _sync();
    final session = OnboardingScope.of(context);
    session.portfolio.templates[session.portfolio.templateId] = design.copy();
    await PortfolioStore.instance.save(session.portfolio);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> _addGalleryItem() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      design.gallery = [
        ...design.gallery,
        PortfolioGalleryItem(
          id: 'g-${DateTime.now().microsecondsSinceEpoch}',
          imageBase64: base64Encode(bytes),
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    _sync();
    final preview = PortfolioLivePreview(
      design: design,
      profile: widget.profile,
      fallbackHeadline: widget.fallbackHeadline,
      fallbackSupport: widget.fallbackSupport,
      height: 420,
    );

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: Text(l10n.line('portfolioWebsiteDetails')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _sync();
            final session = OnboardingScope.of(context);
            session.portfolio.templates[session.portfolio.templateId] =
                design.copy();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            preview,
            const SizedBox(height: 16),
            _field(_title, l10n.line('portfolioSiteTitle')),
            _field(_tagline, l10n.line('portfolioTagline')),
            _field(_about, 'About the Leader', maxLines: 4),
            _field(_vision, 'Vision and Priorities', maxLines: 4),
            _field(_achievements, 'Work and Achievements', maxLines: 4),
            _field(_news, 'News and Updates', maxLines: 3),
            _field(_contact, 'Contact information', maxLines: 3),
            _field(_social, 'Social links', maxLines: 2),
            const SizedBox(height: 8),
            Text('Theme colors', style: AppTextStyles.headline(context)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final color in const [
                  0xFF1D4ED8,
                  0xFF8C3E2F,
                  0xFF0F766E,
                  0xFF111827,
                ])
                  _swatch(color, design.primaryColor, (value) {
                    setState(() => design.primaryColor = value);
                  }),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final color in const [
                  0xFFF08A24,
                  0xFFE7B56A,
                  0xFFF0B429,
                  0xFF22C55E,
                ])
                  _swatch(color, design.accentColor, (value) {
                    setState(() => design.accentColor = value);
                  }),
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
                    selected: design.fontKey == font,
                    onSelected: (_) => setState(() => design.fontKey = font),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Layout', style: AppTextStyles.headline(context)),
            Wrap(
              spacing: 8,
              children: [
                for (final layout in const ['split', 'stacked'])
                  ChoiceChip(
                    label: Text(layout),
                    selected: design.layoutKey == layout,
                    onSelected: (_) => setState(() => design.layoutKey = layout),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Gallery', style: AppTextStyles.headline(context)),
            for (var i = 0; i < design.gallery.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: design.gallery[i].image == null
                    ? const Icon(Icons.image_outlined)
                    : Image.memory(
                        design.gallery[i].image!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                title: TextFormField(
                  key: ValueKey('caption-${design.gallery[i].id}'),
                  initialValue: design.gallery[i].caption,
                  decoration: const InputDecoration(hintText: 'Caption'),
                  onChanged: (value) => design.gallery[i].caption = value,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() {
                    design.gallery = [...design.gallery]..removeAt(i);
                  }),
                ),
              ),
            TextButton.icon(
              onPressed: _addGalleryItem,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Add gallery photo'),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              key: const ValueKey('websiteDetailsSave'),
              label: widget.continueOnboarding
                  ? l10n.saveAndContinue
                  : l10n.line('portfolioSave'),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _swatch(int color, int selected, void Function(int value) apply) {
    return InkWell(
      onTap: () => apply(color),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Color(color),
          shape: BoxShape.circle,
          border: Border.all(
            color: selected == color ? Colors.white : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}
