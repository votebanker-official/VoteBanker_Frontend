import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_card.dart';
import 'letter_download.dart';
import 'letter_model.dart';
import 'letter_pdf.dart';
import 'letter_share.dart';

class LetterPreviewScreen extends StatefulWidget {
  const LetterPreviewScreen({
    required this.letter,
    required this.onChanged,
    required this.onEditDetails,
    this.shareText = shareLetterText,
    super.key,
  });

  final GeneratedLetter letter;
  final ValueChanged<GeneratedLetter> onChanged;
  final VoidCallback onEditDetails;
  final Future<void> Function(String text, {String? subject})? shareText;

  @override
  State<LetterPreviewScreen> createState() => _LetterPreviewScreenState();
}

class _LetterPreviewScreenState extends State<LetterPreviewScreen> {
  late final TextEditingController _text = TextEditingController(text: widget.letter.text);
  var _editing = false;
  var _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  String get _currentText {
    final value = _text.text.trim();
    return value.isEmpty ? widget.letter.text : value;
  }

  void _note(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copy(AppLocalizations l10n) async {
    await Clipboard.setData(ClipboardData(text: _currentText));
    if (!mounted) {
      return;
    }
    _note(l10n.line('letterCopied'));
  }

  Future<void> _download(AppLocalizations l10n) async {
    setState(() => _saving = true);
    try {
      final bytes = await buildLetterPdf(_currentText);
      final path = await saveLetterPdf(letterFileName(widget.letter.subject), bytes);
      if (!mounted) {
        return;
      }
      _note('${l10n.line('letterSaved')} $path');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _note(l10n.line('letterSaveFailed'));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _share(AppLocalizations l10n) async {
    try {
      final share = widget.shareText ?? shareLetterText;
      await share(_currentText, subject: widget.letter.subject);
    } catch (_) {
      if (!mounted) {
        return;
      }
      await Clipboard.setData(ClipboardData(text: _currentText));
      if (!mounted) {
        return;
      }
      _note(l10n.line('letterShareFailed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final buttons = [
      _Action(
        icon: _editing ? Icons.check : Icons.edit_outlined,
        label: l10n.line(_editing ? 'letterDone' : 'letterEdit'),
        onPressed: () {
          if (_editing) {
            widget.onChanged(widget.letter.copyWith(text: _currentText));
          }
          setState(() => _editing = !_editing);
        },
      ),
      _Action(
        icon: Icons.copy_outlined,
        label: l10n.line('letterCopy'),
        onPressed: () => _copy(l10n),
      ),
      _Action(
        icon: Icons.picture_as_pdf_outlined,
        label: l10n.line('letterDownload'),
        onPressed: _saving ? () {} : () => _download(l10n),
      ),
      _Action(
        icon: Icons.share_outlined,
        label: l10n.line('letterShare'),
        onPressed: () => _share(l10n),
      ),
    ];

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Text(l10n.line('letterPreview'), style: AppTextStyles.headline(context)),
        const SizedBox(height: 8),
        Text(
          widget.letter.subject,
          style: AppTextStyles.label(context),
        ),
        if (widget.letter.isMock) ...[
          const SizedBox(height: 8),
          Text(l10n.line('letterMockNote'), style: AppTextStyles.muted(context)),
        ],
        const SizedBox(height: 16),
        AppCard(
          child: _editing
              ? TextField(
                  key: const Key('letter-editor'),
                  controller: _text,
                  maxLines: null,
                  minLines: 8,
                  style: AppTextStyles.body(context),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                )
              : SelectableText(_text.text, style: AppTextStyles.body(context)),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < AppBreakpoints.tablet) {
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
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: widget.onEditDetails,
            child: Text(l10n.line('letterEditDetails')),
          ),
        ),
      ],
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
