import 'package:flutter/material.dart';

import '../../app/routing/app_routes.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/constants/app_assets.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/language_selector.dart';
import '../../core/widgets/theme_toggle.dart';
import 'privacy_meta.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final _sectionKeys = List<GlobalKey>.generate(
    _sections.length,
    (_) => GlobalKey(),
  );
  bool? _tocOpen;

  @override
  void initState() {
    super.initState();
    applyPrivacyMeta();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final deletion = ModalRoute.of(context)?.settings.arguments == 'deletion';
      if (deletion) _revealUntilVisible(6, 0);
    });
  }

  @override
  void dispose() {
    restorePrivacyMeta();
    super.dispose();
  }

  void _showSection(int index) => _revealUntilVisible(index, 0);

  /// The footer shell first lets this page scroll inside itself, then expands
  /// the page so the outer document scrolls. A reveal on the first frame is
  /// undone by that expansion, so keep revealing until the section is on screen.
  void _revealUntilVisible(int index, int attempt) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _sectionKeys[index].currentContext;
      final object = target?.findRenderObject();
      if (target == null || object is! RenderBox || !object.hasSize) {
        if (attempt < 6) _revealUntilVisible(index, attempt + 1);
        return;
      }
      final dy = object.localToGlobal(Offset.zero).dy;
      final height = MediaQuery.sizeOf(context).height;
      if (dy < 0 || dy > height * 0.2) {
        var scrollable = Scrollable.maybeOf(target);
        while (scrollable != null) {
          final position = scrollable.position;
          if (position.hasContentDimensions && position.maxScrollExtent > 2) {
            position.ensureVisible(
              object,
              alignment: 0.06,
              duration: Duration.zero,
            );
          }
          scrollable = Scrollable.maybeOf(scrollable.context);
        }
      }
      if (attempt == 5 || (dy >= 0 && dy <= height * 0.2)) {}
      if ((dy < 0 || dy > height * 0.2) && attempt < 6) {
        _revealUntilVisible(index, attempt + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: ListView(
        children: [
          _Header(onBack: () => AppNav.back(context, AppRoutes.login)),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final pad = wide ? 36.0 : 16.0;
              final open = _tocOpen ?? wide;
              final toc = _Contents(
                open: open,
                onToggle: () => setState(() => _tocOpen = !open),
                onSelect: _showSection,
              );
              final article = Column(
                children: [
                  for (var i = 0; i < _sections.length; i++) ...[
                    _SectionCard(key: _sectionKeys[i], section: _sections[i]),
                    const SizedBox(height: 14),
                  ],
                ],
              );
              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1120),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(pad, 24, pad, 40),
                    child:
                        wide
                            ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 280, child: toc),
                                const SizedBox(width: 20),
                                Expanded(child: article),
                              ],
                            )
                            : Column(
                              children: [
                                toc,
                                const SizedBox(height: 16),
                                article,
                              ],
                            ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              IconButton(
                key: const Key('privacy-back'),
                tooltip: 'Back',
                onPressed: onBack,
                icon: Icon(Icons.arrow_back, color: palette.accent),
              ),
              Image.asset(AppAssets.logo, width: 32, height: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Privacy Policy',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.sectionTitle(
                    context,
                  ).copyWith(fontSize: 18),
                ),
              ),
              const ThemeToggle(),
              const SizedBox(width: 8),
              const Flexible(child: LanguageSelector()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Contents extends StatelessWidget {
  const _Contents({
    required this.open,
    required this.onToggle,
    required this.onSelect,
  });

  final bool open;
  final VoidCallback onToggle;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextButton.icon(
            key: const Key('privacy-toc-toggle'),
            onPressed: onToggle,
            icon: Icon(open ? Icons.expand_less : Icons.menu_book_outlined),
            label: const Align(
              alignment: Alignment.centerLeft,
              child: Text('On this page'),
            ),
          ),
          if (open)
            for (var i = 0; i < _sections.length; i++)
              TextButton(
                key: Key('privacy-toc-$i'),
                onPressed: () => onSelect(i),
                style: TextButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  foregroundColor: palette.accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  _sections[i].title,
                  style: AppTextStyles.body(context).copyWith(
                    color: palette.accent,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, super.key});

  final _PolicySection section;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title,
            style: AppTextStyles.sectionTitle(context).copyWith(fontSize: 20),
          ),
          const SizedBox(height: 10),
          for (final block in section.blocks) ...[
            if (block.heading != null) ...[
              Text(
                block.heading!,
                style: AppTextStyles.body(
                  context,
                ).copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
            ],
            for (final line in block.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(line, style: AppTextStyles.body(context)),
              ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _PolicySection {
  const _PolicySection(this.title, this.blocks);

  final String title;
  final List<_Block> blocks;
}

class _Block {
  const _Block(this.lines, {this.heading});

  final String? heading;
  final List<String> lines;
}

const _sections = <_PolicySection>[
  _PolicySection('1. Introduction', [
    _Block([
      'VoteBanker is a private software platform for political leaders, public representatives, campaign managers, and the teams who organise voter outreach with them. It provides a workspace for voter relationship management, campaign websites, team coordination, content tools, and related campaign operations.',
      'VoteBanker is not affiliated with, endorsed by, or connected to the Election Commission of India (ECI), any State Election Commission, or any other government body. Using VoteBanker does not create an official electoral record and does not replace any filing, disclosure, or permission required by election law.',
      'This policy explains what information the platform processes, who is responsible for it, and the choices available to account holders. It applies to the VoteBanker website, web app, and mobile experience.',
    ]),
  ]),
  _PolicySection('2. Our role under the DPDP Act', [
    _Block([
      'India\'s Digital Personal Data Protection Act, 2023 distinguishes the person who decides why and how personal data is processed from the person who processes it on their instructions.',
      'VoteBanker acts as a Data Processor. We provide the software infrastructure, hosting, and tools. The political leader or campaign that creates a workspace, and the people they authorise, act as the Data Fiduciary for voter and supporter records they upload or enter. The Data Fiduciary is responsible for collecting that data lawfully, giving any required notice, and obtaining consent where the Act requires it.',
      'For account data that a person gives us directly in order to sign in and operate their own workspace, VoteBanker decides the limited purposes described in this policy and handles that account data accordingly.',
    ]),
  ]),
  _PolicySection('3. Information we collect', [
    _Block(heading: 'Account and sign-in', [
      'Name, mobile number used for one-time passcode verification (delivered through WhatsApp, and through SMS where a messaging gateway is used), email address, including an address received through Google sign-in, profile photo, and campaign role or designation.',
    ]),
    _Block(heading: 'Voter Relationship Management (VRM)', [
      'Constituent names, phone numbers, addresses, and booth, ward, or constituency tags that a leader or an authorised team member uploads or types into the workspace. VoteBanker stores these records so the campaign can organise outreach. The campaign, as Data Fiduciary, decides what to collect and from whom.',
    ]),
    _Block(heading: 'Team and volunteer coordination', [
      'Volunteer and team-member names, contact details, assigned roles, and task or activity records entered by the workspace.',
    ]),
    _Block(heading: 'Website Builder', [
      'Public profile details, biography, photographs, and announcements a leader chooses to place on a campaign microsite. Content published on a microsite is visible to people who open that site.',
    ]),
    _Block(heading: 'AI features (speech and content tools)', [
      'Text prompts, topic inputs, and leader-profile context that you submit so the product can draft speeches, letters, social captions, or other campaign material. Those inputs are processed only to produce the output you asked for. They are not used to build a separate advertising profile.',
    ]),
    _Block(heading: 'Social connections (Meta and WhatsApp)', [
      'If you connect Facebook, Instagram, or a WhatsApp Business account, we receive the OAuth tokens and the permissions you approve so the workspace can publish or read the account data that connection requires. You can disconnect those accounts from the social settings in the product.',
    ]),
    _Block(heading: 'Merchandise', [
      'Shipping address, order history, and payment transaction references for campaign materials. Raw card numbers and UPI credentials are handled by the payment gateway that processes the payment. VoteBanker does not store those credentials on its servers.',
    ]),
  ]),
  _PolicySection('4. Mobile permissions and cookies', [
    _Block([
      'On a phone or tablet, the app may ask for photo or media access so you can upload a profile picture and save generated posters, speeches, or other files to your device. Access is used for that action. The app may also record crash and diagnostic logs so we can fix failures.',
      'The website uses essential session cookies and security tokens to keep you signed in and to protect the workspace against unauthorised access. These are not advertising cookies. If you block them, sign-in and saved drafts may stop working.',
    ]),
  ]),
  _PolicySection('5. Third-party processors', [
    _Block([
      'VoteBanker relies on specialist providers to run the service. They process data only so we can deliver the feature you use:',
      '• Cloud database and authentication infrastructure, including Supabase.',
      '• OTP and SMS or WhatsApp delivery gateways.',
      '• Google, for Google sign-in.',
      '• AI model providers that generate the speech, letter, or caption you request.',
      '• Meta Graph and WhatsApp APIs, when you connect a Facebook, Instagram, or WhatsApp Business account.',
      '• Hosting providers that serve the website and campaign microsites.',
      '• Payment gateways that take payment for merchandise. They receive payment details directly. VoteBanker stores the order and a transaction reference, not the raw card or UPI credential.',
    ]),
  ]),
  _PolicySection('6. Isolation, security, and retention', [
    _Block([
      'Each leader workspace is isolated. Voter and team records entered for one leader are not available to another leader\'s workspace. Access inside a workspace follows role-based permissions, so a team member sees the records their role allows. Administrative actions can be written to audit logs.',
      'Traffic between your browser or app and VoteBanker is encrypted with TLS (HTTPS). Stored records are encrypted at rest by the infrastructure that hosts them.',
      'Workspace data is kept while the account is active. When an account is closed, the associated profile, voter records, team records, and connected social tokens for that workspace are deleted, except where a short technical backup cycle or a legal duty requires us to keep a copy for a limited time.',
    ]),
  ]),
  _PolicySection('7. Your rights and how to delete data', [
    _Block([
      'Under the DPDP Act, a person may ask to access personal data, correct inaccurate data, withdraw consent, and request erasure, subject to the Act and to the role of the Data Fiduciary. For voter records a campaign entered, send the request to the campaign that collected them as well as to VoteBanker, so both the fiduciary and the processor can act.',
      'To disconnect Facebook, Instagram, or Google from a workspace, open the social or sign-in settings for that connection and remove it. Disconnecting stops further publishing with that token.',
      'To permanently delete an account and its VRM records, open Settings and follow Account & data deletion, or email the privacy contact below from the address or mobile number on the account. Include the workspace name and the mobile number or email used to sign in. We will confirm and delete the account data, including voter records stored for that workspace and stored social tokens.',
      'You may also remove the VoteBanker app from Facebook, Instagram, or Google account settings on those services. That revokes their token. Email us as well if you want the VoteBanker account itself deleted.',
    ]),
  ]),
  _PolicySection('8. Children\'s privacy', [
    _Block([
      'VoteBanker is only for people aged 18 years and older. We do not knowingly collect personal data from anyone under 18. If you believe a minor has created an account or been entered as a user, email the privacy contact and we will delete that account data.',
    ]),
  ]),
  _PolicySection('9. Grievance redressal', [
    _Block([
      'Complaints about personal data can be sent to the grievance contact below. We will acknowledge the complaint and aim to resolve it within 15 to 30 days.',
      'Grievance Officer: [Grievance Officer Name]',
      'Email: [grievance@votebanker.in]',
      'Postal address: [Company Legal Name & Address]',
      'These bracketed details are placeholders until the operating entity publishes its appointed officer and registered address. Messages sent to the address above will be read once that mailbox is live.',
    ]),
  ]),
];
