// Web download uses the browser anchor API. This file is only compiled for web.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

Future<String> saveSpeechDocument(String filename, String content) async {
  final blob = html.Blob([utf8.encode(content)], 'text/plain;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
  return filename;
}
