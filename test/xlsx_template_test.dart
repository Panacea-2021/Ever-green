import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:evergreen/features/upload/data/xlsx_template.dart';

void main() {
  final samples = {
    'equipment': (equipmentTemplateHeaders, equipmentSampleRows),
    'company': (companyTemplateHeaders, companySampleRows),
    'service_engineer': (technicianTemplateHeaders, technicianSampleRows),
  };

  test('template is a zip with the workbook parts', () {
    final bytes = buildXlsxTemplate(equipmentTemplateHeaders);
    expect(bytes.sublist(0, 4), [0x50, 0x4B, 0x03, 0x04]);
    final text = String.fromCharCodes(bytes);
    expect(text, contains('xl/worksheets/sheet1.xml'));
    expect(text, contains('>EG Serial Number</t>'));
    expect(text, isNot(contains('<row r="2">')));
  });

  test('data rows follow the header row and skip blank cells', () {
    final text = String.fromCharCodes(
      buildXlsxTemplate(
        ['A', 'B', 'C'],
        rows: [
          ['x & y', '', 'z'],
        ],
      ),
    );
    expect(text, contains('<c r="A1" t="inlineStr" s="1">'));
    expect(
      text,
      contains(
        '<c r="A2" t="inlineStr"><is><t xml:space="preserve">x &amp; y</t>',
      ),
    );
    expect(text, isNot(contains('r="B2"')));
    expect(text, contains('<c r="C2" t="inlineStr">'));
  });

  test('every sample row matches its header count', () {
    for (final entry in samples.entries) {
      final (headers, rows) = entry.value;
      expect(rows, isNotEmpty, reason: entry.key);
      for (final row in rows) {
        expect(row.length, headers.length, reason: entry.key);
      }
    }
  });

  test('company sample carries the service type columns', () {
    for (final h in ['service_type', 'amc_type', 'start_date', 'end_date']) {
      expect(companyTemplateHeaders, contains(h));
    }
    final type = companyTemplateHeaders.indexOf('service_type');
    expect(companySampleRows.map((r) => r[type]), ['amc', 'non_amc']);
  });

  test('service engineer designations', () {
    final i = technicianTemplateHeaders.indexOf('Designation');
    expect(technicianSampleRows.map((r) => r[i]), [
      'Senior Service Engineer',
      'Junior Service Engineer',
    ]);
  });

  test('equipment sample frequencies are tm_frequency keys', () {
    const allowed = {
      'daily', 'weekly', 'biweekly', 'monthly', 'bi_monthly', //
      'tri_monthly', 'quarterly', 'semi_annual', 'annual',
    };
    final i = equipmentTemplateHeaders.indexOf('TM Frequency');
    for (final row in equipmentSampleRows) {
      expect(allowed, contains(row[i]));
    }
  });

  // XLSX_TEMPLATE_OUT=<dir> writes the samples for checking with ExcelJS.
  test('writes samples when asked', () {
    final out = Platform.environment['XLSX_TEMPLATE_OUT'];
    if (out == null) return;
    for (final entry in samples.entries) {
      final (headers, rows) = entry.value;
      File('$out/${entry.key}_upload_sample.xlsx')
          .writeAsBytesSync(buildXlsxTemplate(headers, rows: rows));
    }
  });
}
