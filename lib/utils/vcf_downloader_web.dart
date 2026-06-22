// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<void> downloadVcf({
  required String content,
  required String filename,
  required String contactName,
}) async {
  final blob = html.Blob([content], 'text/vcard;charset=utf-8');
  final objectUrl = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.document.createElement('a') as html.AnchorElement;
  anchor.href = objectUrl;
  anchor.download = filename;

  // Must be in DOM for Firefox and some Chromium builds to trigger download
  html.document.body!.append(anchor);
  anchor.click();
  anchor.remove();

  html.Url.revokeObjectUrl(objectUrl);
}
