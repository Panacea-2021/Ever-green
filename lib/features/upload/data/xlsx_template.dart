import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

// The backend bulk uploads read the first row of every sheet as headers,
// matched case-insensitively with spaces as underscores, so each sample keeps
// a single sheet. Every cell is written as text; dates are YYYY-MM-DD.

/// `uploadEquipmentData` headers. Name, Make and Model are required; a blank
/// EG Serial Number is generated. TM Frequency is one of daily, weekly,
/// biweekly, monthly, bi_monthly, tri_monthly, quarterly, semi_annual,
/// annual.
const equipmentTemplateHeaders = [
  'Name',
  'Make',
  'Model',
  'EG Serial Number',
  'Specifications',
  'Location',
  'Description',
  'TM Frequency',
  'Manufacturer Date',
];

const equipmentSampleRows = [
  [
    'Split AC',
    'Daikin',
    'FTKF50',
    '',
    '1.5 Ton Inverter',
    'Ground Floor - Billing Area',
    'Main billing counter AC',
    'quarterly',
    '2025-06-15',
  ],
  [
    'Chiller',
    'Carrier',
    '30XA-252',
    'EG-SAMPLE-0002',
    '250 TR Air Cooled',
    'Terrace',
    'Central cooling plant',
    'monthly',
    '2024-11-01',
  ],
];

/// `uploadCompanyData` headers. company_name, branch_name and all admin_*
/// fields except admin_location are required. service_type: amc, non_amc or
/// regular (blank = amc). amc_type (AMC only): c_amc or nc_amc. start_date /
/// end_date apply to AMC only (blank = today / one year from today).
const companyTemplateHeaders = [
  'company_name',
  'branch_name',
  'admin_name',
  'admin_phone',
  'admin_email',
  'admin_password',
  'admin_location',
  'service_type',
  'amc_type',
  'start_date',
  'end_date',
  'company_email',
  'company_location',
];

const companySampleRows = [
  [
    'Croma',
    'Madhapur',
    'Ravi Kumar',
    '9876543210',
    'ravi.kumar@example.com',
    'Ravi@123',
    'Hyderabad',
    'amc',
    'c_amc',
    '2026-11-01',
    '2027-10-31',
    'madhapur@croma.example.com',
    'Plot 12, Hitech City Road, Madhapur, Hyderabad',
  ],
  [
    'DMart',
    'Kukatpally',
    'Anita Sharma',
    '9123456780',
    'anita.sharma@example.com',
    'Anita@123',
    'Hyderabad',
    'non_amc',
    '',
    '',
    '',
    'kukatpally@dmart.example.com',
    'KPHB Colony, Kukatpally, Hyderabad',
  ],
];

/// `uploadTechnicianData` headers (service engineers). Location is optional.
const technicianTemplateHeaders = [
  'Name',
  'Phone',
  'Email',
  'Password',
  'Designation',
  'Location',
];

/// Designation is "Senior Service Engineer" or "Junior Service Engineer".
const technicianSampleRows = [
  [
    'Suresh Reddy',
    '9988776655',
    'suresh.reddy@example.com',
    'Suresh@123',
    'Senior Service Engineer',
    'Hyderabad',
  ],
  [
    'Kiran Rao',
    '9876501234',
    'kiran.rao@example.com',
    'Kiran@123',
    'Junior Service Engineer',
    'Secunderabad',
  ],
];

/// Builds an .xlsx workbook with one sheet: a bold [headers] row followed by
/// [rows] (text cells; empty strings leave the cell blank).
Uint8List buildXlsxTemplate(
  List<String> headers, {
  List<List<String>> rows = const [],
  String sheetName = 'Sheet1',
}) {
  String esc(String v) => const HtmlEscape(HtmlEscapeMode.element).convert(v);
  String col(int i) {
    var n = i + 1;
    var s = '';
    while (n > 0) {
      final r = (n - 1) % 26;
      s = String.fromCharCode(65 + r) + s;
      n = (n - 1) ~/ 26;
    }
    return s;
  }

  String row(int r, List<String> values, {bool bold = false}) {
    final cells = [
      for (var i = 0; i < values.length; i++)
        if (values[i].isNotEmpty)
          '<c r="${col(i)}$r" t="inlineStr"${bold ? ' s="1"' : ''}>'
              '<is><t xml:space="preserve">${esc(values[i])}</t></is></c>',
    ].join();
    return '<row r="$r">$cells</row>';
  }

  final sheetRows = [
    row(1, headers, bold: true),
    for (var r = 0; r < rows.length; r++) row(r + 2, rows[r]),
  ].join();
  final widths = [
    for (var i = 0; i < headers.length; i++)
      '<col min="${i + 1}" max="${i + 1}" width="24" customWidth="1"/>',
  ].join();

  const xmlHead = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
  final files = <String, String>{
    '[Content_Types].xml': '$xmlHead'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '</Types>',
    '_rels/.rels': '$xmlHead'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>',
    'xl/workbook.xml': '$xmlHead'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets><sheet name="${esc(sheetName)}" sheetId="1" r:id="rId1"/></sheets>'
        '</workbook>',
    'xl/_rels/workbook.xml.rels': '$xmlHead'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
        '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
        '</Relationships>',
    'xl/styles.xml': '$xmlHead'
        '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
        '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
        '<fills count="2"><fill><patternFill patternType="none"/></fill>'
        '<fill><patternFill patternType="gray125"/></fill></fills>'
        '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>'
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
        '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
        '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/></cellXfs>'
        '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
        '</styleSheet>',
    'xl/worksheets/sheet1.xml': '$xmlHead'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<cols>$widths</cols>'
        '<sheetData>$sheetRows</sheetData>'
        '</worksheet>',
  };
  return _storedZip({
    for (final e in files.entries) e.key: utf8.encode(e.value),
  });
}

/// Lets the user save the sample workbook; returns the saved path, or null
/// when cancelled.
Future<String?> saveXlsxTemplate(
  String fileName,
  List<String> headers, {
  List<List<String>> rows = const [],
}) {
  return FilePicker.saveFile(
    dialogTitle: 'Save sample Excel',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: const ['xlsx'],
    bytes: buildXlsxTemplate(headers, rows: rows),
  );
}

/// A zip archive with uncompressed (stored) entries.
Uint8List _storedZip(Map<String, List<int>> entries) {
  final out = BytesBuilder();
  final central = BytesBuilder();
  void u16(BytesBuilder b, int v) => b.add([v & 0xFF, (v >> 8) & 0xFF]);
  void u32(BytesBuilder b, int v) => b.add([
        v & 0xFF,
        (v >> 8) & 0xFF,
        (v >> 16) & 0xFF,
        (v >> 24) & 0xFF,
      ]);

  for (final entry in entries.entries) {
    final name = utf8.encode(entry.key);
    final data = entry.value;
    final crc = _crc32(data);
    final offset = out.length;

    u32(out, 0x04034b50);
    u16(out, 20);
    u16(out, 0x0800);
    u16(out, 0);
    u16(out, 0);
    u16(out, 0x21);
    u32(out, crc);
    u32(out, data.length);
    u32(out, data.length);
    u16(out, name.length);
    u16(out, 0);
    out.add(name);
    out.add(data);

    u32(central, 0x02014b50);
    u16(central, 20);
    u16(central, 20);
    u16(central, 0x0800);
    u16(central, 0);
    u16(central, 0);
    u16(central, 0x21);
    u32(central, crc);
    u32(central, data.length);
    u32(central, data.length);
    u16(central, name.length);
    u16(central, 0);
    u16(central, 0);
    u16(central, 0);
    u16(central, 0);
    u32(central, 0);
    u32(central, offset);
    central.add(name);
  }

  final centralOffset = out.length;
  final centralBytes = central.toBytes();
  out.add(centralBytes);
  u32(out, 0x06054b50);
  u16(out, 0);
  u16(out, 0);
  u16(out, entries.length);
  u16(out, entries.length);
  u32(out, centralBytes.length);
  u32(out, centralOffset);
  u16(out, 0);
  return out.toBytes();
}

int _crc32(List<int> data) {
  var crc = 0xFFFFFFFF;
  for (final byte in data) {
    crc ^= byte;
    for (var k = 0; k < 8; k++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
