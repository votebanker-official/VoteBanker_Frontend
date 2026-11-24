import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/routing/app_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/utils/person_name.dart';
import '../../core/widgets/language_selector.dart';
import '../../core/widgets/theme_toggle.dart';
import '../onboarding/data/profile_languages.dart';
import '../onboarding/state/onboarding_controller.dart';
import 'speech_preview_drafts.dart';
import 'speech_preview_speaker.dart';

const _fallbackLeaderName = 'Rajesh Sharma';
const _fallbackPartyName = 'Janata Vikas Party';
const _placeholderPhoto = 'assets/images/profile/leader-avatar-placeholder.jpg';

class SpeechPreviewScreen extends StatefulWidget {
  const SpeechPreviewScreen({this.speaker, super.key});

  final SpeechPreviewSpeaker? speaker;

  @override
  State<SpeechPreviewScreen> createState() => _SpeechPreviewScreenState();
}

class _SpeechPreviewScreenState extends State<SpeechPreviewScreen> {
  late final SpeechPreviewSpeaker _speaker = widget.speaker ?? createSpeechPreviewSpeaker();
  String? _profileName;
  String? _profileParty;
  String? _profilePhotoUrl;
  var _playing = false;
  var _playToken = 0;
  String? _spokenLanguage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = _languageCode();
    if (_playing && _spokenLanguage != language) {
      _playToken++;
      _speaker.stop();
      _playing = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _playToken++;
    _speaker.stop();
    super.dispose();
  }

  String _languageCode() {
    final code = Localizations.localeOf(context).languageCode;
    return ProfileLanguages.supports(code) ? code : 'en';
  }

  Future<void> _loadProfile() async {
    if (!AuthService.instance.isSignedIn) return;
    final profile = await ProfileService.instance.fetchProfile();
    if (!mounted) return;
    final draft = OnboardingScope.maybeOf(context)?.draft;
    if (profile != null && draft != null) {
      ProfileService.applyProfile(draft, profile);
    }
    setState(() {
      _profileName = _text(profile?['full_name']);
      _profileParty = _text(profile?['organization']);
      _profilePhotoUrl = ProfileService.photoUrlFromProfile(profile ?? const {});
    });
  }

  String? _text(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _first(String? primary, String? secondary, String fallback) {
    if (primary != null && primary.trim().isNotEmpty) return primary.trim();
    if (secondary != null && secondary.trim().isNotEmpty) return secondary.trim();
    return fallback;
  }

  Future<void> _copy(String speech) async {
    await Clipboard.setData(ClipboardData(text: speech));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Speech copied')),
    );
  }

  void _toggleSpeech(String speech, String language) {
    if (_playing) {
      _playToken++;
      _speaker.stop();
      setState(() => _playing = false);
      return;
    }
    final token = ++_playToken;
    final message = _speaker.speak(
      text: speech,
      languageCode: language,
      onDone: () {
        if (!mounted || token != _playToken) return;
        setState(() => _playing = false);
      },
    );
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    setState(() {
      _playing = true;
      _spokenLanguage = language;
    });
  }

  void _openSpeech() {
    _playToken++;
    _speaker.stop();
    AppRouter.open(context, AppRoutes.speech);
  }

  void _skip() {
    _playToken++;
    _speaker.stop();
    if (!mounted) return;
    AppRouter.open(context, AppRoutes.social);
  }

  @override
  Widget build(BuildContext context) {
    final draft = OnboardingScope.maybeOf(context)?.draft;
    final signedIn = AuthService.instance.isSignedIn;
    final name = formatPersonName(
      signedIn
          ? _first(_profileName, draft?.leaderName, _fallbackLeaderName)
          : _fallbackLeaderName,
    );
    final party = signedIn
        ? _first(_profileParty, draft?.party, _fallbackPartyName)
        : _fallbackPartyName;
    final language = _languageCode();
    final speech = speechPreviewDraft(
      languageCode: language,
      leaderName: name,
      partyName: party,
    );
    final photoBytes = signedIn ? draft?.photoBytes : null;
    final photoUrl = signedIn
        ? (_profilePhotoUrl ??
            ((draft?.profilePhotoUrl.trim().isNotEmpty ?? false)
                ? draft!.profilePhotoUrl.trim()
                : null))
        : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 800;
            return Column(
              children: [
                _TopBar(wide: wide, onSkip: _skip),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(wide ? 40 : 24, wide ? 8 : 4, wide ? 40 : 24, 12),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: _PreviewCard(
                          wide: wide,
                          name: name,
                          party: party,
                          speech: speech,
                          rtl: speechPreviewRtlLanguages.contains(language),
                          playing: _playing,
                          photoBytes: photoBytes,
                          photoUrl: photoUrl,
                          onCopy: () => _copy(speech),
                          onListen: () => _toggleSpeech(speech, language),
                          onGenerate: _openSpeech,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.wide, required this.onSkip});

  final bool wide;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            key: const Key('speech-preview-back'),
            tooltip: 'Back',
            onPressed: () => AppRouter.back(context, AppRoutes.website),
            icon: const Icon(Icons.arrow_back),
          ),
          if (wide)
            const Expanded(
              child: Text(
                'Speech Generator',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            )
          else
            const Spacer(),
          _SkipNowButton(onPressed: onSkip),
          const SizedBox(width: 8),
          LanguageSelector(maxWidth: wide ? 168 : 120),
          const SizedBox(width: 8),
          const ThemeToggle(),
        ],
      ),
    );
  }
}

class _SkipNowButton extends StatelessWidget {
  const _SkipNowButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground = palette.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569);
    return TextButton(
      key: const Key('speech-preview-skip'),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: foreground,
        backgroundColor: palette.surfaceSecondary,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: palette.border),
        ),
      ),
      child: const Text('Skip Now'),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.wide,
    required this.name,
    required this.party,
    required this.speech,
    required this.rtl,
    required this.playing,
    required this.onCopy,
    required this.onListen,
    required this.onGenerate,
    this.photoBytes,
    this.photoUrl,
  });

  final bool wide;
  final String name;
  final String party;
  final String speech;
  final bool rtl;
  final bool playing;
  final Uint8List? photoBytes;
  final String? photoUrl;
  final VoidCallback onCopy;
  final VoidCallback onListen;
  final VoidCallback onGenerate;

  @override
  Widget build(BuildContext context) {
    const title = 'Speech Generator';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Color(0x14102A56), blurRadius: 28, offset: Offset(0, 12)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(wide ? 28 : 16, wide ? 22 : 16, wide ? 28 : 16, wide ? 20 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _AiBadge(),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: wide ? 32 : 26,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _ListenButton(playing: playing, onPressed: onListen),
              ],
            ),
            SizedBox(height: wide ? 18 : 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LeaderPhoto(photoBytes: photoBytes, photoUrl: photoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        key: const Key('speech-preview-name'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          child: Text(
                            party,
                            key: const Key('speech-preview-party'),
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _CopyButton(wide: wide, onPressed: onCopy),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8EEF6)),
                ),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Directionality(
                      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                      child: Text(
                        speech,
                        key: const Key('speech-preview-draft'),
                        textAlign: rtl ? TextAlign.right : TextAlign.left,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 16,
                          height: 1.7,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _GenerateButton(onPressed: onGenerate),
          ],
        ),
      ),
    );
  }
}

class _GenerateButton extends StatelessWidget {
  const _GenerateButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        key: const Key('speech-preview-generate'),
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        icon: const Icon(Icons.auto_awesome, size: 18),
        label: const Text('Generate your speech for free'),
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: Color(0xFFEFF6FF),
        borderRadius: BorderRadius.all(Radius.circular(999)),
        border: Border.fromBorderSide(BorderSide(color: Color(0xFF93C5FD))),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 14, color: Color(0xFF2563EB)),
            SizedBox(width: 6),
            Text(
              'AI Powered',
              style: TextStyle(
                color: Color(0xFF2563EB),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListenButton extends StatelessWidget {
  const _ListenButton({required this.playing, required this.onPressed});

  final bool playing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final background = playing ? const Color(0xFF2563EB) : const Color(0xFFEFF6FF);
    final foreground = playing ? Colors.white : const Color(0xFF2563EB);
    return Tooltip(
      message: playing ? 'Stop' : 'Listen',
      child: Material(
        color: background,
        shape: const CircleBorder(
          side: BorderSide(color: Color(0xFF93C5FD), width: 1.5),
        ),
        child: InkWell(
          key: const Key('speech-preview-listen'),
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 64,
            height: 64,
            child: Icon(
              playing ? Icons.stop_rounded : Icons.mic_none_rounded,
              color: foreground,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderPhoto extends StatelessWidget {
  const _LeaderPhoto({this.photoBytes, this.photoUrl});

  final Uint8List? photoBytes;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    Widget? photo;
    if (photoBytes != null) {
      photo = Image.memory(
        photoBytes!,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    } else if (photoUrl != null && photoUrl!.isNotEmpty) {
      photo = Image.network(
        photoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const SizedBox.shrink();
        },
      );
    } else {
      photo = Image.asset(
        _placeholderPhoto,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
    }
    return ClipOval(
      child: SizedBox(
        key: const Key('speech-preview-photo'),
        width: 56,
        height: 56,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(
              key: Key('speech-preview-avatar-fallback'),
              painter: _LeaderPortraitPainter(),
            ),
            photo,
          ],
        ),
      ),
    );
  }
}

class _LeaderPortraitPainter extends CustomPainter {
  const _LeaderPortraitPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(
      rect,
      Paint()..color = const Color(0xFFDBEAFE),
    );
    final shoulder = Paint()..color = const Color(0xFF334155);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.92),
        width: size.width * 0.92,
        height: size.height * 0.46,
      ),
      shoulder,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.78),
          width: size.width * 0.34,
          height: size.height * 0.16,
        ),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFF8FAFC),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.42),
        width: size.width * 0.46,
        height: size.height * 0.5,
      ),
      Paint()..color = const Color(0xFFD4A574),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.34),
        width: size.width * 0.5,
        height: size.height * 0.28,
      ),
      Paint()..color = const Color(0xFF475569),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.wide, required this.onPressed});

  final bool wide;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (!wide) {
      return IconButton(
        key: const Key('speech-preview-copy'),
        tooltip: 'Copy Speech',
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: const Color(0xFFF8FAFC),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF475569)),
      );
    }
    return TextButton.icon(
      key: const Key('speech-preview-copy'),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF475569),
        backgroundColor: const Color(0xFFF8FAFC),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      icon: const Icon(Icons.copy_rounded, size: 16),
      label: const Text('Copy Draft', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
