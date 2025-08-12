// FILE: lib/screens/ra_bill_list_screen.dart
// This screen displays a list of all RA Bills for a project.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:right_angle_interior/models/project.dart';
import 'package:right_angle_interior/models/ra_bill.dart';
import 'package:right_angle_interior/screens/ra_bill_detail_screen.dart';
import 'package:right_angle_interior/utils/database_helper.dart';
import 'package:uuid/uuid.dart';

class RABillListScreen extends StatefulWidget {
  final Project project;

  const RABillListScreen({super.key, required this.project});

  @override
  State<RABillListScreen> createState() => _RABillListScreenState();
}

class _RABillListScreenState extends State<RABillListScreen> {
  late Future<List<RABill>> _raBillsFuture;

  @override
  void initState() {
    super.initState();
    _refreshRABills();
  }

  void _refreshRABills() {
    setState(() {
      _raBillsFuture = DatabaseHelper.instance.getRABills(widget.project.id);
    });
  }

  void _showAddRABillDialog() {
    final billNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add New RA Bill'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: billNameController,
            decoration: const InputDecoration(labelText: 'Bill Name (e.g., RA Bill 1)'),
            validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newBill = RABill(
                  id: const Uuid().v4(),
                  projectId: widget.project.id,
                  billName: billNameController.text,
                  date: DateTime.now(),
                  measurements: [],
                );
                await DatabaseHelper.instance.insertRABill(newBill);
                _refreshRABills();
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _navigateToBillDetail(RABill bill) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        // *** FIX: Pass the project object to the detail screen ***
        builder: (context) => RABillDetailScreen(raBill: bill, project: widget.project),
      ),
    );
    _refreshRABills();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.project.name} - RA Bills'),
      ),
      body: FutureBuilder<List<RABill>>(
        future: _raBillsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No RA Bills created yet.'));
          }

          final raBills = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: raBills.length,
            itemBuilder: (context, index) {
              final bill = raBills[index];
              final totalBillAmount = bill.measurements.fold(0.0, (sum, m) => sum + m.totalAmount);

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColorLight,
                    child: Text('${index + 1}'),
                  ),
                  title: Text(bill.billName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Date: ${DateFormat.yMMMd().format(bill.date)}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormatter.format(totalBillAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          fontSize: 16,
                        ),
                      ),
                      const Text('Total Amount'),
                    ],
                  ),
                  onTap: () => _navigateToBillDetail(bill),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRABillDialog,
        label: const Text('Add RA Bill'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
