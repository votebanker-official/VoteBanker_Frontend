import 'package:flutter/material.dart';

import '../../app/routing/app_routes.dart';
import '../../core/widgets/app_text_field.dart';
import 'public_info_page.dart';
import 'support_contact.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final sections = <PublicSection>[
      for (final category in _categories)
        if (query.isEmpty || category.matches(query))
          PublicSection(category.title, [
            for (final item in category.items)
              if (query.isEmpty || item.matches(query))
                '${item.question}\n${item.answer}',
          ]),
    ];
    return PublicDocument(
      title: 'Help Center',
      description:
          'Answers on VoteBanker accounts, voter records, campaign tools, election rules, deletion, and merchandise.',
      lead: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            key: const Key('help-search'),
            controller: _search,
            label: 'Search help',
            hint: 'Search accounts, voter records, shipping, or election rules',
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: 8),
          const _HelpLinks(),
        ],
      ),
      sections:
          sections.isEmpty
              ? [
                PublicSection('No matching answers', [
                  'Nothing in the help topics matches that search. Try a shorter word, or write to $supportEmail.',
                ], child: const _HelpLinks()),
              ]
              : sections,
    );
  }
}

class _HelpLinks extends StatelessWidget {
  const _HelpLinks();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: const [
        PublicRouteLink(
          label: 'Contact Support',
          route: AppRoutes.contactSupport,
        ),
        PublicRouteLink(
          label: 'Election Disclaimer',
          route: AppRoutes.electionDisclaimer,
        ),
        PublicRouteLink(label: 'Data Deletion', route: AppRoutes.dataDeletion),
        PublicRouteLink(label: 'Terms & Conditions', route: AppRoutes.terms),
      ],
    );
  }
}

class _Faq {
  const _Faq(this.question, this.answer);

  final String question;
  final String answer;

  bool matches(String query) =>
      question.toLowerCase().contains(query) ||
      answer.toLowerCase().contains(query);
}

class _Category {
  const _Category(this.title, this.items);

  final String title;
  final List<_Faq> items;

  bool matches(String query) =>
      title.toLowerCase().contains(query) ||
      items.any((item) => item.matches(query));
}

const _categories = <_Category>[
  _Category('Getting started and sign-in', [
    _Faq(
      'Who can open an account?',
      'VoteBanker is for people aged 18 or older. A workspace is meant for a political leader, a public representative, or a campaign team they authorise.',
    ),
    _Faq(
      'How does the one-time passcode work?',
      'Enter the mobile number on the sign-in screen. The passcode is sent on WhatsApp. Google sign-in is also available. There is no separate pricing or plans page to pass before you sign in.',
    ),
    _Faq(
      'The passcode did not arrive.',
      'Confirm the WhatsApp number, wait a moment, and request the code again from the OTP screen. If it still fails, use Contact Support and choose Account & Access.',
    ),
  ]),
  _Category('Voter records and team roles', [
    _Faq(
      'What is Voter Relationship Management?',
      'VRM is the workspace where an authorised team stores constituent names, phone numbers, addresses, and booth, ward, or constituency tags. The campaign decides what it is lawful to collect. VoteBanker stores the records so the team can organise outreach.',
    ),
    _Faq(
      'Who can see a workspace’s records?',
      'Another leader’s workspace cannot see them. Inside your workspace, role-based access limits what a team member can open. Assign roles from Team and Volunteers.',
    ),
    _Faq(
      'Can volunteers be given their own tasks?',
      'Yes. Volunteer and team screens hold names, contact details, roles, and task activity entered by the workspace.',
    ),
  ]),
  _Category('Website builder and campaign tools', [
    _Faq(
      'What does the website builder publish?',
      'It hosts a leader microsite with the biography, photos, and announcements you choose to make public. Unpublished drafts stay in the workspace.',
    ),
    _Faq(
      'Where are speeches and letters drafted?',
      'The speech and letter tools take a topic and profile context and return a draft. They do not publish it for you.',
    ),
  ]),
  _Category('AI content and election rules', [
    _Faq(
      'Do I have to check an AI draft?',
      'Yes. Read it before you publish, print, or send it. A draft can be wrong, and it is not advice that the text complies with election law.',
    ),
    _Faq(
      'What election rules should I keep in mind?',
      'Follow the Model Code of Conduct, including the silence period, and do not impersonate the Election Commission or another candidate. Label AI-generated or materially edited media when a direction requires it. Read the Election Disclaimer for the full statement.',
    ),
    _Faq(
      'Is VoteBanker an Election Commission portal?',
      'No. It is a private product of Voter Relationship Management Private Limited. It does not register voters or issue an e-EPIC.',
    ),
  ]),
  _Category('Data deletion and privacy', [
    _Faq(
      'How do I delete my account or voter records?',
      'Open Data Deletion, choose what to remove, and send the request from the email or phone on the account. We verify the request and then delete the workspace data, apart from a short backup or a log the law requires.',
    ),
    _Faq(
      'How do I disconnect Facebook, Instagram, or Google?',
      'Remove the connection in the product’s social or sign-in settings, and you can also revoke VoteBanker from that service’s own settings. Then ask for the VoteBanker account to be deleted if you want the workspace removed as well.',
    ),
    _Faq(
      'Who is responsible for voter data?',
      'The leader or campaign that uploads the records is the Data Fiduciary. VoteBanker is the Data Processor. The Privacy Policy explains both roles.',
    ),
  ]),
  _Category('Merchandise, shipping, and refunds', [
    _Faq(
      'Is there a subscription plan?',
      'No. The site has no pricing or plans page and no subscription catalogue. Paid activity, where it exists, is a merchandise order or a specific service shown before you pay.',
    ),
    _Faq(
      'How long does shipping take, and what if the item is wrong?',
      'Dispatch follows confirmation and depends on the item and whether the Indian address is serviceable. Report a damaged, defective, or incorrect item within 7 days of delivery, with the order reference and a photograph. The Refund & Shipping Policy has the replacement and refund steps.',
    ),
    _Faq(
      'Are card or UPI details stored here?',
      'No. The payment gateway handles those credentials. VoteBanker keeps the order and a transaction reference.',
    ),
  ]),
];
