import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../domain/models/task_item.dart';

/// Generates a printable / shareable "Service Report" PDF for a task, matching
/// the Evergreen report layout: a navy company header, service + ticket info,
/// an equipment table, the issue, a timeline of events, photos, customer
/// confirmation, and the service cost.
class ServiceReportService {
  const ServiceReportService._();

  static const PdfColor _navy = PdfColor.fromInt(0xFF102A43);
  static const PdfColor _navyBar = PdfColor.fromInt(0xFF143A5A);
  static const PdfColor _blue = PdfColor.fromInt(0xFF1F6FEB);
  static const PdfColor _grey = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _light = PdfColor.fromInt(0xFFF1F4F8);
  static const PdfColor _red = PdfColor.fromInt(0xFFD32F2F);

  /// Build the PDF bytes for [task].
  static Future<Uint8List> build(TaskItem task) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _header(task),
              _infoStrip(task),
              pw.SizedBox(height: 10),
              _threeColumn(task),
              pw.SizedBox(height: 12),
              _sectionBar(task.isIndividual ? 'TASK' : 'EQUIPMENT'),
              _equipmentTable(task),
              pw.SizedBox(height: 12),
              _sectionBar('ISSUE'),
              _issue(task),
              pw.SizedBox(height: 12),
              _sectionBar('TIMELINE OF EVENTS'),
              _timeline(task),
              pw.SizedBox(height: 12),
              _sectionBar('TASK PHOTOS / ATTACHMENTS'),
              _attachments(task),
              pw.SizedBox(height: 12),
              _sectionBar('CUSTOMER CONFIRMATION'),
              _confirmation(task),
              pw.SizedBox(height: 12),
              _sectionBar('SERVICE COST'),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Text('-', style: const pw.TextStyle(fontSize: 10)),
              ),
              pw.Spacer(),
              pw.Text(
                'Evergreen Enterprises Sainathnagar, Hyderabad service.9@example.com',
                style: const pw.TextStyle(fontSize: 7, color: _grey),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  /// Generate and open the native share sheet for [task]. [bytes] is a
  /// ready-made report (e.g. the backend's PDF); otherwise one is built.
  static Future<void> share(TaskItem task, {Uint8List? bytes}) async {
    final pdf = bytes ?? await build(task);
    await Printing.sharePdf(
      bytes: pdf,
      filename: 'Ticket_${_fileTicket(task)}.pdf',
    );
  }

  /// Open the system print / preview dialog for [task].
  static Future<void> open(TaskItem task, {Uint8List? bytes}) async {
    await Printing.layoutPdf(
      name: 'Ticket_${_fileTicket(task)}',
      onLayout: (format) async => bytes ?? await build(task),
    );
  }

  static String _fileTicket(TaskItem t) =>
      (t.ticketNo.isEmpty ? '${t.taskId}' : t.ticketNo)
          .replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');

  // --- PDF sections --------------------------------------------------------

  static pw.Widget _header(TaskItem t) {
    return pw.Container(
      color: _navy,
      padding: const pw.EdgeInsets.all(14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'EVERGREEN ENTERPRISES',
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 15,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Imported and Indian Equipment Spares and Service',
                    style:
                        const pw.TextStyle(color: PdfColors.white, fontSize: 8),
                  ),
                ],
              ),
              pw.Container(
                color: _blue,
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: pw.Text(
                  'SERVICE REPORT',
                  style: const pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoStrip(TaskItem t) {
    return pw.Container(
      color: _navy,
      padding: const pw.EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: pw.Row(
        children: [
          _stripCol(
            'Service Report',
            t.ticketNo,
            statusLabel: t.lifecycleLabel,
          ),
          _stripCol('Ticket', t.ticketNo),
          _stripCol('Generated', _fmtDateTime(DateTime.now())),
        ],
      ),
    );
  }

  static pw.Widget _stripCol(
    String label,
    String value, {
    String? statusLabel,
  }) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            value,
            style: const pw.TextStyle(
              color: PdfColors.white,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (statusLabel != null) ...[
            pw.SizedBox(height: 3),
            pw.Container(
              color: _red,
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: pw.Text(
                statusLabel,
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _threeColumn(TaskItem t) {
    pw.Widget col(String title, List<String> lines) {
      return pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              color: _light,
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              child: pw.Text(
                title.toUpperCase(),
                style: const pw.TextStyle(
                  fontSize: 7,
                  color: _navy,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            for (final l in lines)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 2),
                child: pw.Text(l, style: const pw.TextStyle(fontSize: 8.5)),
              ),
          ],
        ),
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (t.isIndividual)
          col('Contact', [
            _dash(t.contactName),
            _dash(t.contactPhone),
            _dash(t.address),
          ])
        else
          col('Company', [
            _dash(t.companyName),
            _dash(t.source?.company?.location ?? t.source?.equipment?.location),
          ]),
        pw.SizedBox(width: 8),
        col('Raised By', [
          _dash(t.clientName),
          'Created by ${_dash(t.managerName)}',
        ]),
        pw.SizedBox(width: 8),
        col('Service Engineer', [
          t.hasAssignee ? t.assignee : 'Not assigned',
          t.hasAssignee
              ? (t.technicianPhone.isEmpty
                  ? 'Assigned Service Engineer'
                  : t.technicianPhone)
              : '-',
        ]),
      ],
    );
  }

  static pw.Widget _sectionBar(String title) {
    return pw.Container(
      width: double.infinity,
      color: _navyBar,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: pw.Text(
        title,
        style: const pw.TextStyle(
          color: PdfColors.white,
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _equipmentTable(TaskItem t) {
    pw.Widget cell(String k, String v) {
      return pw.Expanded(
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 58,
              child: pw.Text(
                k,
                style: const pw.TextStyle(fontSize: 8, color: _grey),
              ),
            ),
            pw.Expanded(
              child: pw.Text(v, style: const pw.TextStyle(fontSize: 8.5)),
            ),
          ],
        ),
      );
    }

    pw.Widget row(List<pw.Widget> cells) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 3),
          child: pw.Row(children: cells),
        );

    final e = t.source?.equipment;
    final serial = [e?.egSerialNumber ?? '', e?.serialNumber ?? '']
        .where((s) => s.isNotEmpty)
        .join(' / ');
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4),
      child: pw.Column(
        children: [
          if (e != null) ...[
            row([cell('Name', _dash(t.equipment)), cell('Make', _dash(e.make))]),
            row([cell('Model', _dash(e.model)), cell('Serial No.', _dash(serial))]),
          ],
          row([
            cell('Call type', _dash(t.callType?.label)),
            cell('Created on', _fmtDateTime(t.createdAt)),
          ]),
        ],
      ),
    );
  }

  static pw.Widget _issue(TaskItem t) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            t.title,
            style: const pw.TextStyle(
              fontSize: 10,
              color: _blue,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            t.description.isNotEmpty
                ? t.description
                : t.equipment.isNotEmpty
                    ? '${t.equipment} issue'
                    : '-',
            style: const pw.TextStyle(fontSize: 8, color: _grey),
          ),
        ],
      ),
    );
  }

  static pw.Widget _timeline(TaskItem t) {
    final events = <(String, DateTime?, String)>[
      ('Task created', t.createdAt, 'Ticket ${t.ticketNo} was raised.'),
      if (t.hasAssignee)
        (
          'Service Engineer assigned',
          t.assignedAt,
          '${t.assignee} ${t.acceptedAt != null ? 'accepted this task' : 'was assigned'}.'
        ),
      if (t.startedAt != null)
        ('Work started', t.startedAt, 'Service Engineer started work on-site.'),
      if (t.resolvedAt != null)
        (
          'Work completed',
          t.resolvedAt,
          t.resolutionNotes ?? 'Work completed.'
        ),
      if (t.serviceStatus == ServiceStatus.closed)
        ('Closed', t.closedAt, 'Ticket closed.'),
    ];
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final e in events)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 6,
                    height: 6,
                    margin: const pw.EdgeInsets.only(top: 2, right: 6),
                    decoration: const pw.BoxDecoration(
                      color: _blue,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          e.$2 != null ? _fmtDateTime(e.$2!) : '-',
                          style: const pw.TextStyle(fontSize: 7, color: _grey),
                        ),
                        pw.Text(
                          e.$1,
                          style: const pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(e.$3, style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _attachments(TaskItem t) {
    if (t.attachments.isEmpty) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6),
        child: pw.Text(
          'No attachments.',
          style: const pw.TextStyle(fontSize: 8.5, color: _grey),
        ),
      );
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final a in t.attachments)
            pw.Text(
              '• ${a.split('/').last}',
              style: const pw.TextStyle(fontSize: 8.5, color: _blue),
            ),
        ],
      ),
    );
  }

  static pw.Widget _confirmation(TaskItem t) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Serviced to satisfaction : ${_yesNo(t.source?.serviceSatisfactory)}',
            style: const pw.TextStyle(fontSize: 9, color: _blue),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Comments : ${_dash(t.feedback)}',
            style: const pw.TextStyle(fontSize: 9, color: _blue),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Rating : ${t.rating != null ? '${t.rating} / 5' : '-'}',
            style: const pw.TextStyle(fontSize: 9, color: _blue),
          ),
        ],
      ),
    );
  }

  // --- helpers -------------------------------------------------------------

  static String _dash(String? s) => (s == null || s.trim().isEmpty) ? '-' : s;

  static String _yesNo(bool? v) => v == null ? '-' : (v ? 'Yes' : 'No');

  static String _fmtDateTime(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    final date =
        '${d.day.toString().padLeft(2, '0')} ${_month(d.month)} ${d.year}';
    return '$date, ${h.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $ampm';
  }

  static String _month(int m) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][m - 1];
}
