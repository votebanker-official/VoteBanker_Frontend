import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Native camera (Android / iOS / desktop).
Future<Uint8List?> captureSelfie(BuildContext context) async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.camera,
    preferredCameraDevice: CameraDevice.front,
    maxWidth: 1600,
    imageQuality: 85,
    requestFullMetadata: false,
  );
  if (file == null) {
    return null;
  }
  return file.readAsBytes();
}
