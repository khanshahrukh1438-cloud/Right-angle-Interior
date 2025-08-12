// FILE: lib/screens/edit_project_screen.dart
// This screen contains a form to edit an existing project's details.

import 'package:flutter/material.dart';
import 'package:right_angle_interior/models/project.dart';
import 'package:right_angle_interior/utils/database_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProjectScreen extends StatefulWidget {
  final Project project;

  const EditProjectScreen({super.key, required this.project});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _clientNameController;
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _pincodeController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late String _status;
  bool _isLoadingPincode = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _clientNameController = TextEditingController(text: widget.project.clientName);
    _addressLine1Controller = TextEditingController(text: widget.project.addressLine1);
    _addressLine2Controller = TextEditingController(text: widget.project.addressLine2);
    _pincodeController = TextEditingController(text: widget.project.pincode);
    _cityController = TextEditingController(text: widget.project.city);
    _stateController = TextEditingController(text: widget.project.state);
    _status = widget.project.status;
    _pincodeController.addListener(_onPincodeChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _pincodeController.removeListener(_onPincodeChanged);
    _pincodeController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  void _onPincodeChanged() {
    final pincode = _pincodeController.text;
    if (pincode.length == 6) {
      _fetchPincodeDetails(pincode);
    } else {
      _cityController.clear();
      _stateController.clear();
    }
  }

  Future<void> _fetchPincodeDetails(String pincode) async {
    if (!mounted) return;
    setState(() => _isLoadingPincode = true);

    try {
      final response = await http.get(Uri.parse('https://api.postalpincode.in/pincode/$pincode'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data[0]['Status'] == 'Success') {
          final postOffice = data[0]['PostOffice'][0];
          if (mounted) {
            setState(() {
              _cityController.text = postOffice['District'];
              _stateController.text = postOffice['State'];
            });
          }
        } else {
          _cityController.clear();
          _stateController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid Pincode.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not fetch pincode details. Please check your connection.')),
      );
    } finally {
      if (mounted) setState(() => _isLoadingPincode = false);
    }
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      final updatedProject = Project(
        id: widget.project.id,
        name: _nameController.text,
        clientName: _clientNameController.text,
        addressLine1: _addressLine1Controller.text,
        addressLine2: _addressLine2Controller.text,
        pincode: _pincodeController.text,
        city: _cityController.text,
        state: _stateController.text,
        startDate: widget.project.startDate,
        endDate: widget.project.endDate,
        budget: widget.project.budget,
        status: _status,
        expenses: widget.project.expenses,
        assignedLaborers: widget.project.assignedLaborers,
      );

      await DatabaseHelper.instance.updateProject(updatedProject);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Project'),
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
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Project Name', prefixIcon: Icon(Icons.work_outline), border: OutlineInputBorder()),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter a project name.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _clientNameController,
                    decoration: const InputDecoration(labelText: 'Client Name', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter a client name.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressLine1Controller,
                    decoration: const InputDecoration(labelText: 'Address Line 1', prefixIcon: Icon(Icons.location_on_outlined), border: OutlineInputBorder()),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter an address.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addressLine2Controller,
                    decoration: const InputDecoration(labelText: 'Address Line 2 (Optional)', prefixIcon: Icon(Icons.add_location_alt_outlined), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pincodeController,
                    decoration: InputDecoration(
                      labelText: 'Pincode',
                      prefixIcon: const Icon(Icons.pin_drop_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: _isLoadingPincode ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()) : null,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (value) => value == null || value.length != 6 ? 'Please enter a valid 6-digit pincode.' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City', prefixIcon: Icon(Icons.location_city_outlined), border: OutlineInputBorder()),
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(labelText: 'State', prefixIcon: Icon(Icons.map_outlined), border: OutlineInputBorder()),
                          readOnly: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Project Status', prefixIcon: Icon(Icons.flag_outlined), border: OutlineInputBorder()),
                    items: ['Planned', 'Ongoing', 'Completed']
                        .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
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
