import 'csv_exporter_stub.dart'
    if (dart.library.js_interop) 'csv_exporter_web.dart'
    if (dart.library.io) 'csv_exporter_io.dart' as implementation;

Future<void> exportCsv(String csv, String filename) =>
    implementation.exportCsv(csv, filename);
