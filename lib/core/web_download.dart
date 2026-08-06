import 'dart:html' as html;
import 'dart:typed_data';

/// Triggers a browser download of raw PNG bytes. Web-only (uses dart:html
/// directly since this project targets ONLY Flutter Web / GitHub Pages —
/// no dart:io / mobile fallback is needed).
void downloadPng(Uint8List bytes, String filename) {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
