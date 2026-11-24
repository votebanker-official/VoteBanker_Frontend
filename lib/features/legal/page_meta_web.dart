import 'package:web/web.dart';

String? _previousTitle;
String? _previousDescription;

void applyPageMeta(String title, String description) {
  _previousTitle ??= document.title;
  document.title = title;
  final meta = document.querySelector('meta[name="description"]');
  if (meta == null) return;
  _previousDescription ??= meta.getAttribute('content');
  meta.setAttribute('content', description);
}

void restorePageMeta() {
  if (_previousTitle != null) document.title = _previousTitle!;
  final meta = document.querySelector('meta[name="description"]');
  if (meta != null && _previousDescription != null) {
    meta.setAttribute('content', _previousDescription!);
  }
}
