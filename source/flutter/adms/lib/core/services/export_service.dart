import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/models.dart';

// =============================================================================
// PROVIDER
// =============================================================================

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

// =============================================================================
// EXPORT SERVICE
// =============================================================================

/// Generates PDF and CSV reports from incident and unit data.
class ExportService {
  final _df = DateFormat('yyyy-MM-dd HH:mm');

  // ===========================================================================
  // INCIDENTS — PDF
  // ===========================================================================

  /// Generate and show a PDF report of incidents via the system print dialog.
  Future<void> printIncidentsPdf({
    required BuildContext context,
    required List<Incident> incidents,
    required String title,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('Generated: ${_df.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.Divider(),
          ],
        ),
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 7),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.centerLeft,
            },
            headers: [
              'ID',
              'Description',
              'Severity',
              'Status',
              'Created',
              'Address',
            ],
            data: incidents.map((i) {
              return [
                i.id.substring(0, 8),
                i.description.length > 40
                    ? '${i.description.substring(0, 40)}…'
                    : i.description,
                i.severity.name,
                i.status.displayName,
                _df.format(i.createdAt),
                i.address ?? '—',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Total incidents: ${incidents.length}',
              style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: '${title.replaceAll(' ', '_')}.pdf',
    );
  }

  // ===========================================================================
  // INCIDENTS — CSV
  // ===========================================================================

  /// Generate CSV string for incidents.
  String incidentsToCsv(List<Incident> incidents) {
    final rows = <List<String>>[
      ['ID', 'Description', 'Severity', 'Status', 'Created', 'Address', 'Reporter', 'Assigned Unit'],
      ...incidents.map((i) => [
            i.id,
            i.description,
            i.severity.name,
            i.status.displayName,
            _df.format(i.createdAt),
            i.address ?? '',
            i.reporterName ?? '',
            i.assignedUnitId ?? '',
          ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  // ===========================================================================
  // UNITS — PDF
  // ===========================================================================

  /// Generate and show a PDF report of ambulance units.
  Future<void> printUnitsPdf({
    required BuildContext context,
    required List<AmbulanceUnit> units,
    required String title,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('Generated: ${_df.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.Divider(),
          ],
        ),
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
            headers: ['Call Sign', 'Plate', 'Type', 'Status', 'Driver', 'Active'],
            data: units.map((u) {
              return [
                u.callSign,
                u.plateNumber,
                u.type.displayName,
                u.status.displayName,
                u.assignedDriverName ?? '—',
                u.isActive ? 'Yes' : 'No',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Total units: ${units.length}',
              style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: '${title.replaceAll(' ', '_')}.pdf',
    );
  }

  // ===========================================================================
  // UNITS — CSV
  // ===========================================================================

  /// Generate CSV string for ambulance units.
  String unitsToCsv(List<AmbulanceUnit> units) {
    final rows = <List<String>>[
      ['Call Sign', 'Plate', 'Type', 'Status', 'Driver', 'Active'],
      ...units.map((u) => [
            u.callSign,
            u.plateNumber,
            u.type.displayName,
            u.status.displayName,
            u.assignedDriverName ?? '',
            u.isActive ? 'Yes' : 'No',
          ]),
    ];
    return const ListToCsvConverter().convert(rows);
  }

  // ===========================================================================
  // MAINTENANCE — PDF
  // ===========================================================================

  /// Generate and show a PDF report of maintenance records.
  Future<void> printMaintenancePdf({
    required BuildContext context,
    required List<MaintenanceRecord> records,
    required String title,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text('Generated: ${_df.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.Divider(),
          ],
        ),
        build: (ctx) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration:
                const pw.BoxDecoration(color: PdfColors.grey300),
            headers: [
              'Unit',
              'Type',
              'Status',
              'Scheduled',
              'Completed',
              'Cost',
            ],
            data: records.map((r) {
              return [
                r.unitCallSign,
                r.type.displayName,
                r.status.displayName,
                _df.format(r.scheduledDate),
                r.completedDate != null ? _df.format(r.completedDate!) : '—',
                r.cost != null ? r.cost!.toStringAsFixed(2) : '—',
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 16),
          pw.Text('Total records: ${records.length}',
              style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => pdf.save(),
      name: '${title.replaceAll(' ', '_')}.pdf',
    );
  }
}
