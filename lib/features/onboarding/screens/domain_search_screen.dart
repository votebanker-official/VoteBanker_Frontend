import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/circular_skip_button.dart';
import '../../../core/widgets/language_selector.dart';
import '../../../core/widgets/theme_toggle.dart';
import '../models/domain_suggestion.dart';
import '../services/domain_service.dart';
import '../state/onboarding_controller.dart';
import '../widgets/domain_result_card.dart';

class DomainSearchScreen extends StatefulWidget {
  const DomainSearchScreen({super.key, this.domainService});

  final DomainService? domainService;

  @override
  State<DomainSearchScreen> createState() => _DomainSearchScreenState();
}

class _DomainSearchScreenState extends State<DomainSearchScreen> {
  var _ready = false;
  late final TextEditingController _query;
  DomainService? _domainService;

  var _searching = false;
  String? _errorCode;
  String? _serverIp;
  List<DomainSuggestion> _results = const [];
  String? _lastSearched;

  DomainService get _service =>
      _domainService ??=
          widget.domainService ??
          DomainServiceHost.maybeOf(context) ??
          DomainService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _domainService ??=
        widget.domainService ?? DomainServiceHost.maybeOf(context);
    if (_ready) {
      return;
    }
    final draft = OnboardingScope.of(context).draft;
    final name = draft.leaderName.trim();
    if (draft.domainQuery.trim().isEmpty && name.isNotEmpty) {
      draft.domainQuery = name;
    }
    _query = TextEditingController(text: draft.domainQuery);
    _ready = true;
    if (domainSlug(_query.text) != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _search();
        }
      });
    }
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _commit() {
    OnboardingScope.of(context).draft.domainQuery = _query.text.trim();
  }

  void _onQueryChanged(String value) {
    OnboardingScope.of(context).draft.domainQuery = value;
    setState(() {
      _errorCode = null;
    });
  }

  Future<void> _search() async {
    final raw = _query.text.trim();
    _commit();

    if (raw.isEmpty) {
      setState(() {
        _results = const [];
        _errorCode = null;
        _serverIp = null;
        _lastSearched = null;
      });
      return;
    }

    final slug = domainSlug(raw);
    if (slug == null) {
      setState(() {
        _results = const [];
        _errorCode = 'invalid_name';
        _serverIp = null;
        _lastSearched = null;
      });
      return;
    }

    setState(() {
      _searching = true;
      _errorCode = null;
      _serverIp = null;
      _lastSearched = slug;
    });

    try {
      final results = await _service.search(slug);
      if (!mounted) {
        return;
      }
      setState(() {
        _results = results;
        _searching = false;
        _errorCode = null;
        _serverIp = null;
      });
    } on DomainException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _results = const [];
        _searching = false;
        _errorCode = error.code;
        _serverIp = error.serverIp;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _results = const [];
        _searching = false;
        _errorCode = 'search_failed';
        _serverIp = null;
      });
    }
  }

  void _select(String domain) {
    OnboardingScope.of(context).selectDomain(domain);
    _commit();
    setState(() {});
  }

  void _continueToPurchase() {
    _commit();
    AppRouter.open(context, AppRoutes.websitePurchase);
  }

  void _skipDomain() {
    _commit();
    AppRouter.open(context, AppRoutes.speechPreview);
  }

  String _errorMessage(AppLocalizations l10n, String code) {
    switch (code) {
      case 'invalid_name':
        return l10n.domainNeedLatin;
      case 'unreachable':
      case 'openprovider_timeout':
      case 'openprovider_unreachable':
        return l10n.domainSearchUnreachable;
      case 'openprovider_not_configured':
        return l10n.domainSearchUnavailable;
      case 'openprovider_auth_failed':
        return l10n.domainSearchAuthFailed;
      case 'openprovider_access_denied':
        final ip = _serverIp;
        if (ip != null && ip.isNotEmpty) {
          return l10n.domainSearchAccessDeniedIp.replaceAll('{ip}', ip);
        }
        return l10n.domainSearchAccessDenied;
      default:
        return l10n.domainSearchError;
    }
  }

  String _availabilityLabel(AppLocalizations l10n, DomainSuggestion item) {
    if (item.available) {
      return item.isPremium
          ? '${l10n.available} · ${l10n.premiumDomain}'
          : l10n.available;
    }
    if (!item.checkFailed) {
      return l10n.unavailable;
    }
    return l10n.checkFailed;
  }

  Color _availabilityColor(DomainSuggestion item) {
    if (item.available) {
      return DomainPickerColors.available;
    }
    if (!item.checkFailed) {
      return DomainPickerColors.muted;
    }
    return const Color(0xFFD92D3F);
  }

  String? _priced(AppLocalizations l10n, double? amount, String? currency) {
    final value = customerFacingAmount(amount, currency);
    if (value == null || currency == null || currency.trim().isEmpty) {
      return null;
    }
    return '${_formatDomainMoney(value, currency)} ${l10n.domainPerYear}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = OnboardingScope.of(context).draft;
    final typed = _query.text.trim().isNotEmpty;
    final palette = context.palette;
    final visibleResults = availableDomainsFirst(_results);

    return Scaffold(
      backgroundColor: DomainPickerColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 48 || constraints.maxHeight < 48) {
              return const SizedBox.shrink();
            }
            final compact = constraints.maxWidth < 700;
            return Column(
              children: [
                _DomainTopBar(
                  showBrand: compact,
                  onBack: () {
                    _commit();
                    AppRouter.back(context, AppRoutes.website);
                  },
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          constraints.maxWidth < 700 ? 16 : 28,
                          20,
                          constraints.maxWidth < 700 ? 16 : 28,
                          20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: CircularSkipButton(onPressed: _skipDomain),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.domainTitle,
                              style: TextStyle(
                                color: DomainPickerColors.text,
                                fontSize: constraints.maxWidth < 700 ? 26 : 32,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _DomainArtBanner(
                              compact: constraints.maxWidth < 700,
                            ),
                            const SizedBox(height: 16),
                            _DomainSearchBar(
                              controller: _query,
                              hint: l10n.searchPlaceholder,
                              label:
                                  _searching
                                      ? l10n.domainSearching
                                      : l10n.domainSearch,
                              enabled: !_searching,
                              onChanged: _onQueryChanged,
                              onSearch: _search,
                            ),
                            if (!typed &&
                                !_searching &&
                                _errorCode == null) ...[
                              const SizedBox(height: 12),
                              Text(
                                l10n.domainEmpty,
                                style: const TextStyle(
                                  color: DomainPickerColors.muted,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            if (_searching)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: DomainPickerColors.blue,
                                  ),
                                ),
                              )
                            else if (_errorCode != null) ...[
                              Text(
                                _errorMessage(l10n, _errorCode!),
                                style: AppTextStyles.muted(
                                  context,
                                ).copyWith(color: palette.danger),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: _search,
                                  child: Text(l10n.domainRetry),
                                ),
                              ),
                            ] else if (typed && _lastSearched == null)
                              Text(
                                l10n.domainSearchHint,
                                style: const TextStyle(
                                  color: DomainPickerColors.muted,
                                ),
                              )
                            else if (typed && visibleResults.isEmpty)
                              Text(
                                l10n.domainNoResults,
                                style: const TextStyle(
                                  color: DomainPickerColors.muted,
                                ),
                              )
                            else if (typed)
                              _DomainGrid(
                                maxWidth: constraints.maxWidth,
                                children: [
                                  for (final item in visibleResults)
                                    DomainResultCard(
                                      compact: constraints.maxWidth < 700,
                                      domain: item.name,
                                      availability: _availabilityLabel(
                                        l10n,
                                        item,
                                      ),
                                      availabilityColor: _availabilityColor(
                                        item,
                                      ),
                                      registrationLabel:
                                          l10n.domainRegistration,
                                      registrationPrice:
                                          _priced(
                                            l10n,
                                            item.priceAmount,
                                            item.priceCurrency,
                                          ) ??
                                          '',
                                      renewalLabel: l10n.domainRenewal,
                                      renewalPrice:
                                          _priced(
                                            l10n,
                                            item.renewalPriceAmount,
                                            item.renewalPriceCurrency,
                                          ) ??
                                          '',
                                      premiumLabel:
                                          item.isPremium
                                              ? l10n.premiumDomain
                                              : null,
                                      actionLabel: l10n.selectDomain,
                                      selected:
                                          draft.selectedDomain == item.name,
                                      canSelect: item.available,
                                      onAdd:
                                          item.available
                                              ? () => _select(item.name)
                                              : null,
                                    ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            _DomainTip(text: l10n.domainTip),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _DomainFooter(
                  backLabel: l10n.back,
                  continueLabel: l10n.domainContinue,
                  onBack: () {
                    _commit();
                    AppRouter.back(context, AppRoutes.website);
                  },
                  onContinue: _continueToPurchase,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _formatDomainMoney(double amount, String currency) {
  final code = currency.trim().toUpperCase();
  final negative = amount < 0;
  final absolute = amount.abs();
  final decimals = absolute == absolute.roundToDouble() ? 0 : 2;
  final fixed = absolute.toStringAsFixed(decimals);
  final pieces = fixed.split('.');
  final digits = pieces[0];
  final grouped = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final remaining = digits.length - i;
    if (i > 0 && remaining % 3 == 0) {
      grouped.write(',');
    }
    grouped.write(digits[i]);
  }
  final fraction = pieces.length > 1 ? '.${pieces[1]}' : '';
  final number = '${negative ? '-' : ''}$grouped$fraction';
  return switch (code) {
    'INR' => '₹$number',
    'USD' => '\$$number',
    _ => '$number $code',
  };
}

class _DomainTopBar extends StatelessWidget {
  const _DomainTopBar({required this.showBrand, required this.onBack});

  final bool showBrand;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = Text(
      l10n.appName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: DomainPickerColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
    final logo = ClipOval(
      child: Image.asset(
        AppAssets.logo,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        semanticLabel: l10n.appName,
      ),
    );
    final backButton = IconButton(
      tooltip: l10n.back,
      visualDensity: VisualDensity.compact,
      onPressed: onBack,
      icon: const Icon(Icons.arrow_back, color: DomainPickerColors.text),
    );
    const controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [ThemeToggle(), SizedBox(width: 8), LanguageSelector()],
    );

    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: DomainPickerColors.cardBorder),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child:
              showBrand
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          backButton,
                          logo,
                          const SizedBox(width: 8),
                          Expanded(child: name),
                        ],
                      ),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: controls,
                        ),
                      ),
                    ],
                  )
                  : const Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: controls,
                    ),
                  ),
        ),
      ),
    );
  }
}

class _DomainSearchBar extends StatelessWidget {
  const _DomainSearchBar({
    required this.controller,
    required this.hint,
    required this.label,
    required this.enabled,
    required this.onChanged,
    required this.onSearch,
  });

  final TextEditingController controller;
  final String hint;
  final String label;
  final bool enabled;
  final ValueChanged<String> onChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      enabled: enabled,
      textInputAction: TextInputAction.search,
      textCapitalization: TextCapitalization.words,
      onChanged: onChanged,
      onSubmitted: (_) => onSearch(),
      style: const TextStyle(
        color: DomainPickerColors.text,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: DomainPickerColors.blue,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: const TextStyle(
          color: DomainPickerColors.muted,
          fontSize: 15,
        ),
        prefixIcon: const Icon(Icons.search, color: DomainPickerColors.muted),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: _border(DomainPickerColors.cardBorder, 1),
        enabledBorder: _border(DomainPickerColors.cardBorder, 1),
        disabledBorder: _border(DomainPickerColors.cardBorder, 1),
        focusedBorder: _border(DomainPickerColors.blue, 1.4),
      ),
    );

    final button = ElevatedButton(
      key: const ValueKey('domainSearchButton'),
      onPressed: enabled ? onSearch : null,
      style: ButtonStyle(
        elevation: const WidgetStatePropertyAll(0),
        minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return DomainPickerColors.blue.withValues(alpha: 0.45);
          }
          if (states.contains(WidgetState.pressed)) {
            return DomainPickerColors.bluePressed;
          }
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused)) {
            return const Color(0xFF0860C8);
          }
          return DomainPickerColors.blue;
        }),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final iconOnly = constraints.maxWidth < 560;
        final action =
            iconOnly
                ? SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    key: const ValueKey('domainSearchButton'),
                    onPressed: enabled ? onSearch : null,
                    style: ButtonStyle(
                      elevation: const WidgetStatePropertyAll(0),
                      padding: const WidgetStatePropertyAll(EdgeInsets.zero),
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.disabled)) {
                          return DomainPickerColors.blue.withValues(
                            alpha: 0.45,
                          );
                        }
                        if (states.contains(WidgetState.pressed)) {
                          return DomainPickerColors.bluePressed;
                        }
                        return DomainPickerColors.blue;
                      }),
                      foregroundColor: const WidgetStatePropertyAll(
                        Colors.white,
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    child: const Icon(Icons.search, size: 22),
                  ),
                )
                : button;
        return Row(
          children: [Expanded(child: field), const SizedBox(width: 10), action],
        );
      },
    );
  }

  OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _DomainGrid extends StatelessWidget {
  const _DomainGrid({required this.maxWidth, required this.children});

  final double maxWidth;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final columns =
        maxWidth >= 1040
            ? 3
            : maxWidth >= 700
            ? 2
            : 1;
    const gap = 16.0;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final slice = children.sublist(
        i,
        i + columns > children.length ? children.length : i + columns,
      );
      rows.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: i + columns < children.length ? gap : 0,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) const SizedBox(width: gap),
                Expanded(
                  child: j < slice.length ? slice[j] : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _DomainFooter extends StatelessWidget {
  const _DomainFooter({
    required this.backLabel,
    required this.continueLabel,
    required this.onBack,
    required this.onContinue,
  });

  final String backLabel;
  final String continueLabel;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      shadowColor: const Color(0x140969DA),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: DomainPickerColors.cardBorder)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 700;
                    final back = _FooterButton(
                      label: backLabel,
                      icon: Icons.arrow_back,
                      filled: false,
                      onPressed: onBack,
                    );
                    final next = _FooterButton(
                      label: continueLabel,
                      icon: Icons.arrow_forward,
                      iconAtEnd: true,
                      filled: true,
                      onPressed: onContinue,
                    );
                    if (compact) {
                      return Row(
                        children: [
                          Expanded(child: back),
                          const SizedBox(width: 10),
                          Expanded(child: next),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        SizedBox(width: 148, child: back),
                        const Spacer(),
                        SizedBox(width: 176, child: next),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onPressed,
    this.iconAtEnd = false,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onPressed;
  final bool iconAtEnd;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!iconAtEnd) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        if (iconAtEnd) ...[const SizedBox(width: 6), Icon(icon, size: 18)],
      ],
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    const padding = WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
    if (filled) {
      return SizedBox(
        height: 48,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ButtonStyle(
            elevation: const WidgetStatePropertyAll(0),
            padding: padding,
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.pressed)) {
                return DomainPickerColors.bluePressed;
              }
              if (states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)) {
                return const Color(0xFF0860C8);
              }
              return DomainPickerColors.blue;
            }),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
            shape: WidgetStatePropertyAll(shape),
          ),
          child: child,
        ),
      );
    }
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          padding: padding,
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return DomainPickerColors.blue;
            }
            return DomainPickerColors.text;
          }),
          side: const WidgetStatePropertyAll(
            BorderSide(color: DomainPickerColors.blue),
          ),
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          shape: WidgetStatePropertyAll(shape),
        ),
        child: child,
      ),
    );
  }
}

class _DomainArtBanner extends StatelessWidget {
  const _DomainArtBanner({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 78 : 104,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFE4F0FF), Color(0xFFF5F9FF), Color(0xFFE7F2FF)],
        ),
        border: Border.all(color: const Color(0xFFD5E6F8)),
      ),
      child: Row(
        children: [
          SizedBox(width: compact ? 16 : 28),
          _GlobeBadge(size: compact ? 42 : 52),
          const Spacer(),
          _BrowserArt(compact: compact),
          SizedBox(width: compact ? 12 : 28),
        ],
      ),
    );
  }
}

class _GlobeBadge extends StatelessWidget {
  const _GlobeBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFD5E6F8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140969DA),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.public,
        color: DomainPickerColors.blue,
        size: size * 0.62,
      ),
    );
  }
}

class _BrowserArt extends StatelessWidget {
  const _BrowserArt({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 108.0 : 148.0;
    return SizedBox(
      width: width + 28,
      height: compact ? 64 : 84,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            top: 0,
            child: Icon(
              Icons.public,
              size: compact ? 46 : 62,
              color: DomainPickerColors.blue.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: Container(
              width: width,
              height: compact ? 46 : 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD5E6F8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A0969DA),
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    height: compact ? 14 : 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F8FF),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(11),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        for (final color in const [
                          Color(0xFF8FB6EA),
                          Color(0xFFB7D0F3),
                          Color(0xFFD5E6F8),
                        ]) ...[
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 3),
                        ],
                      ],
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'www.',
                        style: TextStyle(
                          color: DomainPickerColors.blue,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: compact ? 18 : 26,
            bottom: compact ? 2 : 4,
            child: Icon(
              Icons.near_me,
              size: compact ? 16 : 20,
              color: DomainPickerColors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

class _DomainTip extends StatelessWidget {
  const _DomainTip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFFEAF3FF), Color(0xFFF8FBFF)],
        ),
        border: Border.all(color: const Color(0xFFD5E6F8)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF4D6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              size: 16,
              color: Color(0xFFE0A106),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: DomainPickerColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
