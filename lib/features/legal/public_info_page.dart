import 'package:flutter/material.dart';

import '../../app/routing/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/constants/app_assets.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/language_selector.dart';
import '../../core/widgets/theme_toggle.dart';
import 'page_meta.dart';

class PublicSection {
  const PublicSection(this.title, this.paragraphs, {this.child});

  final String title;
  final List<String> paragraphs;
  final Widget? child;
}

/// Shared public page: back button, collapsible contents, white cards.
class PublicDocument extends StatefulWidget {
  const PublicDocument({
    required this.title,
    required this.description,
    required this.sections,
    this.lead,
    super.key,
  });

  final String title;
  final String description;
  final List<PublicSection> sections;
  final Widget? lead;

  @override
  State<PublicDocument> createState() => _PublicDocumentState();
}

class _PublicDocumentState extends State<PublicDocument> {
  late List<GlobalKey> _keys = _freshKeys();
  bool? _tocOpen;

  List<GlobalKey> _freshKeys() =>
      List<GlobalKey>.generate(widget.sections.length, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    applyPageMeta('${widget.title} | VoteBanker', widget.description);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
    });
  }

  @override
  void didUpdateWidget(PublicDocument oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sections.length != widget.sections.length) {
      _keys = _freshKeys();
    }
    if (oldWidget.title != widget.title) {
      applyPageMeta('${widget.title} | VoteBanker', widget.description);
    }
  }

  @override
  void dispose() {
    restorePageMeta();
    super.dispose();
  }

  void _showSection(int index) => _reveal(index, 0);

  void _reveal(int index, int attempt) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || index >= _keys.length) return;
      final target = _keys[index].currentContext;
      final object = target?.findRenderObject();
      if (target == null || object is! RenderBox || !object.hasSize) {
        if (attempt < 6) _reveal(index, attempt + 1);
        return;
      }
      final dy = object.localToGlobal(Offset.zero).dy;
      final height = MediaQuery.sizeOf(context).height;
      if (dy < 0 || dy > height * 0.2) {
        var scrollable = Scrollable.maybeOf(target);
        while (scrollable != null) {
          final position = scrollable.position;
          if (position.hasContentDimensions && position.maxScrollExtent > 2) {
            position.ensureVisible(
              object,
              alignment: 0.06,
              duration: Duration.zero,
            );
          }
          scrollable = Scrollable.maybeOf(scrollable.context);
        }
      }
      if ((dy < 0 || dy > height * 0.2) && attempt < 6) {
        _reveal(index, attempt + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: ListView(
        children: [
          _PublicHeader(
            title: widget.title,
            onBack: () => AppNav.back(context, AppRoutes.login),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final pad = wide ? 36.0 : 16.0;
              final open = _tocOpen ?? wide;
              final toc = _Contents(
                titles: [for (final section in widget.sections) section.title],
                open: open,
                onToggle: () => setState(() => _tocOpen = !open),
                onSelect: _showSection,
              );
              final article = Column(
                children: [
                  if (widget.lead != null) ...[
                    widget.lead!,
                    const SizedBox(height: 14),
                  ],
                  for (var i = 0; i < widget.sections.length; i++) ...[
                    _SectionCard(key: _keys[i], section: widget.sections[i]),
                    const SizedBox(height: 14),
                  ],
                ],
              );
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, 24, pad, 40),
                    child:
                        wide
                            ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 280, child: toc),
                                const SizedBox(width: 20),
                                Expanded(child: article),
                              ],
                            )
                            : Column(
                              children: [
                                toc,
                                const SizedBox(height: 16),
                                article,
                              ],
                            ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PublicHeader extends StatelessWidget {
  const _PublicHeader({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              IconButton(
                key: const Key('public-back'),
                tooltip: 'Back',
                onPressed: onBack,
                icon: Icon(Icons.arrow_back, color: palette.accent),
              ),
              Image.asset(AppAssets.logo, width: 32, height: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle(
                    context,
                  ).copyWith(fontSize: 18),
                ),
              ),
              const ThemeToggle(),
              const SizedBox(width: 8),
              const LanguageSelector(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Contents extends StatelessWidget {
  const _Contents({
    required this.titles,
    required this.open,
    required this.onToggle,
    required this.onSelect,
  });

  final List<String> titles;
  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton.icon(
            key: const Key('public-toc-toggle'),
            onPressed: onToggle,
            icon: Icon(open ? Icons.expand_less : Icons.menu_book_outlined),
            label: const Align(
              alignment: Alignment.centerLeft,
              child: Text('On this page'),
            ),
          ),
          if (open)
            for (var i = 0; i < titles.length; i++)
              TextButton(
                key: Key('public-toc-$i'),
                onPressed: () => onSelect(i),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  foregroundColor: palette.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  titles[i],
                  style: AppTextStyles.body(context).copyWith(
                    color: palette.accent,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, super.key});

  final PublicSection section;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: AppTextStyles.sectionTitle(context).copyWith(fontSize: 20),
          ),
          const SizedBox(height: 10),
          for (final line in section.paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(line, style: AppTextStyles.body(context)),
            ),
          if (section.child != null) ...[
            const SizedBox(height: 8),
            section.child!,
          ],
        ],
      ),
    );
  }
}

class PublicRouteLink extends StatelessWidget {
  const PublicRouteLink({required this.label, required this.route, super.key});

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => AppNav.open(context, route),
      icon: const Icon(Icons.arrow_forward, size: 16),
      label: Text(label),
    );
  }
}
