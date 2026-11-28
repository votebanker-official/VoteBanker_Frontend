import 'package:flutter/material.dart';

import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_service.dart';

typedef PortfolioProfileLoader = Future<Map<String, dynamic>?> Function();

class MyPortfolioScreen extends StatefulWidget {
  const MyPortfolioScreen({this.loadProfile, super.key});

  final PortfolioProfileLoader? loadProfile;

  @override
  State<MyPortfolioScreen> createState() => _MyPortfolioScreenState();
}

class _MyPortfolioScreenState extends State<MyPortfolioScreen> {
  Map<String, dynamic>? _profile;
  String? _error;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile =
          await (widget.loadProfile ??
              ProfileService.instance.fetchProfileForPortfolio)();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _loading = false;
      });
    } on ProfileServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _messageFor(error.code);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Your portfolio could not be loaded. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final session = AuthService.instance.session;
    final profile = _profile ?? const <String, dynamic>{};
    final name = _value(profile, 'full_name', session?.fullName);
    final title = _value(profile, 'designation');
    final organization = _value(profile, 'organization');
    final photoUrl = _value(profile, 'profile_photo_url', session?.avatarUrl);
    final fields = <(String, String, IconData)>[
      ('Organization', organization, Icons.flag_outlined),
      ('Role', title, Icons.badge_outlined),
      (
        'Constituency',
        _value(profile, 'assembly_constituency'),
        Icons.location_city_outlined,
      ),
      ('Constituency', _value(profile, 'constituency'), Icons.map_outlined),
      ('State / Region', _value(profile, 'state_region'), Icons.place_outlined),
      (
        'Public contact',
        _value(profile, 'public_contact', session?.phone),
        Icons.phone_outlined,
      ),
      (
        'Email',
        _value(profile, 'contact_email', session?.email),
        Icons.email_outlined,
      ),
      (
        'Portfolio website',
        _value(profile, 'selected_domain'),
        Icons.language_outlined,
      ),
    ];
    final visibleFields = fields.where((field) => field.$2.isNotEmpty).toList();

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('My Portfolio'),
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            key: const Key('portfolio-refresh'),
            tooltip: 'Refresh portfolio',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _PortfolioError(message: _error!, onRetry: _load)
                : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    key: const Key('my-portfolio-content'),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    children: [
                      _IdentityCard(
                        name: name,
                        title: title,
                        organization: organization,
                        photoUrl: photoUrl,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Portfolio details',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                color: palette.text,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            key: const Key('portfolio-manage-website'),
                            onPressed:
                                () =>
                                    AppRouter.open(context, AppRoutes.website),
                            icon: const Icon(Icons.language_outlined),
                            label: const Text('Website'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (visibleFields.isEmpty)
                        _EmptyPortfolio()
                      else
                        _PortfolioDetails(fields: visibleFields),
                    ],
                  ),
                ),
      ),
    );
  }
}

String _value(Map<String, dynamic> profile, String key, [String? fallback]) {
  final value = profile[key];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback?.trim() ?? '';
}

String _messageFor(String code) {
  return switch (code) {
    'unauthorized' => 'Sign in to view your portfolio.',
    'timeout' || 'unreachable' =>
      'The profile service could not be reached. Check your connection and try again.',
    _ => 'Your portfolio could not be loaded. Please try again.',
  };
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({
    required this.name,
    required this.title,
    required this.organization,
    required this.photoUrl,
  });

  final String name;
  final String title;
  final String organization;
  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final subtitle = [
      title,
      organization,
    ].where((part) => part.isNotEmpty).join(' · ');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: palette.surfaceSecondary,
            foregroundImage:
                photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
            onForegroundImageError:
                photoUrl.isNotEmpty ? (error, stackTrace) {} : null,
            child:
                photoUrl.isEmpty
                    ? Icon(
                      Icons.person_outline,
                      size: 34,
                      color: palette.textMuted,
                    )
                    : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'My Portfolio' : name,
                  key: const Key('portfolio-name'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: palette.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: palette.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioDetails extends StatelessWidget {
  const _PortfolioDetails({required this.fields});

  final List<(String, String, IconData)> fields;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < fields.length; index++) ...[
            ListTile(
              leading: Icon(fields[index].$3, color: palette.accent),
              title: Text(
                fields[index].$1,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
              ),
              subtitle: Text(
                fields[index].$2,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: palette.text),
              ),
            ),
            if (index < fields.length - 1)
              Divider(height: 1, indent: 64, color: palette.border),
          ],
        ],
      ),
    );
  }
}

class _EmptyPortfolio extends StatelessWidget {
  const _EmptyPortfolio();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Icon(Icons.account_box_outlined, color: palette.textMuted, size: 34),
          const SizedBox(height: 10),
          Text(
            'No saved portfolio details',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: palette.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Profile information will appear here after it is saved to your account.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
          ),
        ],
      ),
    );
  }
}

class _PortfolioError extends StatelessWidget {
  const _PortfolioError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, color: palette.textMuted, size: 36),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
