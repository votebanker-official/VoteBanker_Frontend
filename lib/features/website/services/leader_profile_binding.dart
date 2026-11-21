import 'dart:convert';

import '../../onboarding/models/onboarding_draft.dart';
import '../models/website_builder_draft.dart';
import '../widgets/leader_portfolio_site.dart';

/// Copies saved Leader Profile fields onto the portfolio draft.
///
/// The profile form stays the only place the leader enters a party, photo,
/// name, designation, and constituency. Later edits replace the previous values.
void applyLeaderProfile(WebsiteBuilderDraft website, OnboardingDraft profile) {
  void copy(String value, void Function(String) set) {
    final trimmed = value.trim();
    if (trimmed.isNotEmpty) set(trimmed);
  }

  copy(profile.leaderName, (value) => website.fullName = value);
  copy(profile.designation, (value) => website.designation = value);
  copy(profile.assemblyConstituency, (value) => website.constituency = value);
  copy(profile.district, (value) => website.district = value);
  copy(profile.state, (value) => website.state = value);
  copy(profile.contactNumber, (value) => website.phone = value);
  website.applyPartyFromProfile(profile.party);

  if (profile.photoRemoved) {
    website.profilePhoto = MediaRef();
  } else if (profile.photoBytes != null) {
    website.profilePhoto = MediaRef(base64: base64Encode(profile.photoBytes!));
  } else if (profile.profilePhotoUrl.trim().isNotEmpty) {
    website.profilePhoto = MediaRef(url: profile.profilePhotoUrl.trim());
  }

  final extra = profile.additionalProfile;
  void take(String key, void Function(String) set) {
    final value = extra[key];
    if (value is String) copy(value, set);
  }

  take('about', (value) {
    website.biography = value;
    website.aboutLeader = value;
  });
  take('introduction', (value) => website.shortIntro = value);
  take('vision', (value) => website.goalsVision = value);
  take('mission', (value) => website.localPriorities = value);
  take('journey', (value) => website.politicalJourney = value);
  take('education', (value) => website.education = value);
  take('experience', (value) => website.publicServiceExperience = value);

  final palette = PartyPalette.forParty(website.party);
  if (palette.id != PartyPalette.fallback.id) {
    website.design.primaryColor = palette.primary.toARGB32();
    website.design.secondaryColor = palette.ink.toARGB32();
  }
}
