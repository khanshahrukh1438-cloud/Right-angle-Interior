// FILE: lib/screens/edit_laborer_screen.dart
// This screen contains a form to edit an existing laborer's details and manage wage history.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:right_angle_interior/models/laborer.dart';
import 'package:right_angle_interior/models/wage_history.dart';
import 'package:right_angle_interior/utils/database_helper.dart';
import 'package:uuid/uuid.dart';

class EditLaborerScreen extends StatefulWidget {
  final Laborer laborer;

  const EditLaborerScreen({super.key, required this.laborer});

  @override
  State<EditLaborerScreen> createState() => _EditLaborerScreenState();
}

class _EditLaborerScreenState extends State<EditLaborerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _fatherNameController;
  late TextEditingController _tradeController;
  late TextEditingController _contactController;
  late TextEditingController _addressController;
  late TextEditingController _wageController;
  late DateTime _effectiveDate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.laborer.name);
    _fatherNameController = TextEditingController(text: widget.laborer.fatherName);
    _tradeController = TextEditingController(text: widget.laborer.trade);
    _contactController = TextEditingController(text: widget.laborer.contactNumber);
    _addressController = TextEditingController(text: widget.laborer.address);
    // Initialize with the current wage and today's date for a potential new wage entry
    _wageController = TextEditingController(text: widget.laborer.currentWage.toString());
    _effectiveDate = DateTime.now();
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
      initialDate: _effectiveDate,
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
      // Update the laborer's personal details
      final updatedLaborer = Laborer(
        id: widget.laborer.id,
        name: _nameController.text,
        fatherName: _fatherNameController.text,
        trade: _tradeController.text,
        contactNumber: _contactController.text,
        address: _addressController.text,
        wageHistory: widget.laborer.wageHistory,
        wagePayments: widget.laborer.wagePayments,
      );
      await DatabaseHelper.instance.updateLaborer(updatedLaborer);

      // Check if the wage has been changed and add a new history record if it has
      final newWage = double.parse(_wageController.text);
      if (newWage != widget.laborer.currentWage) {
        final newWageRecord = WageHistory(
          id: const Uuid().v4(),
          laborerId: widget.laborer.id,
          perDayWage: newWage,
          effectiveDate: _effectiveDate,
        );
        await DatabaseHelper.instance.insertWageHistory(newWageRecord);
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Laborer'),
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
                  Chip(
                    label: Text('Laborer ID: ${widget.laborer.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    decoration: const InputDecoration(labelText: 'Current Per Day Wage (₹)', prefixIcon: Icon(Icons.currency_rupee), border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || double.tryParse(value) == null || double.parse(value) <= 0 ? 'Please enter a valid wage.' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(
                      'Effective Date: ${DateFormat.yMd().format(_effectiveDate)}',
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
                    icon: const Icon(Icons.save),
                    label: const Text('Save Changes'),
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
