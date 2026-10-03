import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../models/merchandise_product.dart';
import '../services/merchandise_service.dart';

class MerchandiseDesignScreen extends StatefulWidget {
  const MerchandiseDesignScreen({
    required this.product,
    this.service,
    this.onSubmit,
    super.key,
  });

  final MerchandiseProduct product;
  final MerchandiseService? service;
  final Future<void> Function(Map<String, dynamic> payload)? onSubmit;

  @override
  State<MerchandiseDesignScreen> createState() => _MerchandiseDesignScreenState();
}

class _MerchandiseDesignScreenState extends State<MerchandiseDesignScreen> {
  final _line = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _notes = TextEditingController();
  var _quantity = 1;
  var _size = '';
  var _color = '';
  var _saving = false;
  var _saved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _size = widget.product.sizes.isEmpty ? '' : widget.product.sizes.first;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_name.text.isEmpty) {
      final draft = OnboardingScope.maybeOf(context)?.draft.fullName.trim() ?? '';
      if (draft.isNotEmpty) {
        _name.text = draft;
      }
    }
    if (_phone.text.isEmpty) {
      final phone = AuthService.instance.session?.phone ?? '';
      if (phone.isNotEmpty) {
        _phone.text = phone;
      }
    }
  }

  @override
  void dispose() {
    _line.dispose();
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final line = _line.text.trim();
    final name = _name.text.trim();
    if (line.isEmpty) {
      setState(() => _error = l10n.line('merchNeedLine'));
      return;
    }
    if (name.isEmpty) {
      setState(() => _error = l10n.line('merchNeedName'));
      return;
    }

    final payload = <String, dynamic>{
      'product_slug': widget.product.slug,
      'campaign_line': line,
      'quantity': _quantity,
      'size': _size,
      'color': _color,
      'contact_name': name,
      'contact_phone': _phone.text.trim(),
      'notes': _notes.text.trim(),
    };

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final submit = widget.onSubmit;
      if (submit != null) {
        await submit(payload);
      } else {
        await (widget.service ?? MerchandiseService()).placeOrder(payload);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _saved = true;
      });
    } on MerchandiseException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = error.code == 'merchandise_not_ready'
            ? l10n.line('merchNotReady')
            : l10n.line('merchSaveError');
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = l10n.line('merchSaveError');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final product = widget.product;

    return Scaffold(
      backgroundColor: context.palette.background,
      body: AppBackground(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(_saved),
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                  Text(product.name, style: AppTextStyles.headline(context)),
                  const SizedBox(height: 8),
                  Text(product.description, style: AppTextStyles.muted(context)),
                  const SizedBox(height: 16),
                  if (_saved)
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline, color: context.palette.secondary),
                          const SizedBox(height: 12),
                          Text(l10n.line('merchSaved'), style: AppTextStyles.body(context)),
                        ],
                      ),
                    )
                  else
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _line,
                            label: l10n.line('merchCampaignLine'),
                            hint: l10n.line('merchCampaignHint'),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                          const SizedBox(height: 14),
                          Text(l10n.line('merchQuantity'), style: AppTextStyles.label(context)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                onPressed: _quantity > 1 ? () => setState(() => _quantity -= 1) : null,
                                icon: const Icon(Icons.remove),
                              ),
                              Text('$_quantity', style: AppTextStyles.headline(context).copyWith(fontSize: 22)),
                              IconButton(
                                onPressed: _quantity < 500 ? () => setState(() => _quantity += 1) : null,
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                          if (product.sizes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _ChoiceField(
                              label: l10n.line('merchSize'),
                              value: _size,
                              options: product.sizes,
                              onChanged: (value) => setState(() => _size = value),
                            ),
                          ],
                          if (product.colors.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _ChoiceField(
                              label: l10n.line('merchColor'),
                              value: _color,
                              options: product.colors,
                              allowEmpty: true,
                              emptyLabel: l10n.optionalLabel,
                              onChanged: (value) => setState(() => _color = value),
                            ),
                          ],
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _name,
                            label: l10n.line('merchContactName'),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _phone,
                            label: l10n.line('merchContactPhone'),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _notes,
                            label: l10n.line('merchNotes'),
                            maxLines: 3,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(_error!, style: AppTextStyles.body(context).copyWith(color: context.palette.danger)),
                          ],
                          const SizedBox(height: 18),
                          PrimaryButton(
                            label: _saving ? l10n.line('merchPlaceRequest') : l10n.line('merchPlaceRequest'),
                            onPressed: _saving ? () {} : _save,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChoiceField extends StatelessWidget {
  const _ChoiceField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.allowEmpty = false,
    this.emptyLabel = '',
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  final bool allowEmpty;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label(context)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value.isEmpty ? '' : value,
          isExpanded: true,
          dropdownColor: context.palette.surfaceSecondary,
          items: [
            if (allowEmpty) DropdownMenuItem(value: '', child: Text(emptyLabel)),
            for (final option in options) DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (selected) => onChanged(selected ?? ''),
        ),
      ],
    );
  }
}
