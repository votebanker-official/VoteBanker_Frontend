import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Compact skip control shared by the mobile and web layouts.
///
/// Place it at the top-right of the scrolling page content. Do not put it in
/// the app bar, navigation bar, or footer, and do not pin it to the viewport.
class CircularSkipButton extends StatelessWidget {
  const CircularSkipButton({required this.onPressed, super.key});

  final VoidCallback? onPressed;

  static const Color background = Color(0xFF0866FF);
  static const double buttonWidth = 76;
  static const double buttonHeight = 44;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final size = buttonWidth;
    // #region agent log
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      final binding = WidgetsBinding.instance.runtimeType.toString();
      if (binding.contains('Test')) return;
      final box = context.findRenderObject();
      if (box is! RenderBox || !box.hasSize || !box.attached) return;
      final origin = box.localToGlobal(Offset.zero);
      final screen = MediaQuery.sizeOf(context);
      final payload = <String, Object?>{
        'sessionId': '3f8cb7',
        'hypothesisId': 'A-B-D',
        'location': 'circular_skip_button.dart',
        'message': 'skip layout',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'data': {
          'route': ModalRoute.of(context)?.settings.name,
          'kIsWeb': kIsWeb,
          'width': size,
          'height': buttonHeight,
          'paintedWidth': box.size.width,
          'paintedHeight': box.size.height,
          'left': origin.dx,
          'top': origin.dy,
          'rightGap': screen.width - (origin.dx + box.size.width),
          'screenWidth': screen.width,
          'screenHeight': screen.height,
        },
      };
      http
          .post(
            Uri.parse(
              'http://127.0.0.1:7337/ingest/75959716-472f-4d0f-8b88-2b7d19c8618c',
            ),
            headers: const {
              'Content-Type': 'application/json',
              'X-Debug-Session-Id': '3f8cb7',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(milliseconds: 400))
          .then((_) {}, onError: (_) {});
    });
    // #endregion
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Skip',
      child: Material(
        color: enabled ? background : background.withValues(alpha: 0.45),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          hoverColor: Colors.white.withValues(alpha: 0.14),
          highlightColor: Colors.white.withValues(alpha: 0.18),
          splashColor: Colors.white.withValues(alpha: 0.24),
          child: SizedBox(
            width: size,
            height: buttonHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.keyboard_double_arrow_right_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
