import 'dart:io';

Future<String> saveSpeechDocument(String filename, String content) async {
  final directory = _downloadDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$filename');
  await file.writeAsString(content);
  return file.path;
}

Directory _downloadDirectory() {
  if (Platform.isWindows) {
    final home = Platform.environment['USERPROFILE'];
    if (home != null) {
      final downloads = Directory('$home\\Downloads');
      if (downloads.existsSync()) {
        return downloads;
      }
    }
  } else if (Platform.isLinux || Platform.isMacOS) {
    final home = Platform.environment['HOME'];
    if (home != null) {
      final downloads = Directory('$home/Downloads');
      if (downloads.existsSync()) {
        return downloads;
      }
    }
  }
  return Directory.systemTemp;
}
