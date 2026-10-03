import 'package:flutter/material.dart';

import '../../../app/localization/app_languages.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_text_field.dart';

class WebsiteLanguageField extends StatelessWidget {
  const WebsiteLanguageField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceSecondary,
          items: [
            for (final language in AppLanguages.all)
              DropdownMenuItem<String>(
                value: language.code,
                child: Text(language.nativeName),
              ),
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

class WebsiteAnswerField extends StatelessWidget {
  const WebsiteAnswerField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
    this.optional = '',
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;
  final String optional;

  @override
  Widget build(BuildContext context) {
    final caption = optional.isEmpty ? label : '$label ($optional)';
    return AppTextField(
      controller: controller,
      label: caption,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
