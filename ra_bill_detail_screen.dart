// FILE: lib/screens/ra_bill_detail_screen.dart
// This screen shows the details and measurement summary for a single RA Bill.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:right_angle_interior/models/measurement.dart';
import 'package:right_angle_interior/models/project.dart';
import 'package:right_angle_interior/models/ra_bill.dart';
import 'package:right_angle_interior/screens/measurement_sheet_screen.dart';
import 'package:right_angle_interior/utils/database_helper.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:open_file/open_file.dart';


class RABillDetailScreen extends StatefulWidget {
  final RABill raBill;
  final Project project; // We need project details for the export

  const RABillDetailScreen({super.key, required this.raBill, required this.project});

  @override
  State<RABillDetailScreen> createState() => _RABillDetailScreenState();
}

class _RABillDetailScreenState extends State<RABillDetailScreen> {
  late Future<List<Measurement>> _measurementsFuture;

  @override
  void initState() {
    super.initState();
    _refreshMeasurements();
  }

  void _refreshMeasurements() {
    setState(() {
      _measurementsFuture = DatabaseHelper.instance.getMeasurements(widget.raBill.id);
    });
  }

  void _navigateToMeasurementSheet() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeasurementSheetScreen(raBill: widget.raBill),
      ),
    );
    _refreshMeasurements();
  }

  // --- PDF and Excel Export Logic ---

  Future<void> _exportToPdf(List<Measurement> measurements) async {
    final pdf = pw.Document();
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final totalBillAmount = measurements.fold(0.0, (sum, m) => sum + m.totalAmount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(widget.raBill.billName, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text('Project: ${widget.project.name}', style: const pw.TextStyle(fontSize: 18)),
            pw.Text('Client: ${widget.project.clientName}', style: const pw.TextStyle(fontSize: 18)),
            pw.Text('Address: ${widget.project.addressLine1}, ${widget.project.city}', style: const pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Description', 'L', 'W/H', 'Qty', 'Unit', 'Total Area', 'Rate', 'Amount'],
              data: measurements.map((m) => [
                m.description,
                m.length.toString(),
                m.width.toString(),
                m.quantity.toString(),
                m.unit,
                m.totalArea.toStringAsFixed(2),
                currencyFormatter.format(m.rate),
                currencyFormatter.format(m.totalAmount),
              ]).toList(),
            ),
            pw.Divider(height: 20),
            pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Grand Total: ', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text(currencyFormatter.format(totalBillAmount), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                ]
            )
          ];
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/${widget.raBill.billName}.pdf");
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(file.path);
  }

  Future<void> _exportToExcel(List<Measurement> measurements) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    // Helper to create CellValue objects
    CellValue textCell(String text) => TextCellValue(text);
    CellValue doubleCell(double value) => DoubleCellValue(value);

    // Add headers
    sheetObject.appendRow([textCell('Project:'), textCell(widget.project.name)]);
    sheetObject.appendRow([textCell('Client:'), textCell(widget.project.clientName)]);
    sheetObject.appendRow([textCell('Bill:'), textCell(widget.raBill.billName)]);
    sheetObject.appendRow([]); // Empty row for spacing
    sheetObject.appendRow([
      textCell('Description'), textCell('Length'), textCell('Width/Height'),
      textCell('Quantity'), textCell('Unit'), textCell('Total Area'),
      textCell('Rate'), textCell('Total Amount')
    ]);

    final totalBillAmount = measurements.fold(0.0, (sum, m) => sum + m.totalAmount);

    for (var m in measurements) {
      sheetObject.appendRow([
        textCell(m.description),
        doubleCell(m.length),
        doubleCell(m.width),
        doubleCell(m.quantity),
        textCell(m.unit),
        doubleCell(m.totalArea),
        doubleCell(m.rate),
        doubleCell(m.totalAmount),
      ]);
    }

    sheetObject.appendRow([]); // Empty row for spacing
    sheetObject.appendRow([
      textCell(''), textCell(''), textCell(''), textCell(''),
      textCell(''), textCell(''), textCell('Grand Total:'),
      doubleCell(totalBillAmount)
    ]);

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/${widget.raBill.billName}.xlsx");
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
      OpenFile.open(file.path);
    }
  }


  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.raBill.billName),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              final measurements = await _measurementsFuture;
              if (value == 'pdf') {
                _exportToPdf(measurements);
              } else if (value == 'excel') {
                _exportToExcel(measurements);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'pdf',
                child: ListTile(leading: Icon(Icons.picture_as_pdf), title: Text('Export PDF')),
              ),
              const PopupMenuItem<String>(
                value: 'excel',
                child: ListTile(leading: Icon(Icons.table_chart), title: Text('Export Excel')),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Measurement>>(
        future: _measurementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final measurements = snapshot.data ?? [];
          final totalBillAmount = measurements.fold(0.0, (sum, m) => sum + m.totalAmount);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Bill Amount', style: Theme.of(context).textTheme.titleLarge),
                        Text(
                          currencyFormatter.format(totalBillAmount),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Divider(indent: 16, endIndent: 16),
              Expanded(
                child: measurements.isEmpty
                    ? const Center(child: Text('No measurements added to this bill yet.'))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: measurements.length,
                  itemBuilder: (context, index) {
                    final measurement = measurements[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              measurement.description,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const Divider(height: 16),
                            _buildMeasurementDetailRow(
                              'Calculation',
                              '${measurement.length} x ${measurement.width} x ${measurement.quantity} = ${measurement.totalArea.toStringAsFixed(2)} ${measurement.unit}',
                            ),
                            _buildMeasurementDetailRow(
                              'Rate',
                              '${currencyFormatter.format(measurement.rate)} / ${measurement.unit}',
                            ),
                            const Divider(height: 16),
                            _buildMeasurementDetailRow(
                              'Total Amount',
                              currencyFormatter.format(measurement.totalAmount),
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToMeasurementSheet,
        label: const Text('Add/Edit Measurements'),
        icon: const Icon(Icons.edit_document),
      ),
    );
  }

  // Helper widget for displaying measurement details in a row
  Widget _buildMeasurementDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
