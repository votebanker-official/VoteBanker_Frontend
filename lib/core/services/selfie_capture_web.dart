// Live webcam on web. image_picker's camera source opens a file dialog on
// desktop browsers, so this uses getUserMedia instead.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../../app/localization/app_localizations.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

Future<Uint8List?> captureSelfie(BuildContext context) {
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _WebSelfieDialog(),
  );
}

class _WebSelfieDialog extends StatefulWidget {
  const _WebSelfieDialog();

  @override
  State<_WebSelfieDialog> createState() => _WebSelfieDialogState();
}

class _WebSelfieDialogState extends State<_WebSelfieDialog> {
  late final String _viewType;
  late final html.VideoElement _video;
  html.MediaStream? _stream;
  var _ready = false;
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _viewType = 'votebanker-selfie-${identityHashCode(this)}';
    _video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..controls = false;
    _video.setAttribute('playsinline', 'true');
    _video.style
      ..width = '100%'
      ..height = '100%'
      ..border = '0'
      ..objectFit = 'cover'
      ..transform = 'scaleX(-1)';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int _) => _video,
    );
    unawaited(_start());
  }

  Future<void> _start() async {
    try {
      final devices = html.window.navigator.mediaDevices;
      if (devices == null) {
        throw StateError('no mediaDevices');
      }
      html.MediaStream stream;
      try {
        stream = await devices.getUserMedia({
          'audio': false,
          'video': {
            'facingMode': 'user',
            'width': {'ideal': 1280},
            'height': {'ideal': 720},
          },
        });
      } catch (_) {
        stream = await devices.getUserMedia({
          'audio': false,
          'video': true,
        });
      }
      if (!mounted) {
        stream.getTracks().forEach((track) => track.stop());
        return;
      }
      _stream = stream;
      _video.srcObject = stream;
      await _video.play();
      if (mounted) {
        setState(() => _ready = true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context).cameraUnavailable;
        });
      }
    }
  }

  Future<void> _capture() async {
    if (!_ready || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final width = _video.videoWidth == 0 ? 1280 : _video.videoWidth;
      final height = _video.videoHeight == 0 ? 720 : _video.videoHeight;
      final canvas = html.CanvasElement(width: width, height: height);
      final ctx = canvas.context2D
        ..translate(width, 0)
        ..scale(-1, 1);
      ctx.drawImageScaled(_video, 0, 0, width, height);
      final dataUrl = canvas.toDataUrl('image/jpeg', 0.85);
      final comma = dataUrl.indexOf(',');
      final bytes = base64Decode(dataUrl.substring(comma + 1));
      if (mounted) {
        Navigator.of(context).pop(Uint8List.fromList(bytes));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = AppLocalizations.of(context).photoError;
        });
      }
    }
  }

  void _stopCamera() {
    _stream?.getTracks().forEach((track) => track.stop());
    _video.srcObject = null;
    _stream = null;
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = context.palette;
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: l10n.back,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ColoredBox(
                    color: const Color(0xFF111111),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        HtmlElementView(viewType: _viewType),
                        if (_error != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body(
                                  context,
                                ).copyWith(color: Colors.white),
                              ),
                            ),
                          )
                        else if (!_ready)
                          const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: FilledButton.icon(
                onPressed: _ready && !_busy && _error == null ? _capture : null,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(l10n.capturePhoto),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.accent,
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
