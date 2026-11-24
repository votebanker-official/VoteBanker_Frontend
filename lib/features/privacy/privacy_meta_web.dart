import 'package:web/web.dart';

const privacyPageTitle = 'Privacy Policy | VoteBanker';
const privacyPageDescription =
    'How VoteBanker, a private campaign workspace, processes account, voter, and team data under India\'s DPDP Act, 2023.';

String? _previousTitle;
String? _previousDescription;

void applyPrivacyMeta() {
  _previousTitle = document.title;
  document.title = privacyPageTitle;
  final meta = document.querySelector('meta[name="description"]');
  if (meta == null) return;
  _previousDescription = meta.getAttribute('content');
  meta.setAttribute('content', privacyPageDescription);
}

void restorePrivacyMeta() {
  if (_previousTitle != null) document.title = _previousTitle!;
  final meta = document.querySelector('meta[name="description"]');
  if (meta != null && _previousDescription != null) {
    meta.setAttribute('content', _previousDescription!);
  }
}
