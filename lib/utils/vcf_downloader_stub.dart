import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> downloadVcf({
  required String content,
  required String filename,
  required String contactName,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(content);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'text/vcard', name: filename)],
    subject: '$contactName - Contact Card',
  );
}
