// FILE: lib/screens/measurement_sheet_screen.dart
// This screen displays and manages the measurement sheet for a specific RA Bill.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:right_angle_interior/models/measurement.dart';
import 'package:right_angle_interior/models/ra_bill.dart';
import 'package:right_angle_interior/utils/database_helper.dart';
import 'package:uuid/uuid.dart';

// A helper class to manage the state of a single measurement row in the form
class MeasurementRow {
  final String tempId = const Uuid().v4();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController lengthController = TextEditingController(text: '0.0');
  TextEditingController widthController = TextEditingController(text: '0.0');
  TextEditingController quantityController = TextEditingController(text: '1.0');
  TextEditingController rateController = TextEditingController(text: '0.0');
  String unit = 'Sq. Ft.';
  double totalArea = 0.0;

  void dispose() {
    descriptionController.dispose();
    lengthController.dispose();
    widthController.dispose();
    quantityController.dispose();
    rateController.dispose();
  }
}

class MeasurementSheetScreen extends StatefulWidget {
  final RABill raBill;

  const MeasurementSheetScreen({super.key, required this.raBill});

  @override
  State<MeasurementSheetScreen> createState() => _MeasurementSheetScreenState();
}

class _MeasurementSheetScreenState extends State<MeasurementSheetScreen> {
  late Future<List<Measurement>> _measurementsFuture;
  final List<MeasurementRow> _newMeasurementRows = [];
  final List<String> _units = ['Sq. Ft.', 'Running Ft.', 'Sq. Mtr.', 'Running Mtr.', 'Nos.'];

  @override
  void initState() {
    super.initState();
    _refreshMeasurements();
    _addNewMeasurementRow(); // Start with one empty row
  }

  @override
  void dispose() {
    for (var row in _newMeasurementRows) {
      row.dispose();
    }
    super.dispose();
  }

  void _refreshMeasurements() {
    setState(() {
      _measurementsFuture = DatabaseHelper.instance.getMeasurements(widget.raBill.id);
    });
  }

  void _addNewMeasurementRow() {
    setState(() {
      _newMeasurementRows.add(MeasurementRow());
    });
  }

  void _removeMeasurementRow(String tempId) {
    setState(() {
      final rowToRemove = _newMeasurementRows.firstWhere((row) => row.tempId == tempId);
      rowToRemove.dispose();
      _newMeasurementRows.removeWhere((row) => row.tempId == tempId);
    });
  }

  void _calculateTotalArea(MeasurementRow row) {
    final length = double.tryParse(row.lengthController.text) ?? 0.0;
    final width = double.tryParse(row.widthController.text) ?? 0.0;
    final quantity = double.tryParse(row.quantityController.text) ?? 1.0;

    setState(() {
      if (row.unit == 'Nos.') {
        row.totalArea = quantity;
      } else {
        row.totalArea = length * width * quantity;
      }
    });
  }

  void _saveAllMeasurements() async {
    List<Measurement> measurementsToSave = [];
    for (var row in _newMeasurementRows) {
      if (row.descriptionController.text.isNotEmpty) {
        measurementsToSave.add(
          Measurement(
            id: const Uuid().v4(),
            raBillId: widget.raBill.id,
            description: row.descriptionController.text,
            length: double.tryParse(row.lengthController.text) ?? 0.0,
            width: double.tryParse(row.widthController.text) ?? 0.0,
            quantity: double.tryParse(row.quantityController.text) ?? 1.0,
            unit: row.unit,
            rate: double.tryParse(row.rateController.text) ?? 0.0,
          ),
        );
      }
    }

    if (measurementsToSave.isNotEmpty) {
      await DatabaseHelper.instance.insertMultipleMeasurements(measurementsToSave);
    }
    _refreshMeasurements();
    setState(() {
      for (var row in _newMeasurementRows) {
        row.dispose();
      }
      _newMeasurementRows.clear();
      _addNewMeasurementRow();
    });
  }

  // *** NEW: Dialog for adding AND editing measurements ***
  void _showMeasurementDialog({Measurement? measurement}) {
    final isEditing = measurement != null;
    final formKey = GlobalKey<FormState>();
    final descriptionController = TextEditingController(text: isEditing ? measurement.description : '');
    final lengthController = TextEditingController(text: isEditing ? measurement.length.toString() : '0.0');
    final widthController = TextEditingController(text: isEditing ? measurement.width.toString() : '0.0');
    final quantityController = TextEditingController(text: isEditing ? measurement.quantity.toString() : '1.0');
    final rateController = TextEditingController(text: isEditing ? measurement.rate.toString() : '0.0');
    String selectedUnit = isEditing ? measurement.unit : 'Sq. Ft.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Measurement' : 'Add Measurement'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                DropdownButtonFormField<String>(
                  value: selectedUnit,
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: _units.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      selectedUnit = value;
                    }
                  },
                ),
                TextFormField(
                  controller: lengthController,
                  decoration: const InputDecoration(labelText: 'Length'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || double.tryParse(value) == null ? 'Invalid' : null,
                ),
                TextFormField(
                  controller: widthController,
                  decoration: const InputDecoration(labelText: 'Width/Height'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || double.tryParse(value) == null ? 'Invalid' : null,
                ),
                TextFormField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || double.tryParse(value) == null ? 'Invalid' : null,
                ),
                TextFormField(
                  controller: rateController,
                  decoration: const InputDecoration(labelText: 'Rate'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || double.tryParse(value) == null ? 'Invalid' : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newMeasurement = Measurement(
                  id: isEditing ? measurement.id : const Uuid().v4(),
                  raBillId: widget.raBill.id,
                  description: descriptionController.text,
                  length: double.parse(lengthController.text),
                  width: double.parse(widthController.text),
                  quantity: double.parse(quantityController.text),
                  unit: selectedUnit,
                  rate: double.parse(rateController.text),
                );

                if (isEditing) {
                  await DatabaseHelper.instance.updateMeasurement(newMeasurement);
                } else {
                  await DatabaseHelper.instance.insertMeasurement(newMeasurement);
                }
                _refreshMeasurements();
                Navigator.of(ctx).pop();
              }
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.raBill.billName),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Measurement>>(
              future: _measurementsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final existingMeasurements = snapshot.data ?? [];

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        if (existingMeasurements.isNotEmpty)
                          _buildMeasurementsTable(existingMeasurements, currencyFormatter),
                        const Divider(height: 32),
                        Text("Add New Measurements", style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        ..._newMeasurementRows.map((row) => _buildMeasurementInputRow(row)),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Add More'),
                              onPressed: _addNewMeasurementRow,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveAllMeasurements,
                icon: const Icon(Icons.save),
                label: const Text('Save All New Measurements'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementsTable(List<Measurement> measurements, NumberFormat formatter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Description')),
          DataColumn(label: Text('Total Area'), numeric: true),
          DataColumn(label: Text('Rate'), numeric: true),
          DataColumn(label: Text('Amount'), numeric: true),
          DataColumn(label: Text('Actions')),
        ],
        rows: measurements.map((m) {
          return DataRow(cells: [
            DataCell(Text(m.description)),
            DataCell(Text('${m.totalArea.toStringAsFixed(2)} ${m.unit}')),
            DataCell(Text(formatter.format(m.rate))),
            DataCell(Text(formatter.format(m.totalAmount))),
            DataCell(Row(
              children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: Colors.blue.shade700, size: 20),
                  onPressed: () => _showMeasurementDialog(measurement: m),
                  tooltip: 'Edit Measurement',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () async {
                    await DatabaseHelper.instance.deleteMeasurement(m.id);
                    _refreshMeasurements();
                  },
                  tooltip: 'Delete Measurement',
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildMeasurementInputRow(MeasurementRow row) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextFormField(
              controller: row.descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: row.unit,
                    decoration: const InputDecoration(labelText: 'Unit'),
                    items: _units.map((unit) => DropdownMenuItem(value: unit, child: Text(unit))).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          row.unit = value;
                          _calculateTotalArea(row);
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: row.rateController,
                    decoration: const InputDecoration(labelText: 'Rate'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: row.lengthController,
                    decoration: const InputDecoration(labelText: 'Length'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateTotalArea(row),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: row.widthController,
                    decoration: const InputDecoration(labelText: 'Width/Height'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateTotalArea(row),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: row.quantityController,
                    decoration: const InputDecoration(labelText: 'Qty'),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _calculateTotalArea(row),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Area: ${row.totalArea.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_newMeasurementRows.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeMeasurementRow(row.tempId),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
