// FILE: lib/screens/ledger_detail_screen.dart
// This screen shows the detailed financial ledger for a single payer.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:right_angle_interior/models/expense.dart';
import 'package:right_angle_interior/models/ledger_transfer.dart';
import 'package:right_angle_interior/models/payer.dart';
import 'package:right_angle_interior/models/settlement_payment.dart';
import 'package:right_angle_interior/models/wage_payment.dart';
import 'package:right_angle_interior/utils/database_helper.dart';
import 'package:uuid/uuid.dart';

// A helper class to combine different transaction types for a unified timeline
class LedgerTransaction {
  final DateTime date;
  final String description;
  final double amount;
  final String type; // e.g., "Expense", "Wage Payment", "Settlement", "Transfer"

  LedgerTransaction({
    required this.date,
    required this.description,
    required this.amount,
    required this.type,
  });
}

class LedgerDetailScreen extends StatefulWidget {
  final Payer payer;

  const LedgerDetailScreen({super.key, required this.payer});

  @override
  State<LedgerDetailScreen> createState() => _LedgerDetailScreenState();
}

class _LedgerDetailScreenState extends State<LedgerDetailScreen> {
  late Future<Map<String, dynamic>> _ledgerDataFuture;

  @override
  void initState() {
    super.initState();
    _refreshLedgerData();
  }

  // Fetches all necessary data for the ledger from the database
  Future<Map<String, dynamic>> _fetchLedgerData() async {
    final db = DatabaseHelper.instance;
    final payerExpenses = await db.getExpensesByPayer(widget.payer.id);
    final payerWagePayments = await db.getWagePaymentsByPayer(widget.payer.id);
    final paymentsToPayer = await db.getSettlementPaymentsForPayer(widget.payer.id);
    final transfers = await db.getLedgerTransfersForPayer(widget.payer.id);
    final allPayers = await db.getPayers(); // Fetch all payers to get names for transfers

    return {
      'expenses': payerExpenses,
      'wagePayments': payerWagePayments,
      'paymentsToPayer': paymentsToPayer,
      'transfers': transfers,
      'allPayers': allPayers,
    };
  }

  void _refreshLedgerData() {
    setState(() {
      _ledgerDataFuture = _fetchLedgerData();
    });
  }

  void _showSettlePaymentDialog() {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Pay to ${widget.payer.name}'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: amountController,
            decoration: const InputDecoration(labelText: 'Amount (₹)'),
            keyboardType: TextInputType.number,
            validator: (value) => value == null || double.tryParse(value) == null || double.parse(value) <= 0 ? 'Please enter a valid amount.' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newPayment = SettlementPayment(
                  id: const Uuid().v4(),
                  payerId: widget.payer.id,
                  amount: double.parse(amountController.text),
                  date: DateTime.now(),
                );
                await DatabaseHelper.instance.insertSettlementPayment(newPayment);
                _refreshLedgerData();
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Make Payment'),
          ),
        ],
      ),
    );
  }

  void _showTransferDialog() async {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    Payer? selectedToPayer;
    final allPayers = await DatabaseHelper.instance.getPayers();
    // Exclude the current payer from the list of recipients
    final otherPayers = allPayers.where((p) => p.id != widget.payer.id).toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Transfer from ${widget.payer.name}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Payer>(
                value: selectedToPayer,
                decoration: const InputDecoration(labelText: 'Transfer To'),
                items: otherPayers.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                onChanged: (value) => selectedToPayer = value,
                validator: (value) => value == null ? 'Please select a recipient.' : null,
              ),
              TextFormField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount (₹)'),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || double.tryParse(value) == null || double.parse(value) <= 0 ? 'Please enter a valid amount.' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final newTransfer = LedgerTransfer(
                  id: const Uuid().v4(),
                  fromPayerId: widget.payer.id,
                  toPayerId: selectedToPayer!.id,
                  amount: double.parse(amountController.text),
                  date: DateTime.now(),
                );
                await DatabaseHelper.instance.insertLedgerTransfer(newTransfer);
                _refreshLedgerData();
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Transfer'),
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
        title: Text('${widget.payer.name} Ledger'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _ledgerDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final expenses = (snapshot.data?['expenses'] as List<Expense>?) ?? [];
          final wagePayments = (snapshot.data?['wagePayments'] as List<WagePayment>?) ?? [];
          final paymentsToPayer = (snapshot.data?['paymentsToPayer'] as List<SettlementPayment>?) ?? [];
          final transfers = (snapshot.data?['transfers'] as List<LedgerTransfer>?) ?? [];
          final allPayers = (snapshot.data?['allPayers'] as List<Payer>?) ?? [];

          List<LedgerTransaction> transactions = [];

          for (var expense in expenses) {
            transactions.add(LedgerTransaction(date: expense.date, description: 'Expense: ${expense.description}', amount: expense.amount, type: 'spent'));
          }
          for (var payment in wagePayments) {
            transactions.add(LedgerTransaction(date: payment.date, description: 'Wage Payment: ${payment.note}', amount: payment.amount, type: 'spent'));
          }
          for (var payment in paymentsToPayer) {
            transactions.add(LedgerTransaction(date: payment.date, description: 'Settlement Received', amount: payment.amount, type: 'received'));
          }
          for (var transfer in transfers) {
            if (transfer.fromPayerId == widget.payer.id) {
              // Find the recipient's name
              final toPayer = allPayers.firstWhere((p) => p.id == transfer.toPayerId, orElse: () => Payer(id: '', name: 'Unknown'));
              transactions.add(LedgerTransaction(date: transfer.date, description: 'Transferred to ${toPayer.name}', amount: transfer.amount, type: 'sent'));
            } else {
              // Find the sender's name
              final fromPayer = allPayers.firstWhere((p) => p.id == transfer.fromPayerId, orElse: () => Payer(id: '', name: 'Unknown'));
              transactions.add(LedgerTransaction(date: transfer.date, description: 'Received from ${fromPayer.name}', amount: transfer.amount, type: 'received'));
            }
          }

          transactions.sort((a, b) => b.date.compareTo(a.date));

          final double totalSpent = transactions.where((t) => t.type == 'spent' || t.type == 'sent').fold(0.0, (sum, item) => sum + item.amount);
          final double totalReceived = transactions.where((t) => t.type == 'received').fold(0.0, (sum, item) => sum + item.amount);
          final double balance = (widget.payer.openingBalance + totalSpent) - totalReceived;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildSummaryRow('Opening Balance', currencyFormatter.format(widget.payer.openingBalance), Colors.black),
                        _buildSummaryRow('Total Spent / Transferred', currencyFormatter.format(totalSpent), Colors.red),
                        _buildSummaryRow('Total Received', currencyFormatter.format(totalReceived), Colors.green),
                        const Divider(),
                        _buildSummaryRow('Balance Due to ${widget.payer.name}', currencyFormatter.format(balance), Colors.blue, isTotal: true),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(child: ElevatedButton.icon(onPressed: _showSettlePaymentDialog, icon: const Icon(Icons.payment), label: const Text('Settle'))),
                    const SizedBox(width: 16),
                    Expanded(child: ElevatedButton.icon(onPressed: _showTransferDialog, icon: const Icon(Icons.swap_horiz), label: const Text('Transfer'))),
                  ],
                ),
              ),
              const Divider(height: 32),
              Text("Transaction History", style: Theme.of(context).textTheme.titleLarge),
              Expanded(
                child: transactions.isEmpty
                    ? const Center(child: Text('No transactions recorded.'))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: transactions.length,
                  itemBuilder: (ctx, index) {
                    final transaction = transactions[index];
                    return Card(
                      child: ListTile(
                        title: Text(transaction.description),
                        subtitle: Text(DateFormat.yMMMd().format(transaction.date)),
                        trailing: Text(
                          currencyFormatter.format(transaction.amount),
                          style: TextStyle(
                            color: transaction.type == 'received' ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  Widget _buildSummaryRow(String label, String value, Color color, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
