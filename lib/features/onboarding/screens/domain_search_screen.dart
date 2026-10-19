import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../models/domain_suggestion.dart';
import '../services/domain_service.dart';
import '../state/onboarding_controller.dart';
import '../widgets/domain_result_card.dart';
import '../widgets/onboarding_actions.dart';
import '../widgets/onboarding_frame.dart';

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
    AppRouter.open(context, AppRoutes.website);
  }

  void _continueToWebsite() {
    _commit();
    AppRouter.open(context, AppRoutes.website);
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
      case 'openprovider_access_denied':
      case 'openprovider_auth_failed':
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
      return item.isPremium ? '${l10n.available} · ${l10n.premiumDomain}' : l10n.available;
    }
    if (!item.checkFailed) {
      return l10n.unavailable;
    }
    return l10n.checkFailed;
  }

  Color _availabilityColor(BuildContext context, DomainSuggestion item) {
    final palette = context.palette;
    if (item.available) {
      return palette.success;
    }
    if (!item.checkFailed) {
      return palette.textMuted;
    }
    return palette.danger;
  }

  String _formatMoney(double amount, String currency) {
    final formatted = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
    return '$formatted $currency';
  }

  String _priceLabel(AppLocalizations l10n, DomainSuggestion item) {
    final amount = item.priceAmount;
    final currency = item.priceCurrency;
    if (amount == null || currency == null || currency.isEmpty) {
      return '';
    }
    return l10n.registrationPrice
        .replaceAll('{price}', _formatMoney(amount, '').trim())
        .replaceAll('{currency}', currency);
  }

  String? _supplierPriceLabel(AppLocalizations l10n, DomainSuggestion item) {
    final amount = item.supplierPriceAmount;
    final currency = item.supplierPriceCurrency;
    if (amount == null || currency == null || currency.isEmpty) {
      return null;
    }
    if (item.priceCurrency == currency && item.priceAmount == amount) {
      return null;
    }
    return l10n.supplierPrice
        .replaceAll('{price}', _formatMoney(amount, '').trim())
        .replaceAll('{currency}', currency);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = OnboardingScope.of(context).draft;
    final typed = _query.text.trim().isNotEmpty;
    final palette = context.palette;
    final visibleResults = availableDomainsFirst(_results);

    return OnboardingFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OnboardingHeader(
                  compact: true,
                  title: l10n.domainTitle,
                  description: l10n.domainDescription,
                ),
                const SizedBox(height: 18),
                AppTextField(
                  controller: _query,
                  hint: l10n.searchPlaceholder,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.search,
                  onChanged: _onQueryChanged,
                  onSubmitted: (_) => _search(),
                  prefixIcon: Icon(Icons.search, color: palette.textMuted),
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: _searching ? l10n.domainSearching : l10n.domainSearch,
                  onPressed: _searching ? null : _search,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (_searching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorCode != null) ...[
            Text(
              _errorMessage(l10n, _errorCode!),
              style: AppTextStyles.muted(context).copyWith(color: palette.danger),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _search,
                child: Text(l10n.domainRetry),
              ),
            ),
          ] else if (!typed)
            Text(l10n.domainEmpty, style: AppTextStyles.muted(context))
          else if (_lastSearched == null)
            Text(l10n.domainSearchHint, style: AppTextStyles.muted(context))
          else if (visibleResults.isEmpty)
            Text(l10n.domainNoResults, style: AppTextStyles.muted(context))
          else ...[
            for (final item in visibleResults) ...[
              DomainResultCard(
                domain: item.name,
                availability: _availabilityLabel(l10n, item),
                availabilityColor: _availabilityColor(context, item),
                price: _priceLabel(l10n, item),
                perYear: item.priceAmount == null
                    ? ''
                    : () {
                        final supplier = _supplierPriceLabel(l10n, item);
                        return supplier == null
                            ? l10n.perYear
                            : '${l10n.perYear}\n$supplier';
                      }(),
                premiumLabel: item.isPremium ? l10n.premiumDomain : null,
                actionLabel: draft.selectedDomain == item.name
                    ? l10n.selected
                    : l10n.selectDomain,
                selected: draft.selectedDomain == item.name,
                canSelect: item.available,
                onAdd: item.available ? () => _select(item.name) : null,
              ),
              const SizedBox(height: 10),
            ],
          ],
          const SizedBox(height: 14),
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.verified_outlined,
                    color: palette.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.whiteLabelTitle,
                        style: AppTextStyles.label(context),
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.whiteLabelBody, style: AppTextStyles.muted(context)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OnboardingActions(
            backLabel: l10n.back,
            onBack: () {
              _commit();
              AppRouter.back(context, AppRoutes.profile);
            },
            primaryLabel: l10n.next,
            onPrimary: _continueToWebsite,
            skipLabel: l10n.skipForNow,
            onSkip: _continueToWebsite,
          ),
        ],
      ),
    );
  }
}
