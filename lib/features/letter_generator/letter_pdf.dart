import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List> buildLetterPdf(String text) async {
  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(56, 56, 56, 56),
      build: (context) => [
        pw.Text(
          text.trim(),
          style: const pw.TextStyle(fontSize: 12, lineSpacing: 3),
        ),
      ],
    ),
  );
  return document.save();
}
