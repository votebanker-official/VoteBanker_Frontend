import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import 'speech_model.dart';

class SpeechPromptScreen extends StatelessWidget {
  const SpeechPromptScreen({
    required this.prompt,
    required this.speechType,
    required this.language,
    required this.duration,
    required this.tone,
    required this.onSpeechType,
    required this.onLanguage,
    required this.onDuration,
    required this.onTone,
    required this.onPromptChanged,
    required this.onGenerate,
    required this.canGenerate,
    this.error,
    super.key,
  });

  final TextEditingController prompt;
  final String speechType;
  final String language;
  final String duration;
  final String tone;
  final ValueChanged<String> onSpeechType;
  final ValueChanged<String> onLanguage;
  final ValueChanged<String> onDuration;
  final ValueChanged<String> onTone;
  final ValueChanged<String> onPromptChanged;
  final VoidCallback onGenerate;
  final bool canGenerate;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final examples = [
      l10n.line('speechExampleEducation'),
      l10n.line('speechExampleWater'),
      l10n.line('speechExampleUpdate'),
    ];

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Text(l10n.line('speechTitle'), style: AppTextStyles.headline(context)),
        const SizedBox(height: 8),
        Text(l10n.line('speechSubtitle'), style: AppTextStyles.muted(context)),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                key: const Key('speech-prompt'),
                controller: prompt,
                label: l10n.line('speechPromptLabel'),
                hint: l10n.line('speechPromptHint'),
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                onChanged: onPromptChanged,
              ),
              const SizedBox(height: 14),
              Text(l10n.line('speechExamples'), style: AppTextStyles.label(context)),
              const SizedBox(height: 8),
              for (final example in examples)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      label: Text(example, style: AppTextStyles.muted(context)),
                      onPressed: () {
                        prompt.text = example;
                        onPromptChanged(example);
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < AppBreakpoints.tablet;
            final fields = [
              _ChoiceField(
                label: l10n.line('speechType'),
                value: speechType,
                options: speechTypeKeys,
                l10n: l10n,
                onChanged: onSpeechType,
              ),
              _ChoiceField(
                label: l10n.line('speechLanguage'),
                value: language,
                options: speechLanguageKeys,
                l10n: l10n,
                onChanged: onLanguage,
              ),
              _ChoiceField(
                label: l10n.line('speechDuration'),
                value: duration,
                options: speechDurationKeys,
                l10n: l10n,
                onChanged: onDuration,
              ),
              _ChoiceField(
                label: l10n.line('speechTone'),
                value: tone,
                options: speechToneKeys,
                l10n: l10n,
                onChanged: onTone,
              ),
            ];
            if (stacked) {
              return Column(
                children: [
                  for (final field in fields) ...[
                    field,
                    const SizedBox(height: 12),
                  ],
                ],
              );
            }
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final field in fields)
                  SizedBox(width: (constraints.maxWidth - 12) / 2, child: field),
              ],
            );
          },
        ),
        if (error != null) ...[
          Text(error!, style: AppTextStyles.body(context).copyWith(color: Theme.of(context).colorScheme.error)),
          const SizedBox(height: 12),
        ],
        PrimaryButton(
          label: l10n.line('speechGenerate'),
          icon: Icons.auto_awesome_outlined,
          onPressed: canGenerate ? onGenerate : null,
        ),
      ],
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.value,
    required this.options,
    required this.l10n,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> options;
  final AppLocalizations l10n;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final entry in options.entries)
          DropdownMenuItem(
            value: entry.key,
            child: Text(l10n.line(entry.value), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}
