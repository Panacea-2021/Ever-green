import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../amcs/data/equipment_provider.dart';

/// Fetches the backend QR sticker PDF and opens the system share sheet.
/// Throws on failure so callers can show the message.
Future<void> shareQrStickerPdf(
  WidgetRef ref, {
  int? companyId,
  List<int>? equipmentIds,
  required String filename,
}) async {
  final bytes = await ref
      .read(equipmentApiProvider)
      .qrStickerPdf(companyId: companyId, equipmentIds: equipmentIds);
  await Printing.sharePdf(bytes: bytes, filename: filename);
}

/// File-name-safe version of [value].
String qrFileSlug(String value) {
  final slug = value
      .trim()
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return slug.isEmpty ? 'equipment' : slug;
}
