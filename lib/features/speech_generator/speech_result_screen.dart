import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_card.dart';
import 'speech_download.dart';
import 'speech_model.dart';

class SpeechResultScreen extends StatefulWidget {
  const SpeechResultScreen({
    required this.speech,
    required this.onRegenerate,
    required this.onTranslate,
    required this.onEditPrompt,
    required this.onSpeechChanged,
    super.key,
  });

  final GeneratedSpeech speech;
  final VoidCallback onRegenerate;
  final ValueChanged<String> onTranslate;
  final VoidCallback onEditPrompt;
  final ValueChanged<GeneratedSpeech> onSpeechChanged;

  @override
  State<SpeechResultScreen> createState() => _SpeechResultScreenState();
}

class _SpeechResultScreenState extends State<SpeechResultScreen> {
  late final TextEditingController _title;
  late final List<TextEditingController> _sections;
  var _editing = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.speech.title);
    _sections = [
      for (final section in widget.speech.sections) TextEditingController(text: section.content),
    ];
  }

  @override
  void dispose() {
    _title.dispose();
    for (final controller in _sections) {
      controller.dispose();
    }
    super.dispose();
  }

  GeneratedSpeech _current() {
    final title = _title.text.trim().isEmpty ? widget.speech.title : _title.text.trim();
    return widget.speech.copyWith(
      title: title,
      sections: [
        for (var i = 0; i < widget.speech.sections.length; i++)
          widget.speech.sections[i].copyWith(content: _sections[i].text.trim()),
      ],
    );
  }

  Future<void> _copy(AppLocalizations l10n) async {
    await Clipboard.setData(ClipboardData(text: _document(l10n, _current())));
    if (!mounted) {
      return;
    }
    _note(l10n.line('speechCopied'));
  }

  Future<void> _download(AppLocalizations l10n) async {
    final speech = _current();
    try {
      final path = await saveSpeechDocument(speechFileName(speech.title), _document(l10n, speech));
      if (!mounted) {
        return;
      }
      _note('${l10n.line('speechSaved')} $path');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _note(l10n.line('speechSaveFailed'));
    }
  }

  String _document(AppLocalizations l10n, GeneratedSpeech speech) {
    String label(Map<String, String> keys, String value) {
      final key = keys[value];
      return key == null ? value : l10n.line(key);
    }

    return formatSpeechDocument(
      speech: speech,
      metadata: [
        '${l10n.line('speechLanguage')}: ${label(speechLanguageKeys, speech.language)}',
        '${l10n.line('speechType')}: ${label(speechTypeKeys, speech.speechType)}',
        '${l10n.line('speechDuration')}: ${label(speechDurationKeys, speech.duration)}',
        '${l10n.line('speechTone')}: ${label(speechToneKeys, speech.tone)}',
      ],
    );
  }

  void _note(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _translate(AppLocalizations l10n) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(l10n.line('speechTranslatePick')),
          children: [
            for (final entry in speechLanguageKeys.entries)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(entry.key),
                child: Text(l10n.line(entry.value)),
              ),
          ],
        );
      },
    );
    if (selected != null) {
      widget.onTranslate(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final speech = widget.speech;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        if (_editing)
          TextField(
            controller: _title,
            style: AppTextStyles.headline(context),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          )
        else
          Text(_title.text, style: AppTextStyles.headline(context)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Meta(l10n.line('speechLanguage'), _choice(l10n, speechLanguageKeys, speech.language)),
            _Meta(l10n.line('speechType'), _choice(l10n, speechTypeKeys, speech.speechType)),
            _Meta(l10n.line('speechDuration'), _choice(l10n, speechDurationKeys, speech.duration)),
            _Meta(l10n.line('speechTone'), _choice(l10n, speechToneKeys, speech.tone)),
          ],
        ),
        if (speech.isMock) ...[
          const SizedBox(height: 12),
          Text(l10n.line('speechMockNote'), style: AppTextStyles.muted(context)),
        ],
        const SizedBox(height: 16),
        for (var i = 0; i < speech.sections.length; i++) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(speech.sections[i].heading, style: AppTextStyles.label(context)),
                const SizedBox(height: 8),
                if (_editing)
                  TextField(
                    controller: _sections[i],
                    maxLines: null,
                    style: AppTextStyles.body(context),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  )
                else
                  Text(_sections[i].text, style: AppTextStyles.body(context)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= AppBreakpoints.tablet;
            final buttons = [
              _Action(
                icon: _editing ? Icons.check : Icons.edit_outlined,
                label: l10n.line(_editing ? 'speechDone' : 'speechEdit'),
                onPressed: () {
                  if (_editing) {
                    final updated = _current();
                    widget.onSpeechChanged(updated);
                  }
                  setState(() => _editing = !_editing);
                },
              ),
              _Action(
                icon: Icons.refresh,
                label: l10n.line('speechRegenerate'),
                onPressed: widget.onRegenerate,
              ),
              _Action(
                icon: Icons.copy_outlined,
                label: l10n.line('speechCopy'),
                onPressed: () => _copy(l10n),
              ),
              _Action(
                icon: Icons.download_outlined,
                label: l10n.line('speechDownload'),
                onPressed: () => _download(l10n),
              ),
              _Action(
                icon: Icons.translate,
                label: l10n.line('speechTranslate'),
                onPressed: () => _translate(l10n),
              ),
            ];
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final button in buttons) ...[
                    button,
                    const SizedBox(height: 8),
                  ],
                ],
              );
            }
            return Wrap(spacing: 8, runSpacing: 8, children: buttons);
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: widget.onEditPrompt,
            child: Text(l10n.line('speechEditPrompt')),
          ),
        ),
        Text(l10n.line('speechVoiceLater'), style: AppTextStyles.muted(context)),
      ],
    );
  }

  String _choice(AppLocalizations l10n, Map<String, String> keys, String value) {
    final key = keys[value];
    return key == null ? value : l10n.line(key);
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: context.palette.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$label: $value', style: AppTextStyles.muted(context).copyWith(fontSize: 13)),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
