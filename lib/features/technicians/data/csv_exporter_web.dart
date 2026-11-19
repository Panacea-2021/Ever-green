import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<void> exportCsv(String csv, String filename) async {
  final blob = web.Blob(
    [csv.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
}
