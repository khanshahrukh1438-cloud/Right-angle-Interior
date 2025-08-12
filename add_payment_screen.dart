// FILE: lib/screens/add_payment_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:right_angle_interior/models/payer.dart';
import 'package:right_angle_interior/models/wage_payment.dart';
import 'package:right_angle_interior/utils/database_helper.dart';
import 'package:uuid/uuid.dart';

class AddPaymentScreen extends StatefulWidget {
  final String laborerId;
  const AddPaymentScreen({super.key, required this.laborerId});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _selectedDate;
  Payer? _selectedPayer;
  late Future<List<Payer>> _payersFuture;

  @override
  void initState() {
    super.initState();
    _payersFuture = DatabaseHelper.instance.getPayers();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
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
          const SnackBar(content: Text('Please select a payment date.')),
        );
        return;
      }
      if (_selectedPayer == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select who made the payment.')),
        );
        return;
      }

      final newPayment = WagePayment(
        id: const Uuid().v4(),
        laborerId: widget.laborerId,
        payerId: _selectedPayer!.id,
        amount: double.parse(_amountController.text),
        date: _selectedDate!,
        note: _noteController.text,
      );
      await DatabaseHelper.instance.insertWagePayment(newPayment);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Wage Payment')),
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
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.currency_rupee), border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || double.tryParse(value) == null ? 'Please enter a valid amount.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    decoration: const InputDecoration(labelText: 'Note (e.g., For Kitchen Work)', prefixIcon: Icon(Icons.description_outlined), border: OutlineInputBorder()),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a note.' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: Text(
                      _selectedDate == null
                          ? 'Select Payment Date'
                          : 'Date: ${DateFormat.yMd().format(_selectedDate!)}',
                    ),
                    onTap: _presentDatePicker,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Colors.grey.shade400)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _submitData,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Payment'),
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
