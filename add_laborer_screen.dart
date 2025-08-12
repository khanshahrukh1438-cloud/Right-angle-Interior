// FILE: lib/screens/add_laborer_screen.dart
// This screen contains a form to add a new laborer to the database.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:right_angle_interior/models/laborer.dart';
import 'package:right_angle_interior/models/wage_history.dart';
import 'package:right_angle_interior/utils/database_helper.dart';
import 'package:uuid/uuid.dart';

class AddLaborerScreen extends StatefulWidget {
  const AddLaborerScreen({super.key});

  @override
  State<AddLaborerScreen> createState() => _AddLaborerScreenState();
}

class _AddLaborerScreenState extends State<AddLaborerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _tradeController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _wageController = TextEditingController();
  DateTime? _effectiveDate;
  String? _laborerId;

  @override
  void initState() {
    super.initState();
    _generateLaborerId();
    _effectiveDate = DateTime.now(); // Default effective date to today
  }

  void _generateLaborerId() async {
    final laborers = await DatabaseHelper.instance.getLaborers();
    if (mounted) {
      setState(() {
        _laborerId = 'LBR-${(laborers.length + 1).toString().padLeft(4, '0')}';
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fatherNameController.dispose();
    _tradeController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _wageController.dispose();
    super.dispose();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _effectiveDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    ).then((pickedDate) {
      if (pickedDate != null) {
        setState(() {
          _effectiveDate = pickedDate;
        });
      }
    });
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      final newLaborer = Laborer(
        id: _laborerId!,
        name: _nameController.text,
        fatherName: _fatherNameController.text,
        trade: _tradeController.text,
        contactNumber: _contactController.text,
        address: _addressController.text,
        wageHistory: [], // Will be added next
        wagePayments: [],
      );

      // Save the laborer first
      await DatabaseHelper.instance.insertLaborer(newLaborer);

      // Then, create and save the first wage history record
      final initialWage = WageHistory(
        id: const Uuid().v4(),
        laborerId: newLaborer.id,
        perDayWage: double.parse(_wageController.text),
        effectiveDate: _effectiveDate!,
      );
      await DatabaseHelper.instance.insertWageHistory(initialWage);

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Laborer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (_laborerId != null)
                    Chip(
                      label: Text('Laborer ID: $_laborerId', style: const TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: Theme.of(context).primaryColorLight,
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a name.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fatherNameController,
                    decoration: const InputDecoration(labelText: "Father's Name", prefixIcon: Icon(Icons.family_restroom_outlined), border: OutlineInputBorder()),
                    validator: (value) => value == null || value.trim().isEmpty ? "Please enter father's name." : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tradeController,
                    decoration: const InputDecoration(labelText: 'Trade (e.g., Painter)', prefixIcon: Icon(Icons.construction_outlined), border: OutlineInputBorder()),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a trade.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _wageController,
                    decoration: const InputDecoration(labelText: 'Initial Per Day Wage (₹)', prefixIcon: Icon(Icons.currency_rupee), border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || double.tryParse(value) == null || double.parse(value) <= 0 ? 'Please enter a valid wage.' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(
                      'Effective Date: ${DateFormat.yMd().format(_effectiveDate!)}',
                    ),
                    onTap: _presentDatePicker,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade400)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactController,
                    decoration: const InputDecoration(labelText: 'Contact Number', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder()),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    validator: (value) => value == null || value.length != 10 ? 'Please enter a valid 10-digit number.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.home_outlined), border: OutlineInputBorder()),
                    maxLines: 3,
                    validator: (value) => value == null || value.trim().isEmpty ? 'Please enter an address.' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _submitData,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Add Laborer'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
