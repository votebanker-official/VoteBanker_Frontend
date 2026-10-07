import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/routing/app_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/language_selector.dart';
import '../../core/widgets/theme_toggle.dart';
import 'letter_form_screen.dart';
import 'letter_model.dart';
import 'letter_preview_screen.dart';
import 'letter_service.dart';

class LetterGeneratorScreen extends StatefulWidget {
  const LetterGeneratorScreen({
    this.service,
    this.shareText,
    super.key,
  });

  final LetterService? service;
  final Future<void> Function(String text, {String? subject})? shareText;

  @override
  State<LetterGeneratorScreen> createState() => _LetterGeneratorScreenState();
}

class _LetterGeneratorScreenState extends State<LetterGeneratorScreen> {
  late final LetterService _service = widget.service ?? LetterService();
  final _senderName = TextEditingController();
  final _senderAddress = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _politicianName = TextEditingController();
  final _designationDetail = TextEditingController();
  final _constituency = TextEditingController();
  final _subject = TextEditingController();
  final _purpose = TextEditingController();
  final _message = TextEditingController();

  var _designation = '';
  var _date = DateTime.now();
  var _errors = const <String, String>{};
  var _phase = _LetterPhase.form;
  var _requestToken = 0;
  String? _error;
  GeneratedLetter? _letter;

  @override
  void dispose() {
    _senderName.dispose();
    _senderAddress.dispose();
    _mobile.dispose();
    _email.dispose();
    _politicianName.dispose();
    _designationDetail.dispose();
    _constituency.dispose();
    _subject.dispose();
    _purpose.dispose();
    _message.dispose();
    super.dispose();
  }

  LetterDraft _draft() {
    return LetterDraft(
      senderName: _senderName.text,
      senderAddress: _senderAddress.text,
      mobile: _mobile.text,
      email: _email.text,
      politicianName: _politicianName.text,
      designation: _designation,
      designationDetail: _designationDetail.text,
      constituency: _constituency.text,
      subject: _subject.text,
      purpose: _purpose.text,
      message: _message.text,
      date: _date,
    );
  }

  Future<void> _generate() async {
    final draft = _draft();
    final errors = letterFieldErrors(draft);
    if (errors.isNotEmpty) {
      setState(() {
        _errors = errors;
        _error = null;
      });
      return;
    }

    final token = ++_requestToken;
    setState(() {
      _errors = const {};
      _error = null;
      _phase = _LetterPhase.loading;
    });

    try {
      final letter = await _service.generate(draft);
      if (!mounted || token != _requestToken) {
        return;
      }
      setState(() {
        _letter = letter;
        _phase = _LetterPhase.preview;
      });
    } catch (_) {
      if (!mounted || token != _requestToken) {
        return;
      }
      setState(() {
        _phase = _LetterPhase.form;
        _error = AppLocalizations.of(context).line('letterError');
      });
    }
  }

  void _back() {
    if (_phase == _LetterPhase.loading) {
      _requestToken++;
      setState(() => _phase = _LetterPhase.form);
      return;
    }
    if (_phase == _LetterPhase.preview) {
      setState(() => _phase = _LetterPhase.form);
      return;
    }
    AppRouter.back(context, AppRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final letter = _letter;

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
                        l10n.line('letterTitle'),
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
                      _LetterPhase.loading => const _LetterLoading(),
                      _LetterPhase.preview when letter != null => LetterPreviewScreen(
                          letter: letter,
                          shareText: widget.shareText,
                          onChanged: (updated) => setState(() => _letter = updated),
                          onEditDetails: () => setState(() => _phase = _LetterPhase.form),
                        ),
                      _ => LetterFormScreen(
                          senderName: _senderName,
                          senderAddress: _senderAddress,
                          mobile: _mobile,
                          email: _email,
                          politicianName: _politicianName,
                          designation: _designation,
                          designationDetail: _designationDetail,
                          constituency: _constituency,
                          subject: _subject,
                          purpose: _purpose,
                          message: _message,
                          date: _date,
                          errors: _errors,
                          busy: false,
                          error: _error,
                          onChanged: () => setState(() {}),
                          onDesignation: (value) => setState(() => _designation = value),
                          onDate: (value) => setState(() => _date = value),
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

enum _LetterPhase { form, loading, preview }

class _LetterLoading extends StatelessWidget {
  const _LetterLoading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
      children: [
        AppCard(
          child: Column(
            children: [
              const SizedBox(height: 12),
              CircularProgressIndicator(color: context.palette.accent),
              const SizedBox(height: 16),
              Text(l10n.line('letterCreating'), style: AppTextStyles.label(context)),
              const SizedBox(height: 8),
              Text(
                l10n.line('letterCreatingBody'),
                textAlign: TextAlign.center,
                style: AppTextStyles.muted(context),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
