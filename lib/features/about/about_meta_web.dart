import 'package:web/web.dart';

const aboutPageTitle = 'About Us | VoteBanker';
const aboutPageDescription =
    'VoteBanker is a Voter Relationship Management platform that helps candidates, campaign teams, and organizers manage voter outreach and field coordination in one workspace.';

String? _previousTitle;
String? _previousDescription;

void applyAboutMeta() {
  _previousTitle = document.title;
  document.title = aboutPageTitle;
  final meta = document.querySelector('meta[name="description"]');
  if (meta == null) return;
  _previousDescription = meta.getAttribute('content');
  meta.setAttribute('content', aboutPageDescription);
}

void restoreAboutMeta() {
  if (_previousTitle != null) document.title = _previousTitle!;
  final meta = document.querySelector('meta[name="description"]');
  if (meta != null && _previousDescription != null) {
    meta.setAttribute('content', _previousDescription!);
  }
}
