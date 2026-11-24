import 'package:flutter/material.dart';

import 'public_info_page.dart';

class ElectionDisclaimerScreen extends StatelessWidget {
  const ElectionDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PublicDocument(
      title: 'Election Disclaimer',
      description:
          'VoteBanker is a private campaign tool and is not an official portal of the Election Commission of India.',
      sections: [
        PublicSection('1. A private campaign tool', [
          'Voter Relationship Management Private Limited operates VoteBanker as an independent private software tool for political leaders, public representatives, and campaign teams. The platform helps a workspace organise outreach, team work, a campaign website, and draft material.',
          'VoteBanker is not affiliated with, endorsed by, or an official portal of the Election Commission of India (ECI), any State Election Commission, or any government body. An account, a microsite, a poster, or a voter list inside VoteBanker is not an official electoral record.',
        ]),
        PublicSection('2. Official election services are separate', [
          'Official electoral services are provided by the Election Commission and the authorities it designates. Those services include enrolment as an elector, corrections to the electoral roll, the official voter list, and the e-EPIC (electronic elector photo identity card).',
          'VoteBanker does not register voters, does not amend the electoral roll, and does not issue an EPIC or any government identity document. A phone number or address stored in a campaign workspace is a private campaign record. It does not prove that a person is on the roll, and it is not a substitute for checking the official roll.',
        ]),
        PublicSection('3. Model Code of Conduct and your duties', [
          'You are responsible for using the platform in line with the Representation of the People Act, the Model Code of Conduct (MCC), and any direction the Election Commission or a competent authority issues for an election. The MCC applies during the period the Commission notifies, including the silence period before the close of poll, when campaigning to electors is restricted.',
          'Do not use VoteBanker to publish or send misinformation, impersonate the Commission, a candidate, a party, or a public office, or to circulate hate speech. Do not campaign in a way the MCC or any other law prohibits, including appeals on the ground of religion, race, caste, community, or language where the law forbids them, and paid news or surrogate publicity that hides who is speaking.',
          'Where a post, poster, or message is generated or materially edited by software, label it as such when the law or an Election Commission direction requires that disclosure. You must not present an AI draft as an official Commission notice.',
        ]),
        PublicSection('4. Drafts are not compliance advice', [
          'Speeches, captions, letters, websites, analytics, and lists produced in VoteBanker are campaign working material. They are not legal advice, and they are not a confirmation that a message, a list, or a method of contact complies with election law or with a direction of the Election Commission.',
          'Review every draft against the current MCC, the silence-period calendar for your constituency, and your own legal advice before you publish or message anyone. If a rule and a draft disagree, follow the rule.',
        ]),
      ],
    );
  }
}
