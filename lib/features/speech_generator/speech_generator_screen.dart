import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/routing/app_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/language_selector.dart';
import '../../core/widgets/theme_toggle.dart';
import 'speech_generating_screen.dart';
import 'speech_model.dart';
import 'speech_prompt_screen.dart';
import 'speech_result_screen.dart';
import 'speech_service.dart';

class SpeechGeneratorScreen extends StatefulWidget {
  const SpeechGeneratorScreen({
    this.service,
    this.stageDelay = const Duration(milliseconds: 280),
    super.key,
  });

  final SpeechService? service;
  final Duration stageDelay;

  @override
  State<SpeechGeneratorScreen> createState() => _SpeechGeneratorScreenState();
}

class _SpeechGeneratorScreenState extends State<SpeechGeneratorScreen> {
  late final SpeechService _service = widget.service ?? SpeechService();
  late final TextEditingController _prompt = TextEditingController();

  var _speechType = 'Public Meeting';
  var _language = 'English';
  var _duration = '5 minutes';
  var _tone = 'Formal';
  var _phase = _SpeechPhase.form;
  var _variant = 0;
  var _requestToken = 0;
  String? _error;
  GeneratedSpeech? _speech;

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  SpeechRequest _request() {
    return SpeechRequest(
      prompt: _prompt.text.trim(),
      speechType: _speechType,
      language: _language,
      duration: _duration,
      tone: _tone,
      variant: _variant,
    );
  }

  void _generate() {
    if (_prompt.text.trim().isEmpty) {
      return;
    }
    setState(() {
      _error = null;
      _requestToken += 1;
      _phase = _SpeechPhase.generating;
    });
  }

  void _finish(GeneratedSpeech speech) {
    if (!mounted) {
      return;
    }
    setState(() {
      _speech = speech;
      _phase = _SpeechPhase.result;
    });
  }

  void _fail() {
    if (!mounted) {
      return;
    }
    setState(() {
      _phase = _SpeechPhase.form;
      _error = AppLocalizations.of(context).line('speechError');
    });
  }

  void _back() {
    if (_phase == _SpeechPhase.generating) {
      _requestToken++;
      setState(() => _phase = _SpeechPhase.form);
      return;
    }
    if (_phase == _SpeechPhase.result) {
      setState(() => _phase = _SpeechPhase.form);
      return;
    }
    AppRouter.back(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final speech = _speech;

    return Scaffold(
      backgroundColor: context.palette.background,
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _back,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        l10n.line('speechTitle'),
                        style: AppTextStyles.wordmark(context).copyWith(fontSize: 16),
                      ),
                    ),
                    const ThemeToggle(),
                    const SizedBox(width: 8),
                    const LanguageSelector(),
                  ],
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: AppBreakpoints.dashboardMaxWidth),
                    child: switch (_phase) {
                      _SpeechPhase.form => SpeechPromptScreen(
                          prompt: _prompt,
                          speechType: _speechType,
                          language: _language,
                          duration: _duration,
                          tone: _tone,
                          error: _error,
                          canGenerate: _prompt.text.trim().isNotEmpty,
                          onPromptChanged: (_) => setState(() {}),
                          onSpeechType: (value) => setState(() => _speechType = value),
                          onLanguage: (value) => setState(() => _language = value),
                          onDuration: (value) => setState(() => _duration = value),
                          onTone: (value) => setState(() => _tone = value),
                          onGenerate: _generate,
                        ),
                      _SpeechPhase.generating => SpeechGeneratingScreen(
                          key: ValueKey(_requestToken),
                          stageDelay: widget.stageDelay,
                          generate: () => _service.generate(_request()),
                          onComplete: _finish,
                          onError: _fail,
                        ),
                      _SpeechPhase.result when speech != null => SpeechResultScreen(
                          key: ValueKey('$_requestToken-${speech.language}'),
                          speech: speech,
                          onRegenerate: () {
                            _variant += 1;
                            _generate();
                          },
                          onTranslate: (language) {
                            _language = language;
                            _variant += 1;
                            _generate();
                          },
                          onEditPrompt: () => setState(() => _phase = _SpeechPhase.form),
                          onSpeechChanged: (updated) => setState(() => _speech = updated),
                        ),
                      _SpeechPhase.result => SpeechPromptScreen(
                          prompt: _prompt,
                          speechType: _speechType,
                          language: _language,
                          duration: _duration,
                          tone: _tone,
                          error: _error,
                          canGenerate: _prompt.text.trim().isNotEmpty,
                          onPromptChanged: (_) => setState(() {}),
                          onSpeechType: (value) => setState(() => _speechType = value),
                          onLanguage: (value) => setState(() => _language = value),
                          onDuration: (value) => setState(() => _duration = value),
                          onTone: (value) => setState(() => _tone = value),
                          onGenerate: _generate,
                        ),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SpeechPhase { form, generating, result }
