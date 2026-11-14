import 'package:flutter_test/flutter_test.dart';
import 'package:votebanker/features/onboarding/models/onboarding_draft.dart';
import 'package:votebanker/features/website/models/website_draft.dart';

void main() {
  test('facebook or google name fills an empty questions field', () {
    final website = WebsiteDraft();
    website.applyLoginName(
      signedIn: true,
      loginName: 'asha patel',
      profileName: '',
    );
    expect(website.fullName, 'Asha Patel');
  });

  test('login name replaces a name copied from the leader profile', () {
    final profile = OnboardingDraft()..fullName = 'Saved Leader';
    final website = WebsiteDraft()..seedFromProfile(profile);
    website.applyLoginName(
      signedIn: true,
      loginName: 'Vote Banker',
      profileName: profile.fullName,
    );
    expect(website.fullName, 'Vote Banker');
  });

  test('a name typed on the website is kept after login', () {
    final website = WebsiteDraft()..fullName = 'Campaign Name';
    website.applyLoginName(
      signedIn: true,
      loginName: 'Vote Banker',
      profileName: 'Saved Leader',
    );
    expect(website.fullName, 'Campaign Name');
  });

  test('signed-out questions do not show a profile name', () {
    final profile = OnboardingDraft()..fullName = 'Vote Banker';
    final website = WebsiteDraft()..seedFromProfile(profile);
    website.applyLoginName(
      signedIn: false,
      loginName: 'Vote Banker',
      profileName: profile.fullName,
    );
    expect(website.fullName, isEmpty);
  });
}
