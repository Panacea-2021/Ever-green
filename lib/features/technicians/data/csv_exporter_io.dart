import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<void> exportCsv(String csv, String filename) async {
  await FilePicker.saveFile(
    dialogTitle: 'Save performance report',
    fileName: filename,
    type: FileType.custom,
    allowedExtensions: const ['csv'],
    bytes: Uint8List.fromList(utf8.encode(csv)),
  );
}
