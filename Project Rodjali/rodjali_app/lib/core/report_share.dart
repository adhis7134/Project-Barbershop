import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:share_plus/share_plus.dart';

const _xlsxMime = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// Web: file langsung terunduh. Android/iOS: membuka menu bagikan (simpan ke Drive, kirim WhatsApp, buka di Excel).
Future<void> saveOrShareWorkbook(xl.Excel book, String fileName) async {
  if (kIsWeb) {
    book.save(fileName: fileName);
    return;
  }
  final bytes = book.save();
  if (bytes == null) throw StateError('Berkas Excel gagal dibuat.');
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(Uint8List.fromList(bytes), mimeType: _xlsxMime, name: fileName)],
      fileNameOverrides: [fileName],
    ),
  );
}
