import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/routing/app_routes.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import 'public_info_page.dart';
import 'support_contact.dart';

class DataDeletionScreen extends StatelessWidget {
  const DataDeletionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PublicDocument(
      title: 'Data Deletion',
      description:
          'How to ask VoteBanker to delete an account, voter records, or a connected social account.',
      sections: [
        const PublicSection('1. What you can ask us to delete', [
          'You can ask for deletion of your VoteBanker account, the voter and campaign records stored in your workspace, team records held for that workspace, and a connection to Facebook, Instagram, Google, or WhatsApp.',
          'If you are a constituent whose details were entered by a campaign, that campaign is the Data Fiduciary for those records. Write to the campaign as well as to VoteBanker so both the fiduciary and the processor can act.',
        ]),
        const PublicSection('2. Steps to request deletion', [
          '1. Sign in and disconnect Facebook, Instagram, or Google from the social or sign-in settings if you only want that connection removed. You can also remove VoteBanker from the settings of those services. That revokes their token.',
          '2. For the account itself, or for voter and campaign records, complete the form on this page. Use the mobile number or email that is on the account so we can match the workspace.',
          '3. If the form cannot be sent from this browser, email the same details to the support address below. Keep a copy of what you sent.',
          '4. We will verify that the request comes from the account holder, or from a person the workspace has authorised, before anything is deleted.',
        ]),
        PublicSection('3. Deletion request', [
          'Fields marked as required must be filled in. The confirmation checkbox is required. Submitting prepares the request for $supportEmail. VoteBanker does not store this form on its servers.',
        ], child: const DataDeletionForm()),
        const PublicSection('4. Verification and timing', [
          'We match the name and the email or phone to the account, and we may send a one-time code or reply to that address before deleting. A request we cannot match is not actioned until you confirm it.',
          supportReplyWindow,
          'After verification, we delete the account profile, the workspace’s voter and team records, and stored social tokens for that workspace. A short technical backup may still hold a copy until the backup cycle ends.',
        ]),
        const PublicSection('5. What may be kept', [
          'We may keep a limited security or audit log, and a record of the deletion request itself, where that is required to show that the request was received or to investigate abuse. Payment gateways keep their own transaction records under their rules. Those logs are not a copy of your voter list.',
          'Disconnecting a social account stops new publishing. It does not delete posts that were already published on Facebook, Instagram, or WhatsApp. Remove those in the social product if you want them taken down.',
        ]),
      ],
    );
  }
}

class DataDeletionForm extends StatefulWidget {
  const DataDeletionForm({super.key});

  @override
  State<DataDeletionForm> createState() => _DataDeletionFormState();
}

class _DataDeletionFormState extends State<DataDeletionForm> {
  static const _types = [
    'Delete my account',
    'Delete voter or campaign records',
    'Disconnect a social account',
    'Delete the account and all workspace records',
  ];

  String? _type;
  final _name = TextEditingController();
  final _contact = TextEditingController();
  final _workspace = TextEditingController();
  final _details = TextEditingController();
  bool _confirmed = false;
  String? _error;
  bool _ready = false;

  @override
  void dispose() {
    _name.dispose();
    _contact.dispose();
    _workspace.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final contact = _contact.text.trim();
    final workspace = _workspace.text.trim();
    final details = _details.text.trim();
    if (_type == null ||
        name.isEmpty ||
        contact.isEmpty ||
        workspace.isEmpty ||
        details.isEmpty ||
        !_confirmed) {
      setState(() {
        _error =
            'Choose a request type, fill in every field, and confirm you are authorised.';
        _ready = false;
      });
      return;
    }
    final body = [
      'Request type: $_type',
      'Name: $name',
      'Email or phone: $contact',
      'Account or workspace: $workspace',
      'Details: $details',
      'I confirm I am the account holder or authorised to request this deletion.',
    ].join('\n');
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {
        'subject': 'VoteBanker data deletion request',
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
        Text('Request type', style: AppTextStyles.label(context)),
        Column(
          children: [
            for (final type in _types)
              RadioListTile<String>(
                key: Key('deletion-type-$type'),
                value: type,
                groupValue: _type,
                onChanged: (value) => setState(() => _type = value),
                contentPadding: EdgeInsets.zero,
                title: Text(type, style: AppTextStyles.body(context)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        AppTextField(
          key: const Key('deletion-name'),
          controller: _name,
          label: 'Name',
          hint: 'Name on the account',
        ),
        const SizedBox(height: 12),
        AppTextField(
          key: const Key('deletion-contact'),
          controller: _contact,
          label: 'Email or phone',
          hint: 'The email or mobile number used to sign in',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        AppTextField(
          key: const Key('deletion-workspace'),
          controller: _workspace,
          label: 'Account or workspace',
          hint: 'Leader or workspace name',
        ),
        const SizedBox(height: 12),
        AppTextField(
          key: const Key('deletion-details'),
          controller: _details,
          label: 'Reason and details',
          hint: 'What should be deleted',
          maxLines: 4,
        ),
        CheckboxListTile(
          key: const Key('deletion-confirm'),
          contentPadding: EdgeInsets.zero,
          value: _confirmed,
          onChanged: (value) => setState(() => _confirmed = value ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            'I confirm I am the account holder, or I am authorised by the workspace to request this deletion.',
            style: AppTextStyles.body(context).copyWith(fontSize: 13.5),
          ),
        ),
        if (_error != null)
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 8),
        PrimaryButton(
          key: const Key('deletion-submit'),
          label: 'Prepare deletion request',
          onPressed: _submit,
        ),
        const SizedBox(height: 8),
        Text(
          'Or email $supportEmail with the same details. Support hours: $supportHours',
          style: AppTextStyles.muted(context),
        ),
        if (_ready) ...[
          const SizedBox(height: 12),
          Text(
            'Your deletion request is ready. If your email app did not open, send the same details to $supportEmail. Nothing is deleted until we verify the request.',
            key: const Key('deletion-ready'),
            style: AppTextStyles.body(context),
          ),
          PublicRouteLink(
            label: 'Read the Privacy Policy',
            route: AppRoutes.privacyPolicy,
          ),
        ],
      ],
    );
  }
}
