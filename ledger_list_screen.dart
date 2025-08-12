// FILE: lib/screens/ledger_list_screen.dart
// This screen displays and manages a list of all ledgers (Payers).

import 'package:flutter/material.dart';
import 'package:right_angle_interior/models/payer.dart';
import 'package:right_angle_interior/screens/ledger_detail_screen.dart';
import 'package:right_angle_interior/utils/database_helper.dart';
import 'package:uuid/uuid.dart';

class LedgerListScreen extends StatefulWidget {
  const LedgerListScreen({super.key});

  @override
  State<LedgerListScreen> createState() => _LedgerListScreenState();
}

class _LedgerListScreenState extends State<LedgerListScreen> {
  late Future<List<Payer>> _payersFuture;

  @override
  void initState() {
    super.initState();
    _refreshPayers();
  }

  void _refreshPayers() {
    setState(() {
      _payersFuture = DatabaseHelper.instance.getPayers();
    });
  }

  void _showPayerDialog({Payer? payer}) {
    final isEditing = payer != null;
    final nameController = TextEditingController(text: isEditing ? payer.name : '');
    final openingBalanceController = TextEditingController(text: isEditing ? payer.openingBalance.toString() : '0.0');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Payer' : 'Add New Payer'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Payer Name (e.g., John Doe)'),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: openingBalanceController,
                decoration: const InputDecoration(labelText: 'Opening Balance (₹)'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || double.tryParse(value) == null ? 'Please enter a valid balance.' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                if (isEditing) {
                  final updatedPayer = Payer(
                    id: payer.id,
                    name: nameController.text,
                    openingBalance: double.parse(openingBalanceController.text),
                    isCompanyAccount: payer.isCompanyAccount,
                  );
                  await DatabaseHelper.instance.updatePayer(updatedPayer);
                } else {
                  final newPayer = Payer(
                    id: const Uuid().v4(),
                    name: nameController.text,
                    openingBalance: double.parse(openingBalanceController.text),
                  );
                  await DatabaseHelper.instance.insertPayer(newPayer);
                }
                _refreshPayers();
                Navigator.of(ctx).pop();
              }
            },
            child: Text(isEditing ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _deletePayer(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to permanently delete this payer? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deletePayer(id);
      _refreshPayers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledgers'),
      ),
      body: FutureBuilder<List<Payer>>(
        future: _payersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No ledgers found. Add one to get started.'));
          }

          final payers = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: payers.length,
            itemBuilder: (context, index) {
              final payer = payers[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Icon(payer.isCompanyAccount ? Icons.business : Icons.person),
                  ),
                  title: Text(payer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showPayerDialog(payer: payer);
                      } else if (value == 'delete') {
                        _deletePayer(payer.id);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit')),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(leading: Icon(Icons.delete_outline), title: Text('Delete')),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LedgerDetailScreen(payer: payer),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showPayerDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Payer',
      ),
    );
  }
}
