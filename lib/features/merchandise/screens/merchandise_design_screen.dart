import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/localization/app_localizations.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/profile_service.dart';
import '../../../core/services/theme_controller.dart';
import '../../../core/widgets/app_background.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/language_selector.dart';
import '../../onboarding/state/onboarding_controller.dart';
import '../models/merchandise_product.dart';
import '../services/merchandise_service.dart';
import '../widgets/merchandise_preview.dart';

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
  final _picker = ImagePicker();
  Uint8List? _photoBytes;
  var _quantity = 1;
  var _size = '';
  var _color = '';
  var _saving = false;
  var _saved = false;
  var _seeded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _size = widget.product.sizes.isEmpty ? '' : widget.product.sizes.first;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) {
      return;
    }
    _seeded = true;
    final draft = OnboardingScope.maybeOf(context)?.draft.fullName.trim() ?? '';
    if (draft.isNotEmpty) {
      _name.text = draft;
    }
    final phone = AuthService.instance.session?.phone ?? '';
    if (phone.isNotEmpty) {
      _phone.text = phone;
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
      if (_photoBytes != null) 'campaign_photo': base64Encode(_photoBytes!),
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

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
        requestFullMetadata: false,
      );
      if (file == null) {
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      if (bytes.length > ProfileService.maxPhotoBytes ||
          ProfileService.photoContentType(bytes) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.photoError)),
        );
        return;
      }
      setState(() => _photoBytes = bytes);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.photoError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: AppBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final form = _FormCard(
                product: product,
                line: _line,
                name: _name,
                phone: _phone,
                notes: _notes,
                quantity: _quantity,
                size: _size,
                color: _color,
                photoBytes: _photoBytes,
                onLine: (value) => setState(() {}),
                onQuantity: (value) => setState(() => _quantity = value),
                onSize: (value) => setState(() => _size = value),
                onColor: (value) => setState(() => _color = value),
                onPickPhoto: _pickPhoto,
                onRemovePhoto: () => setState(() => _photoBytes = null),
              );
              final preview = _PreviewColumn(
                product: product,
                line: _line.text,
                photoBytes: _photoBytes,
                size: _size,
                color: _color,
                quantity: _quantity,
                saving: _saving,
                saved: _saved,
                error: _error,
                onSave: _saving || _saved ? null : _save,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(product: product),
                    const SizedBox(height: 18),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _StepRail(),
                          const SizedBox(width: 8),
                          Expanded(flex: 12, child: form),
                          const SizedBox(width: 18),
                          Expanded(flex: 10, child: preview),
                        ],
                      )
                    else ...[
                      const _StepRail(horizontal: true),
                      const SizedBox(height: 14),
                      form,
                      const SizedBox(height: 16),
                      preview,
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.product});

  final MerchandiseProduct product;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Material(
              color: palette.surface,
              shape: CircleBorder(side: BorderSide(color: palette.border)),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).pop(),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.arrow_back, size: 18),
                ),
              ),
            ),
            const Spacer(),
            const LanguageSelector(),
            const SizedBox(width: 8),
            const _ModePill(),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          '${product.name} ${l10n.line('merchConfigSuffix')}',
          style: AppTextStyles.headline(context).copyWith(fontSize: 28),
        ),
        const SizedBox(height: 2),
        Text(product.description, style: AppTextStyles.muted(context)),
      ],
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final controller = ThemeScope.of(context);
    final label = palette.isDark ? l10n.line('merchLightMode') : l10n.line('merchDarkMode');
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: controller.toggle,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                palette.isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 18,
                color: palette.text,
              ),
              const SizedBox(width: 8),
              Text(label, style: AppTextStyles.label(context).copyWith(fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRail extends StatelessWidget {
  const _StepRail({this.horizontal = false});

  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      for (var number = 1; number <= 3; number++)
        _StepDot(number: number, label: '${l10n.line('merchStep')} $number'),
    ];
    if (horizontal) {
      return Row(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            if (index > 0) const SizedBox(width: 18),
            steps[index],
          ],
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            if (index > 0) const _StepLine(),
            steps[index],
          ],
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.number, required this.label});

  final int number;
  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFF2E9BDB),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.muted(context).copyWith(fontSize: 11, color: palette.textMuted)),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 72,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: const Color(0xFFD5E3F0),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.product,
    required this.line,
    required this.name,
    required this.phone,
    required this.notes,
    required this.quantity,
    required this.size,
    required this.color,
    required this.photoBytes,
    required this.onLine,
    required this.onQuantity,
    required this.onSize,
    required this.onColor,
    required this.onPickPhoto,
    required this.onRemovePhoto,
  });

  final MerchandiseProduct product;
  final TextEditingController line;
  final TextEditingController name;
  final TextEditingController phone;
  final TextEditingController notes;
  final int quantity;
  final String size;
  final String color;
  final Uint8List? photoBytes;
  final ValueChanged<String> onLine;
  final ValueChanged<int> onQuantity;
  final ValueChanged<String> onSize;
  final ValueChanged<String> onColor;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: palette.cardShadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(
              icon: Icons.list_alt_outlined,
              title: l10n.line('merchItemDetails'),
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: line,
              label: l10n.line('merchCampaignLine'),
              hint: l10n.line('merchCampaignHint'),
              textCapitalization: TextCapitalization.sentences,
              onChanged: onLine,
            ),
            const SizedBox(height: 12),
            _PrintPhotoPicker(
              photoBytes: photoBytes,
              onPick: onPickPhoto,
              onRemove: onRemovePhoto,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _QuantityField(
                    label: l10n.line('merchQuantity'),
                    quantity: quantity,
                    onChanged: onQuantity,
                  ),
                ),
                if (product.sizes.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SizeField(
                      label: l10n.line('merchSize'),
                      value: size,
                      options: product.sizes,
                      onChanged: onSize,
                    ),
                  ),
                ],
              ],
            ),
            if (product.colors.isNotEmpty) ...[
              const SizedBox(height: 16),
              _ColorLabel(
                colour: l10n.line('merchColor'),
                optional: l10n.line('merchColorOptional'),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ColorChip(
                    label: l10n.line('merchStandard'),
                    selected: color.isEmpty,
                    onTap: () => onColor(''),
                  ),
                  for (final option in product.colors)
                    _ColorChip(
                      label: option,
                      selected: color == option,
                      onTap: () => onColor(option),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            _SectionRule(title: l10n.line('merchContactInfo')),
            const SizedBox(height: 14),
            AppTextField(
              controller: name,
              label: l10n.line('merchContactName'),
              hint: l10n.line('merchContactName'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            AppTextField(
              controller: phone,
              label: l10n.line('merchContactPhone'),
              hint: l10n.line('merchContactPhone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 22),
            _SectionRule(title: l10n.line('merchNotesSection')),
            const SizedBox(height: 14),
            AppTextField(
              controller: notes,
              label: l10n.line('merchNotes'),
              hint: l10n.line('merchNotes'),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: palette.surfaceSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: palette.textMuted),
        ),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.label(context).copyWith(fontSize: 16)),
      ],
    );
  }
}

class _SectionRule extends StatelessWidget {
  const _SectionRule({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      children: [
        Text(title, style: AppTextStyles.label(context).copyWith(fontSize: 16)),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: palette.border, height: 1)),
      ],
    );
  }
}

class _ColorLabel extends StatelessWidget {
  const _ColorLabel({required this.colour, required this.optional});

  final String colour;
  final String optional;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: colour,
        style: AppTextStyles.label(context).copyWith(fontSize: 13, color: context.palette.textMuted),
        children: [
          TextSpan(text: '  $optional'),
        ],
      ),
    );
  }
}

class _QuantityField extends StatelessWidget {
  const _QuantityField({
    required this.label,
    required this.quantity,
    required this.onChanged,
  });

  final String label;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label(context).copyWith(fontSize: 13, color: palette.textMuted)),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.border),
          ),
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                _StepperButton(
                  icon: Icons.remove,
                  onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
                ),
                Expanded(
                  child: Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.label(context).copyWith(fontSize: 16),
                  ),
                ),
                _StepperButton(
                  icon: Icons.add,
                  onPressed: quantity < 500 ? () => onChanged(quantity + 1) : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      color: context.palette.textMuted,
    );
  }
}

class _SizeField extends StatelessWidget {
  const _SizeField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.label(context).copyWith(fontSize: 13, color: palette.textMuted)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          borderRadius: BorderRadius.circular(14),
          dropdownColor: palette.surface,
          icon: Icon(Icons.keyboard_arrow_down, color: palette.textMuted),
          decoration: InputDecoration(
            filled: true,
            fillColor: palette.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          items: [
            for (final option in options)
              DropdownMenuItem(value: option, child: Text(option)),
          ],
          onChanged: (selected) {
            if (selected != null) {
              onChanged(selected);
            }
          },
        ),
      ],
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = const Color(0xFF2E9BDB);
    return Material(
      color: selected ? accent.withValues(alpha: 0.12) : palette.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? accent : palette.border),
          ),
          child: Text(
            label,
            style: AppTextStyles.label(context).copyWith(
              fontSize: 13,
              color: selected ? accent : palette.textMuted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrintPhotoPicker extends StatelessWidget {
  const _PrintPhotoPicker({
    required this.photoBytes,
    required this.onPick,
    required this.onRemove,
  });

  final Uint8List? photoBytes;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    final hasPhoto = photoBytes != null;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: hasPhoto
                    ? Image.memory(
                        photoBytes!,
                        key: const ValueKey('merchPrintPhoto'),
                        fit: BoxFit.cover,
                      )
                    : ColoredBox(
                        color: palette.surfaceHighlight,
                        child: Icon(
                          Icons.add_a_photo_outlined,
                          color: palette.textMuted,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    key: const ValueKey('merchAddPhoto'),
                    onPressed: onPick,
                    icon: Icon(
                      hasPhoto ? Icons.photo_camera_back_outlined : Icons.add_a_photo_outlined,
                      size: 18,
                    ),
                    label: Text(
                      hasPhoto
                          ? l10n.line('merchChangePhoto')
                          : l10n.line('merchAddPhoto'),
                    ),
                  ),
                  if (hasPhoto)
                    OutlinedButton.icon(
                      key: const ValueKey('merchRemovePhoto'),
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(l10n.line('merchRemovePhoto')),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewColumn extends StatelessWidget {
  const _PreviewColumn({
    required this.product,
    required this.line,
    required this.photoBytes,
    required this.size,
    required this.color,
    required this.quantity,
    required this.saving,
    required this.saved,
    required this.error,
    required this.onSave,
  });

  final MerchandiseProduct product;
  final String line;
  final Uint8List? photoBytes;
  final String size;
  final String color;
  final int quantity;
  final bool saving;
  final bool saved;
  final String? error;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MerchandiseLivePreview(
          product: product,
          line: line,
          photoBytes: photoBytes,
          hint: l10n.line('merchCampaignHint'),
          size: size,
          color: color,
          quantity: quantity,
          previewLabel: l10n.line('merchLivePreview'),
          standardLabel: l10n.line('merchStandard'),
          qtyLabel: l10n.line('merchQty'),
        ),
        const SizedBox(height: 14),
        if (saved)
          Text(l10n.line('merchSaved'), style: AppTextStyles.body(context))
        else
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A6F82),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF1A6F82).withValues(alpha: 0.6),
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onSave,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(l10n.line('merchPlaceRequest')),
          ),
        if (error != null) ...[
          const SizedBox(height: 10),
          Text(error!, style: AppTextStyles.body(context).copyWith(color: context.palette.danger)),
        ],
      ],
    );
  }
}
