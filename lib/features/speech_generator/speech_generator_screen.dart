import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/routing/app_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/constants/app_assets.dart';
import '../../core/widgets/language_selector.dart';
import '../../core/widgets/theme_toggle.dart';
import '../../core/utils/person_name.dart';
import '../dashboard/widgets/dashboard_colors.dart';
import '../dashboard/widgets/dashboard_sidebar.dart';
import '../onboarding/state/onboarding_controller.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  var _speechType = 'Public Meeting';
  var _language = 'Hindi';
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
    final palette = context.palette;
    final colors = DashboardColors.of(context);
    final draft = OnboardingScope.of(context).draft;
    final pageColor =
        palette.isDark ? palette.background : const Color(0xFFF5F8FC);
    final modules = dashboardSidebarItems(l10n);

    Widget sidebar({VoidCallback? onNavigate}) {
      return DashboardSidebar(
        colors: colors,
        items: modules,
        selectedRoute: AppRoutes.speech,
        onNavigate: onNavigate,
        footer: _SpeechSidebarFooter(
          colors: colors,
          name: formatPersonName(draft.fullName),
          role: draft.designation.trim(),
          photo: draft.photoBytes,
          onStart: () => AppRouter.open(context, AppRoutes.merchandise),
        ),
      );
    }

    final form = SpeechPromptScreen(
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
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: pageColor,
          drawer:
              wide
                  ? null
                  : Drawer(
                    backgroundColor: colors.sidebar,
                    child: SafeArea(
                      child: sidebar(
                        onNavigate: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ),
          bottomNavigationBar: wide ? null : _SpeechMobileNav(colors: colors),
          body: SafeArea(
            child: Row(
              children: [
                if (wide) SizedBox(width: 248, child: sidebar()),
                Expanded(
                  child: Column(
                    children: [
                      _SpeechTopBar(
                        colors: colors,
                        wide: wide,
                        photo: draft.photoBytes,
                        onBack: _back,
                        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                      Expanded(
                        child: switch (_phase) {
                          _SpeechPhase.form => form,
                          _SpeechPhase.generating => SpeechGeneratingScreen(
                            key: ValueKey(_requestToken),
                            stageDelay: widget.stageDelay,
                            generate: () => _service.generate(_request()),
                            onComplete: _finish,
                            onError: _fail,
                          ),
                          _SpeechPhase.result when speech != null =>
                            SpeechResultScreen(
                              key: ValueKey(
                                '$_requestToken-${speech.language}',
                              ),
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
                              onEditPrompt:
                                  () => setState(
                                    () => _phase = _SpeechPhase.form,
                                  ),
                              onSpeechChanged:
                                  (updated) =>
                                      setState(() => _speech = updated),
                            ),
                          _SpeechPhase.result => form,
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _SpeechPhase { form, generating, result }

class _SpeechTopBar extends StatelessWidget {
  const _SpeechTopBar({
    required this.colors,
    required this.wide,
    required this.photo,
    required this.onBack,
    required this.onMenu,
  });

  final DashboardColors colors;
  final bool wide;
  final Uint8List? photo;
  final VoidCallback onBack;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final avatar = CircleAvatar(
      radius: 16,
      backgroundColor: colors.accentSoft,
      backgroundImage: photo == null ? null : MemoryImage(photo!),
      child:
          photo == null
              ? Icon(Icons.person, size: 18, color: colors.accent)
              : null,
    );
    final back = IconButton(
      tooltip: l10n.back,
      onPressed: onBack,
      icon: Icon(Icons.arrow_back, color: colors.accent),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.topBar,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 720;
            if (!compact && wide) {
              return Row(
                children: [
                  back,
                  const Spacer(),
                  const ThemeToggle(),
                  const SizedBox(width: 8),
                  const LanguageSelector(),
                  const SizedBox(width: 8),
                  Icon(Icons.notifications_none, color: colors.accent),
                  const SizedBox(width: 8),
                  avatar,
                ],
              );
            }
            return Column(
              children: [
                Row(
                  children: [
                    if (!wide)
                      IconButton(
                        tooltip: l10n.dashboard,
                        onPressed: onMenu,
                        icon: Icon(Icons.menu, color: colors.accent),
                      ),
                    ClipOval(
                      child: Image.asset(
                        AppAssets.logo,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.appName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    back,
                    Icon(Icons.notifications_none, color: colors.accent),
                    const SizedBox(width: 8),
                    avatar,
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    ThemeToggle(),
                    SizedBox(width: 8),
                    LanguageSelector(),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SpeechMobileNav extends StatelessWidget {
  const _SpeechMobileNav({required this.colors});

  final DashboardColors colors;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.topBar,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => AppRouter.open(context, AppRoutes.dashboard),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.home_rounded, color: colors.muted, size: 22),
                      Text(
                        l10n.dashboard,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.muted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      color: colors.muted,
                      size: 22,
                    ),
                    Text(
                      l10n.cardAnalytics,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Expanded(
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.add, color: Colors.white, size: 22),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      color: colors.muted,
                      size: 22,
                    ),
                    Text(
                      l10n.line('dashNavNotifications'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.person_outline, color: colors.muted, size: 22),
                    Text(
                      l10n.cardProfile,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeechSidebarFooter extends StatelessWidget {
  const _SpeechSidebarFooter({
    required this.colors,
    required this.name,
    required this.role,
    required this.photo,
    required this.onStart,
  });

  final DashboardColors colors;
  final String name;
  final String role;
  final Uint8List? photo;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.campaign, color: Color(0xFF2563EB)),
                  const SizedBox(height: 6),
                  Text(
                    l10n.line('dashGrowTitle'),
                    style: TextStyle(
                      color: colors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.line('dashGrowBody'),
                    style: TextStyle(color: colors.muted, fontSize: 12),
                  ),
                  TextButton(
                    onPressed: onStart,
                    child: Text(l10n.line('dashGetStarted')),
                  ),
                ],
              ),
            ),
          ),
          if (name.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: photo == null ? null : MemoryImage(photo!),
                  child:
                      photo == null
                          ? Icon(Icons.person, size: 16, color: colors.accent)
                          : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (role.isNotEmpty)
                        Text(
                          role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: colors.muted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
