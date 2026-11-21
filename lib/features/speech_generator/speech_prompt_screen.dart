import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_colors.dart';
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
    final palette = context.palette;
    final titleColor = palette.isDark ? palette.text : const Color(0xFF102A56);
    final muted = palette.isDark ? palette.textMuted : const Color(0xFF64748B);
    final examples = [
      l10n.line('speechExampleEducation'),
      l10n.line('speechExampleWater'),
      l10n.line('speechExampleUpdate'),
    ];

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SpeechHero(
                  badge: l10n.line('speechAiPowered'),
                  title: l10n.line('speechTitle'),
                  subtitle: l10n.line('speechSubtitle'),
                  titleColor: titleColor,
                  muted: muted,
                ),
                const SizedBox(height: 16),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color:
                          palette.isDark
                              ? palette.border
                              : const Color(0xFFE2EAF4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            palette.isDark
                                ? palette.cardShadow
                                : const Color(0x12102A56),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              color: Color(0xFF2563EB),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.line('speechPromptLabel'),
                                style: TextStyle(
                                  color: titleColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              '${prompt.text.length}/1000',
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          key: const Key('speech-prompt'),
                          controller: prompt,
                          minLines: 4,
                          maxLines: 6,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: onPromptChanged,
                          style: TextStyle(color: titleColor, height: 1.4),
                          decoration: InputDecoration(
                            hintText: l10n.line('speechPromptHint'),
                            hintStyle: TextStyle(color: muted),
                            filled: true,
                            fillColor:
                                palette.isDark
                                    ? palette.surfaceSecondary
                                    : const Color(0xFFF7FAFE),
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFFE2EAF4),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color:
                                    palette.isDark
                                        ? palette.border
                                        : const Color(0xFFE2EAF4),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                color: Color(0xFF2563EB),
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              color: Color(0xFFF59E0B),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.line('speechExamples'),
                              style: TextStyle(
                                color: titleColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 760 ? 3 : 1;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: examples.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columns,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    mainAxisExtent: columns == 1 ? 64 : 78,
                                  ),
                              itemBuilder: (context, index) {
                                return Material(
                                  color:
                                      palette.isDark
                                          ? palette.surfaceSecondary
                                          : const Color(0xFFF8FBFF),
                                  borderRadius: BorderRadius.circular(12),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      prompt.text = examples[index];
                                      onPromptChanged(examples[index]);
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Text(
                                        examples[index],
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: muted,
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 640 ? 2 : 2;
                            final fields = [
                              _ChoiceField(
                                icon: Icons.graphic_eq,
                                label: l10n.line('speechType'),
                                value: speechType,
                                options: speechTypeKeys,
                                l10n: l10n,
                                onChanged: onSpeechType,
                              ),
                              _ChoiceField(
                                icon: Icons.language,
                                label: l10n.line('speechLanguage'),
                                value: language,
                                options: speechLanguageKeys,
                                l10n: l10n,
                                onChanged: onLanguage,
                              ),
                              _ChoiceField(
                                icon: Icons.schedule,
                                label: l10n.line('speechDuration'),
                                value: duration,
                                options: speechDurationKeys,
                                l10n: l10n,
                                onChanged: onDuration,
                              ),
                              _ChoiceField(
                                icon: Icons.sentiment_satisfied_alt_outlined,
                                label: l10n.line('speechTone'),
                                value: tone,
                                options: speechToneKeys,
                                l10n: l10n,
                                onChanged: onTone,
                              ),
                            ];
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: fields.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        constraints.maxWidth < 420
                                            ? 1
                                            : columns,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    mainAxisExtent: 72,
                                  ),
                              itemBuilder: (context, index) => fields[index],
                            );
                          },
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            disabledBackgroundColor: const Color(0xFF93C5FD),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(52),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: canGenerate ? onGenerate : null,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.auto_awesome, size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  l10n.line('speechGenerate'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SpeechHero extends StatelessWidget {
  const _SpeechHero({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.muted,
  });

  final String badge;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(width: 6),
                Text(
                  badge,
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: wide ? 34 : 26,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: muted, fontSize: 14, height: 1.4),
        ),
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors:
              context.palette.isDark
                  ? [context.palette.surface, context.palette.backgroundRaised]
                  : const [Color(0xFFF3F8FF), Color(0xFFE7F1FF)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
        child: Row(
          children: [
            Expanded(child: copy),
            const SizedBox(width: 8),
            const _MicArt(),
          ],
        ),
      ),
    );
  }
}

class _MicArt extends StatelessWidget {
  const _MicArt();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 520;
    return SizedBox(
      width: compact ? 72 : 120,
      height: compact ? 64 : 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.graphic_eq,
            size: compact ? 56 : 92,
            color: const Color(0xFF93C5FD),
          ),
          Icon(
            Icons.mic,
            size: compact ? 34 : 52,
            color: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.l10n,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String value;
  final Map<String, String> options;
  final AppLocalizations l10n;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final titleColor = palette.isDark ? palette.text : const Color(0xFF102A56);
    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            palette.isDark ? palette.surfaceSecondary : const Color(0xFFF7FAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: palette.isDark ? palette.border : const Color(0xFFE2EAF4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF2563EB)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: palette.textMuted, fontSize: 11),
                  ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: value,
                      isExpanded: true,
                      isDense: true,
                      borderRadius: BorderRadius.circular(12),
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      items: [
                        for (final entry in options.entries)
                          DropdownMenuItem(
                            value: entry.key,
                            child: Text(
                              l10n.line(entry.value),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (selected) {
                        if (selected != null) onChanged(selected);
                      },
                    ),
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
