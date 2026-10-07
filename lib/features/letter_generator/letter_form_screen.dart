import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import 'letter_model.dart';

class LetterFormScreen extends StatelessWidget {
  const LetterFormScreen({
    required this.senderName,
    required this.senderAddress,
    required this.mobile,
    required this.email,
    required this.politicianName,
    required this.designation,
    required this.designationDetail,
    required this.constituency,
    required this.subject,
    required this.purpose,
    required this.message,
    required this.date,
    required this.errors,
    required this.busy,
    required this.onChanged,
    required this.onDesignation,
    required this.onDate,
    required this.onGenerate,
    this.error,
    super.key,
  });

  final TextEditingController senderName;
  final TextEditingController senderAddress;
  final TextEditingController mobile;
  final TextEditingController email;
  final TextEditingController politicianName;
  final String designation;
  final TextEditingController designationDetail;
  final TextEditingController constituency;
  final TextEditingController subject;
  final TextEditingController purpose;
  final TextEditingController message;
  final DateTime date;
  final Map<String, String> errors;
  final bool busy;
  final VoidCallback onChanged;
  final ValueChanged<String> onDesignation;
  final ValueChanged<DateTime> onDate;
  final VoidCallback onGenerate;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String? fieldError(String key) {
      final code = errors[key];
      return code == null ? null : l10n.line(code);
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        Text(l10n.line('letterTitle'), style: AppTextStyles.headline(context)),
        const SizedBox(height: 8),
        Text(l10n.line('letterSubtitle'), style: AppTextStyles.muted(context)),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.line('letterFrom'), style: AppTextStyles.label(context)),
              const SizedBox(height: 12),
              _FieldGrid(
                children: [
                  AppTextField(
                    key: const Key('letter-sender'),
                    controller: senderName,
                    label: l10n.line('letterSenderName'),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    errorText: fieldError('senderName'),
                    onChanged: (_) => onChanged(),
                  ),
                  AppTextField(
                    controller: mobile,
                    label: l10n.line('letterMobile'),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    errorText: fieldError('mobile'),
                    onChanged: (_) => onChanged(),
                  ),
                  AppTextField(
                    controller: senderAddress,
                    label: l10n.line('letterSenderAddress'),
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => onChanged(),
                  ),
                  AppTextField(
                    controller: email,
                    label: l10n.line('letterEmail'),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: fieldError('email'),
                    onChanged: (_) => onChanged(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.line('letterTo'), style: AppTextStyles.label(context)),
              const SizedBox(height: 12),
              _FieldGrid(
                children: [
                  AppTextField(
                    key: const Key('letter-politician'),
                    controller: politicianName,
                    label: l10n.line('letterPoliticianName'),
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    errorText: fieldError('politicianName'),
                    onChanged: (_) => onChanged(),
                  ),
                  _DesignationField(
                    label: l10n.line('letterDesignation'),
                    value: designation,
                    errorText: fieldError('designation'),
                    onChanged: onDesignation,
                  ),
                  if (designation == 'Other')
                    AppTextField(
                      key: const Key('letter-designation-detail'),
                      controller: designationDetail,
                      label: l10n.line('letterDesignationDetail'),
                      textCapitalization: TextCapitalization.words,
                      errorText: fieldError('designationDetail'),
                      onChanged: (_) => onChanged(),
                    ),
                  AppTextField(
                    key: const Key('letter-constituency'),
                    controller: constituency,
                    label: l10n.line('letterConstituency'),
                    textCapitalization: TextCapitalization.words,
                    errorText: fieldError('constituency'),
                    onChanged: (_) => onChanged(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.line('letterAbout'), style: AppTextStyles.label(context)),
              const SizedBox(height: 12),
              AppTextField(
                key: const Key('letter-subject'),
                controller: subject,
                label: l10n.line('letterSubject'),
                textCapitalization: TextCapitalization.sentences,
                errorText: fieldError('subject'),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 12),
              AppTextField(
                key: const Key('letter-purpose'),
                controller: purpose,
                label: l10n.line('letterPurpose'),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                errorText: fieldError('purpose'),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 12),
              AppTextField(
                key: const Key('letter-message'),
                controller: message,
                label: l10n.line('letterMessage'),
                hint: l10n.line('letterMessageHint'),
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                errorText: fieldError('message'),
                onChanged: (_) => onChanged(),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.line('letterDate'),
                style: AppTextStyles.label(context).copyWith(
                  fontSize: 13,
                  color: context.palette.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('letter-date'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    onDate(picked);
                  }
                },
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(DateFormat('d MMMM y').format(date)),
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: AppTextStyles.body(context).copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 16),
        PrimaryButton(
          label: l10n.line('letterGenerate'),
          icon: Icons.mail_outline,
          onPressed: busy ? null : onGenerate,
        ),
      ],
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < AppBreakpoints.tablet;
        if (stacked) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                children[i],
              ],
            ],
          );
        }
        final width = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

class _DesignationField extends StatelessWidget {
  const _DesignationField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final String value;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DropdownButtonFormField<String>(
      key: const Key('letter-designation'),
      value: value.isEmpty ? null : value,
      isExpanded: true,
      hint: Text(l10n.line('letterDesignationHint')),
      decoration: InputDecoration(labelText: label, errorText: errorText),
      items: [
        for (final entry in letterDesignations.entries)
          DropdownMenuItem(
            value: entry.key,
            child: Text(l10n.line(entry.value), overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}
