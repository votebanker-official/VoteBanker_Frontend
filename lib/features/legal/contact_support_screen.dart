import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routing/app_routes.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import 'public_info_page.dart';
import 'support_contact.dart';

class ContactSupportScreen extends StatelessWidget {
  const ContactSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicDocument(
      title: 'Contact Support',
      description:
          'Contact VoteBanker support for account, technical, merchandise, data deletion, and election-policy questions.',
      sections: [
        PublicSection('1. How to reach us', [
          'Email $supportEmail. Support hours are $supportHours $supportReplyWindow',
          'Use the form to prepare a message. VoteBanker does not store the form on its servers. If the email app does not open, copy the details into an email to the address above.',
          'For a personal-data complaint, you may also use the grievance contact named in the Privacy Policy. Deletion of an account or voter records is handled on the Data Deletion page.',
        ]),
        PublicSection('2. Support request', [
          'Choose the category that best matches the question. Phone is optional.',
        ], child: SupportRequestForm()),
      ],
    );
  }
}

class SupportRequestForm extends StatefulWidget {
  const SupportRequestForm({super.key});

  @override
  State<SupportRequestForm> createState() => _SupportRequestFormState();
}

class _SupportRequestFormState extends State<SupportRequestForm> {
  static const _categories = [
    'Technical Issue',
    'Account & Access',
    'Data Deletion',
    'Merchandise & Shipping',
    'Election & Policy Query',
  ];

  String? _category;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  String? _error;
  bool _ready = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final message = _message.text.trim();
    final emailLooksValid = email.contains('@') && email.contains('.');
    if (_category == null || name.isEmpty || !emailLooksValid || message.length < 10) {
      setState(() {
        _error = 'Add your name, a valid email, a category, and a message of at least a sentence.';
        _ready = false;
      });
      return;
    }
    final phone = _phone.text.trim();
    final body = [
      'Category: $_category',
      'Name: $name',
      'Email: $email',
      if (phone.isNotEmpty) 'Phone: $phone',
      'Message: $message',
    ].join('\n');
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': 'VoteBanker support: $_category',
        'body': body,
      },
    );
    if (!mounted) return;
    setState(() {
      _error = null;
      _ready = true;
    });
    try {
      await launchUrl(uri);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          key: const Key('support-name'),
          controller: _name,
          label: 'Name',
        ),
        const SizedBox(height: 12),
        AppTextField(
          key: const Key('support-email'),
          controller: _email,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        AppTextField(
          key: const Key('support-phone'),
          controller: _phone,
          label: 'Phone (optional)',
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: const Key('support-category'),
          initialValue: _category,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Category'),
          items: [
            for (final category in _categories)
              DropdownMenuItem(value: category, child: Text(category)),
          ],
          onChanged: (value) => setState(() => _category = value),
        ),
        const SizedBox(height: 12),
        AppTextField(
          key: const Key('support-message'),
          controller: _message,
          label: 'Message',
          maxLines: 5,
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ],
        const SizedBox(height: 12),
        PrimaryButton(
          key: const Key('support-submit'),
          label: 'Prepare support request',
          onPressed: _submit,
        ),
        if (_ready) ...[
          const SizedBox(height: 12),
          Text(
            'Your support request is ready. If your email app did not open, send it to $supportEmail. Hours: $supportHours',
            key: const Key('support-ready'),
            style: AppTextStyles.body(context),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          children: [
            PublicRouteLink(label: 'Data Deletion', route: AppRoutes.dataDeletion),
            PublicRouteLink(label: 'Election Disclaimer', route: AppRoutes.electionDisclaimer),
            PublicRouteLink(label: 'Help Center', route: AppRoutes.helpCenter),
          ],
        ),
      ],
    );
  }
}
