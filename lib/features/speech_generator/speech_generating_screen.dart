import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/widgets/app_card.dart';
import 'speech_model.dart';

class SpeechGeneratingScreen extends StatefulWidget {
  const SpeechGeneratingScreen({
    required this.generate,
    required this.onComplete,
    required this.onError,
    this.stageDelay = const Duration(milliseconds: 280),
    super.key,
  });

  final Future<GeneratedSpeech> Function() generate;
  final ValueChanged<GeneratedSpeech> onComplete;
  final VoidCallback onError;
  final Duration stageDelay;

  @override
  State<SpeechGeneratingScreen> createState() => _SpeechGeneratingScreenState();
}

class _SpeechGeneratingScreenState extends State<SpeechGeneratingScreen> {
  static const _stages = <String>[
    'speechStageTopic',
    'speechStagePoints',
    'speechStageStructure',
    'speechStageWriting',
    'speechStageFinal',
  ];

  var _done = 0;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final future = widget.generate();
    var pending = true;
    future.whenComplete(() {
      pending = false;
    });

    for (var step = 1; step < _stages.length && pending; step++) {
      await Future<void>.delayed(widget.stageDelay);
      if (!mounted) {
        return;
      }
      if (!pending) {
        break;
      }
      setState(() => _done = step);
    }

    try {
      final speech = await future;
      if (!mounted) {
        return;
      }
      setState(() => _done = _stages.length);
      widget.onComplete(speech);
    } catch (_) {
      if (!mounted) {
        return;
      }
      widget.onError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Text(l10n.line('speechCreating'), style: AppTextStyles.headline(context)),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            children: [
              for (var i = 0; i < _stages.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        i < _done
                            ? Icons.check_circle
                            : i == _done
                                ? Icons.timelapse
                                : Icons.radio_button_unchecked,
                        color: i < _done ? context.palette.secondary : context.palette.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(l10n.line(_stages[i]), style: AppTextStyles.body(context)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
