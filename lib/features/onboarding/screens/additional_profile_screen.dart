import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../state/onboarding_controller.dart';
import '../widgets/onboarding_frame.dart';

class AdditionalProfileScreen extends StatefulWidget {
  const AdditionalProfileScreen({super.key});

  @override
  State<AdditionalProfileScreen> createState() =>
      _AdditionalProfileScreenState();
}

class _AdditionalProfileScreenState extends State<AdditionalProfileScreen> {
  final _picker = ImagePicker();
  final _fields = <String, TextEditingController>{};
  final _priorities = <String>[];
  final _goals = <String>[];
  final _focus = <String>[];
  final _achievements = <Map<String, dynamic>>[];
  final _albums = <Map<String, dynamic>>[];
  final _updates = <Map<String, dynamic>>[];
  bool _restored = false;

  TextEditingController _field(String key) =>
      _fields.putIfAbsent(key, TextEditingController.new);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_restored) return;
    _restored = true;
    final saved = OnboardingScope.of(context).draft.additionalProfile;
    for (final key in const [
      'about',
      'journey',
      'education',
      'experience',
      'introduction',
      'vision',
      'mission',
      'galleryTitle',
      'galleryDate',
      'galleryLocation',
      'galleryDescription',
    ]) {
      final value = saved[key];
      if (value is String) _field(key).text = value;
    }
    _restoreStrings(_priorities, saved['priorities']);
    _restoreStrings(_goals, saved['goals']);
    _restoreStrings(_focus, saved['focusAreas']);
    _restoreMaps(_achievements, saved['achievements']);
    _restoreMaps(_albums, saved['albums']);
    _restoreMaps(_updates, saved['updates']);
  }

  void _restoreStrings(List<String> target, dynamic value) {
    if (value is List) target.addAll(value.whereType<String>());
  }

  void _restoreMaps(List<Map<String, dynamic>> target, dynamic value) {
    if (value is List) {
      target.addAll(value.whereType<Map>().map(Map<String, dynamic>.from));
    }
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _text(String key, String label, {int lines = 1}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: AppTextField(
            controller: _field(key), label: label, maxLines: lines),
      );

  Widget _section(String title, List<Widget> children) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(title,
                style: AppTextStyles.headline(context).copyWith(fontSize: 20)),
            const SizedBox(height: 14),
            ...children,
          ]),
        ),
      );

  Future<void> _addString(String label, List<String> target) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: AppTextField(controller: controller, label: label),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                target.add(controller.text.trim());
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    controller.dispose();
  }

  Widget _chips(String label, List<String> target) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Text(label)),
            TextButton.icon(
              onPressed: () => _addString(label, target),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ]),
          Wrap(
            spacing: 8,
            children: [
              for (final value in target)
                Chip(
                    label: Text(value),
                    onDeleted: () => setState(() => target.remove(value))),
            ],
          ),
        ],
      );

  Future<void> _pickMedia(List<Map<String, dynamic>> target,
      {required bool video}) async {
    final file = video
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery);
    if (file != null && mounted) {
      setState(() => target
          .add({'fileName': file.name, 'type': video ? 'video' : 'photo'}));
    }
  }

  Future<void> _addRecord(
      List<Map<String, dynamic>> target, String label) async {
    final values = <String, TextEditingController>{
      'title': TextEditingController(),
      'description': TextEditingController(),
      'date': TextEditingController(),
      'location': TextEditingController(),
    };
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: SingleChildScrollView(
          child: Column(
            children: [
              for (final entry in values.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child:
                      AppTextField(controller: entry.value, label: entry.key),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final record = <String, String>{};
              for (final entry in values.entries) {
                if (entry.value.text.trim().isNotEmpty) {
                  record[entry.key] = entry.value.text.trim();
                }
              }
              if (record.isNotEmpty) target.add(record);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    for (final controller in values.values) {
      controller.dispose();
    }
  }

  Widget _media(String label, List<Map<String, dynamic>> target) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label),
          for (final item in target)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item['fileName'] as String? ?? 'Selected file'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => setState(() => target.remove(item)),
              ),
            ),
        ],
      );

  void _save() {
    final draft = OnboardingScope.of(context).draft;
    draft.additionalProfile = {
      for (final entry in _fields.entries)
        if (entry.value.text.trim().isNotEmpty)
          entry.key: entry.value.text.trim(),
      if (_priorities.isNotEmpty) 'priorities': _priorities,
      if (_goals.isNotEmpty) 'goals': _goals,
      if (_focus.isNotEmpty) 'focusAreas': _focus,
      if (_achievements.isNotEmpty) 'achievements': _achievements,
      if (_albums.isNotEmpty) 'albums': _albums,
      if (_updates.isNotEmpty) 'updates': _updates,
    };
    AppRouter.open(context, AppRoutes.website);
  }

  @override
  Widget build(BuildContext context) => OnboardingFrame(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          IconButton(
            alignment: Alignment.centerLeft,
            onPressed: () => AppRouter.back(context, AppRoutes.profile),
            icon: const Icon(Icons.arrow_back),
          ),
          Text('Additional Leader Profile Details',
              style: AppTextStyles.headline(context)),
          Text(
            'All fields are optional. Add only what you want citizens to see.',
            style: AppTextStyles.body(context)
                .copyWith(color: context.palette.textMuted),
          ),
          const SizedBox(height: 18),
          _section('About the Leader', [
            _text('about', 'About the Leader', lines: 5),
            _text('journey', 'Political Journey', lines: 4),
            _text('education', 'Education & Background'),
            _text('experience', 'Experience in Public Service'),
            _text('introduction', 'Personal Introduction', lines: 3),
          ]),
          _section('Vision & Priorities', [
            _text('vision', 'Vision Statement', lines: 5),
            _text('mission', 'Mission Statement', lines: 4),
            _chips('Key Priorities', _priorities),
            _chips('Development Goals', _goals),
            _chips('Focus Areas', _focus),
          ]),
          _section('Achievements', [
            TextButton.icon(
              onPressed: () => _addRecord(_achievements, 'Add Achievement'),
              icon: const Icon(Icons.add),
              label: const Text('Add Another Achievement'),
            ),
            _media('Achievements (add photos below)', _achievements),
            TextButton.icon(
              onPressed: () => _pickMedia(_achievements, video: false),
              icon: const Icon(Icons.photo_outlined),
              label: const Text('Upload Achievement Photo'),
            ),
          ]),
          _section('Gallery', [
            _text('galleryTitle', 'Gallery Title / Album Name'),
            _text('galleryDate', 'Event Date'),
            _text('galleryLocation', 'Event Location'),
            _text('galleryDescription', 'Photo Description', lines: 3),
            TextButton.icon(
              onPressed: () => _addRecord(_albums, 'Create Another Album'),
              icon: const Icon(Icons.add),
              label: const Text('Create Another Album'),
            ),
            _media('Gallery files', _albums),
            Wrap(spacing: 8, children: [
              OutlinedButton.icon(
                onPressed: () => _pickMedia(_albums, video: false),
                icon: const Icon(Icons.photo_outlined),
                label: const Text('Upload Photos'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickMedia(_albums, video: true),
                icon: const Icon(Icons.videocam_outlined),
                label: const Text('Upload Videos'),
              ),
            ]),
          ]),
          _section('Community Updates', [
            TextButton.icon(
              onPressed: () => _addRecord(_updates, 'Add Another Update'),
              icon: const Icon(Icons.add),
              label: const Text('Add Another Update'),
            ),
            _media('Updates (add photos below)', _updates),
            TextButton.icon(
              onPressed: () => _pickMedia(_updates, video: false),
              icon: const Icon(Icons.photo_outlined),
              label: const Text('Upload Photos'),
            ),
          ]),
          PrimaryButton(label: 'Save & Continue', onPressed: _save),
        ]),
      );
}
