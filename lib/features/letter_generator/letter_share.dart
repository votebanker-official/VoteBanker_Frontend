import 'package:share_plus/share_plus.dart';

Future<void> shareLetterText(String text, {String? subject}) {
  return Share.share(text, subject: subject);
}
