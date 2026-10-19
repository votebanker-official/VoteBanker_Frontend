import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/website_builder_draft.dart';

typedef DraftChanged = void Function();

class BuilderTextField extends StatelessWidget {
  const BuilderTextField({
    required this.controller,
    required this.label,
    this.hint,
    this.requiredField = false,
    this.maxLines = 1,
    this.keyboardType,
    this.errorText,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool requiredField;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppTextField(
        controller: controller,
        label: requiredField ? '$label *' : '$label (optional)',
        hint: hint,
        maxLines: maxLines,
        keyboardType: keyboardType,
        errorText: errorText,
        onChanged: onChanged,
      ),
    );
  }
}

class BuilderPhotoPicker extends StatelessWidget {
  const BuilderPhotoPicker({
    required this.label,
    required this.media,
    required this.onChanged,
    this.requiredField = false,
    this.round = false,
    super.key,
  });

  final String label;
  final MediaRef media;
  final ValueChanged<MediaRef> onChanged;
  final bool requiredField;
  final bool round;

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    onChanged(
      MediaRef(
        base64: base64Encode(bytes),
        caption: media.caption,
        url: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bytes = media.bytes;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            requiredField ? '$label *' : '$label (optional)',
            style: AppTextStyles.label(context).copyWith(
              fontSize: 13,
              color: palette.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(round ? 40 : 12),
                child: SizedBox(
                  width: round ? 80 : 120,
                  height: round ? 80 : 72,
                  child: bytes != null
                      ? Image.memory(bytes, fit: BoxFit.cover)
                      : media.url.isNotEmpty
                          ? Image.network(media.url, fit: BoxFit.cover)
                          : ColoredBox(
                              color: palette.surfaceHighlight,
                              child: Icon(
                                Icons.person,
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
                      onPressed: _pick,
                      icon: const Icon(Icons.upload_outlined),
                      label: Text(bytes == null && media.url.isEmpty
                          ? 'Upload'
                          : 'Replace'),
                    ),
                    if (media.hasImage)
                      OutlinedButton.icon(
                        onPressed: () => onChanged(MediaRef()),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BuilderSectionHeader extends StatelessWidget {
  const BuilderSectionHeader(this.title, {this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headline(context)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTextStyles.muted(context)),
          ],
        ],
      ),
    );
  }
}

class EmptyEntriesHint extends StatelessWidget {
  const EmptyEntriesHint(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(message, style: AppTextStyles.muted(context)),
    );
  }
}
