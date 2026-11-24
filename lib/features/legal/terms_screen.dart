import 'package:flutter/material.dart';

import 'public_info_page.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PublicDocument(
      title: 'Terms & Conditions',
      description:
          'Terms for using VoteBanker, a private campaign and voter relationship workspace operated in India.',
      sections: [
        PublicSection('1. Who may use VoteBanker', [
          'These terms govern use of the VoteBanker website, web app, and mobile experience operated by Voter Relationship Management Private Limited. By creating an account or continuing past the sign-in screen, you agree to them.',
          'VoteBanker is only for individuals aged 18 years or older. A campaign workspace is for a political leader, a public representative, or people they authorise. You must not create an account for a minor or present yourself as someone you are not.',
        ]),
        PublicSection('2. Accounts and sign-in', [
          'You register with a mobile number and a one-time passcode, which is delivered on WhatsApp, or with Google sign-in where that option is offered. Keep the passcode, password, and any connected social token to yourself. You are responsible for activity under your account until you tell us the account is compromised.',
          'Give a name and contact detail that can reach you. We may refuse or close an account that uses a number or identity you are not entitled to use.',
        ]),
        PublicSection('3. Acceptable use and election rules', [
          'Use the workspace only for lawful campaign organisation. You must not use VoteBanker for unlawful campaigning, harassment, impersonation, defamation, or misleading material. You must not use it to violate the Model Code of Conduct, a direction of the Election Commission of India or a State Election Commission, or any other applicable law.',
          'That includes the silence period, restrictions on government publicity during an election, and any rule that requires paid or edited content to name who authorised it. VoteBanker may suspend a workspace that is used for this kind of abuse.',
          'VoteBanker is not an official election portal. Nothing in the product is an instruction from the Election Commission.',
        ]),
        PublicSection('4. Voter and constituent data', [
          'If you upload or type constituent records, you warrant that you have a lawful basis to do so under the Digital Personal Data Protection Act, 2023 and any other law that applies. That includes any consent or other permitted ground the Act requires, and a proper notice to the person concerned.',
          'For those records you are the Data Fiduciary. VoteBanker processes them as a Data Processor, on the workspace’s instructions, and only to provide the product. You will not sell constituent contact details, use them for a purpose the person was not told about, or share a workspace login with someone who is not authorised.',
          'Leader workspaces are isolated from each other. You must not attempt to reach another leader’s voter or team records.',
        ]),
        PublicSection('5. Intellectual property', [
          'The VoteBanker name, logo, software, and layout belong to Voter Relationship Management Private Limited or its licensors. These terms give you a limited right to use the product for your own campaign while the account is active. They do not transfer ownership of the software.',
          'You keep ownership of the text, photos, voter records, and other material you submit. You grant us the right to host, display, and process that material only so we can run the features you use, including a public microsite you choose to publish.',
        ]),
        PublicSection('6. AI-assisted content', [
          'Speech, letter, and caption tools draft from the prompt and profile context you submit. A draft can be wrong, out of date, or unsuitable for an election period. You must read and verify it before you publish, print, or send it. You are responsible for the final text, including any disclosure that the material was assisted or edited by software.',
        ]),
        PublicSection('7. Availability, suspension, and ending the service', [
          'We aim to keep the workspace available, but we do not guarantee uninterrupted access. Maintenance, a supplier outage, or a legal requirement can interrupt a feature.',
          'We may suspend or close an account that breaks these terms, breaks election law, or puts other people at risk. You may stop using the service and ask for the account to be deleted from the Data Deletion page. Closing an account deletes the workspace data described in the Privacy Policy, except for a short backup cycle or a record the law tells us to keep.',
        ]),
        PublicSection('8. Liability and Indian law', [
          'The product is provided as a campaign tool. To the extent the law allows, Voter Relationship Management Private Limited is not liable for loss of votes, loss of a campaign opportunity, or a penalty that follows from a message or list you chose to publish. Nothing in these terms limits liability that Indian law does not allow a contract to limit.',
          'These terms are governed by the laws of India. The courts at the registered office of Voter Relationship Management Private Limited have jurisdiction, without affecting any right you have to approach a consumer or data-protection forum that the law makes available.',
        ]),
      ],
    );
  }
}
