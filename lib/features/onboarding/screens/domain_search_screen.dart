import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/routing/app_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/onboarding_header.dart';
import '../models/domain_suggestion.dart';
import '../state/onboarding_controller.dart';
import '../widgets/domain_result_card.dart';
import '../widgets/onboarding_actions.dart';
import '../widgets/onboarding_frame.dart';

class DomainSearchScreen extends StatefulWidget {
  const DomainSearchScreen({super.key});

  @override
  State<DomainSearchScreen> createState() => _DomainSearchScreenState();
}

class _DomainSearchScreenState extends State<DomainSearchScreen> {
  var _ready = false;
  late final TextEditingController _query;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) {
      return;
    }
    _query = TextEditingController(
      text: OnboardingScope.of(context).draft.domainQuery,
    );
    _ready = true;
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
    setState(() {});
  }

  void _select(String domain) {
    OnboardingScope.of(context).selectDomain(domain);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final draft = OnboardingScope.of(context).draft;
    final suggestions = suggestDomains(_query.text);
    final typed = _query.text.trim().isNotEmpty;

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
                  onSubmitted: _onQueryChanged,
                  prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (!typed)
            Text(l10n.domainEmpty, style: AppTextStyles.muted(context))
          else if (suggestions.isEmpty)
            Text(l10n.domainNeedLatin, style: AppTextStyles.muted(context))
          else
            for (var index = 0; index < suggestions.length; index++) ...[
              if (index > 0) const SizedBox(height: 10),
              DomainResultCard(
                domain: suggestions[index].name,
                availability: l10n.available,
                price: '₹${suggestions[index].priceInr}',
                perYear: l10n.perYear,
                actionLabel: draft.selectedDomain == suggestions[index].name
                    ? l10n.selected
                    : l10n.add,
                selected: draft.selectedDomain == suggestions[index].name,
                onAdd: () => _select(suggestions[index].name),
              ),
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
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.verified_outlined,
                    color: AppColors.secondary,
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
            onPrimary: () {
              _commit();
              AppRouter.open(context, AppRoutes.dashboard);
            },
            skipLabel: l10n.skipForNow,
            onSkip: () {
              _commit();
              AppRouter.open(context, AppRoutes.dashboard);
            },
          ),
        ],
      ),
    );
  }
}
