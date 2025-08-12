// FILE: lib/screens/add_expense_screen.dart
// This screen contains a form to add a new expense to the database.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:right_angle_interior/models/expense.dart';
import 'package:right_angle_interior/models/payer.dart';
import 'package:right_angle_interior/utils/database_helper.dart';
import 'package:uuid/uuid.dart';

class AddExpenseScreen extends StatefulWidget {
  final String projectId;

  const AddExpenseScreen({super.key, required this.projectId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedType;
  Payer? _selectedPayer;
  late Future<List<Payer>> _payersFuture;

  final List<String> _expenseTypes = [
    'Food', 'Hardware', 'Machine/Tools', 'Material', 'Personal',
    'Petrol/Diesel', 'Ration', 'Rent', 'Travelling',
  ];

  @override
  void initState() {
    super.initState();
    _payersFuture = DatabaseHelper.instance.getPayers();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate != null) {
        setState(() {
          _selectedDate = pickedDate;
        });
      }
    });
  }

  void _submitData() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a date for the expense.')),
        );
        return;
      }
      if (_selectedPayer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select who made the payment.')),
        );
        return;
      }

      final newExpense = Expense(
        id: const Uuid().v4(),
        projectId: widget.projectId,
        payerId: _selectedPayer!.id,
        description: _descriptionController.text,
        type: _selectedType!,
        amount: double.parse(_amountController.text),
        date: _selectedDate!,
      );

      await DatabaseHelper.instance.insertExpense(newExpense);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Expense'),
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
                  FutureBuilder<List<Payer>>(
                    future: _payersFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final payers = snapshot.data!;
                      return DropdownButtonFormField<Payer>(
                        value: _selectedPayer,
                        decoration: const InputDecoration(
                          labelText: 'Paid By',
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                          border: OutlineInputBorder(),
                        ),
                        items: payers.map((payer) => DropdownMenuItem(value: payer, child: Text(payer.name))).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPayer = value;
                          });
                        },
                        validator: (value) => value == null ? 'Please select a payer.' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description (e.g., Paint, Plywood)',
                      prefixIcon: Icon(Icons.description_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a description.' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Expense Type',
                      prefixIcon: Icon(Icons.category_outlined),
                      border: OutlineInputBorder(),
                    ),
                    items: _expenseTypes
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedType = value);
                    },
                    validator: (value) => value == null ? 'Please select an expense type.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount (₹)',
                      prefixIcon: Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || double.tryParse(value) == null ? 'Please enter a valid amount.' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(
                      _selectedDate == null
                          ? 'Select Expense Date'
                          : 'Date: ${DateFormat.yMd().format(_selectedDate!)}',
                    ),
                    onTap: _presentDatePicker,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(color: Colors.grey.shade400),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _submitData,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Expense'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
