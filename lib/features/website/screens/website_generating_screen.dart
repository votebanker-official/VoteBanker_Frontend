import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../../onboarding/widgets/onboarding_frame.dart';
import '../services/website_services.dart';

class WebsiteGeneratingScreen extends StatefulWidget {
  const WebsiteGeneratingScreen({super.key});

  @override
  State<WebsiteGeneratingScreen> createState() => _WebsiteGeneratingScreenState();
}

class _WebsiteGeneratingScreenState extends State<WebsiteGeneratingScreen> {
  static const _stages = <String>[
    'genStyle',
    'genInfo',
    'genLanguage',
    'genContent',
    'genPreview',
  ];

  var _done = 0;
  var _busy = true;
  String? _errorCode;
  String? _errorHint;
  List<String> _requiredEnv = const [];
  var _requestToken = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _start();
      }
    });
  }

  Future<void> _start() async {
    final token = ++_requestToken;
    setState(() {
      _busy = true;
      _done = 0;
      _errorCode = null;
      _errorHint = null;
      _requiredEnv = const [];
    });

    final session = OnboardingScope.of(context);
    final draft = session.website;
    if (draft.description.trim().length < 12 && !draft.hasWritableContent) {
      if (!mounted || token != _requestToken) {
        return;
      }
      setState(() {
        _busy = false;
        _errorCode = 'invalid_description';
      });
      return;
    }

    var completed = false;
    final progress = () async {
      for (var step = 1; step < _stages.length; step++) {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted || token != _requestToken || completed) {
          return;
        }
        setState(() => _done = step);
      }
    }();

    try {
      final preview = await session.websiteServices.generation.generate(draft);
      completed = true;
      await progress;
      if (!mounted || token != _requestToken) {
        return;
      }
      session.website.preview = preview;
      setState(() {
        _busy = false;
        _done = _stages.length;
      });
      AppRouter.replace(context, AppRoutes.websitePreview);
    } on WebsiteGenerationException catch (error) {
      completed = true;
      if (!mounted || token != _requestToken) {
        return;
      }
      setState(() {
        _busy = false;
        _errorCode = error.code;
        _errorHint = error.hint;
        _requiredEnv = error.requiredEnv;
      });
    } catch (_) {
      completed = true;
      if (!mounted || token != _requestToken) {
        return;
      }
      setState(() {
        _busy = false;
        _errorCode = 'generation_failed';
      });
    }
  }

  String _message(AppLocalizations l10n) {
    switch (_errorCode) {
      case 'invalid_description':
        return l10n.line('websiteGenerateNeedDescription');
      case 'website_ai_not_configured':
        return l10n.line('websiteAiNotConfigured');
      case 'unreachable':
        return l10n.line('websiteGenerateUnreachable');
      default:
        return l10n.line('websiteGenerateFailed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;

    return OnboardingFrame(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OnboardingHeader(
              compact: true,
              title: l10n.line('generatingTitle'),
              description: l10n.line('generatingBody'),
            ),
            const SizedBox(height: 18),
            if (_busy) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 18),
            ],
            for (var i = 0; i < _stages.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      i < _done
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: i < _done
                          ? palette.secondary
                          : palette.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.line(_stages[i]),
                        style: AppTextStyles.body(context),
                      ),
                    ),
                  ],
                ),
              ),
            if (_errorCode != null) ...[
              const SizedBox(height: 8),
              Text(
                _message(l10n),
                style: AppTextStyles.muted(context).copyWith(color: palette.danger),
              ),
              if (_errorHint != null && _errorHint!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_errorHint!, style: AppTextStyles.muted(context)),
              ],
              if (_requiredEnv.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final item in _requiredEnv)
                  Text('• $item', style: AppTextStyles.muted(context)),
              ],
              const SizedBox(height: 16),
              PrimaryButton(
                label: l10n.domainRetry,
                onPressed: _busy ? null : _start,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    AppRouter.back(context, AppRoutes.websiteSections),
                child: Text(l10n.back),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
