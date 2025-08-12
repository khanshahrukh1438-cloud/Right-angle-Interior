// FILE: lib/screens/laborer_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:right_angle_interior/models/attendance_record.dart';
import 'package:right_angle_interior/models/laborer.dart';
// *** FIX: Corrected the import path ***
import 'package:right_angle_interior/models/project_laborer.dart';
import 'package:right_angle_interior/models/wage_payment.dart';
import 'package:right_angle_interior/screens/add_payment_screen.dart';
import 'package:right_angle_interior/screens/edit_attendance_screen.dart';
import 'package:right_angle_interior/screens/edit_wage_payment_screen.dart';
import 'package:right_angle_interior/utils/database_helper.dart';

// A helper class to combine attendance and payments for a unified timeline
class Transaction {
  final DateTime date;
  final String description;
  final double amount;
  final bool isCredit; // true for wages earned, false for payments made
  final dynamic originalObject; // To hold the original WagePayment or AttendanceRecord

  Transaction({
    required this.date,
    required this.description,
    required this.amount,
    required this.isCredit,
    this.originalObject,
  });
}

class LaborerDetailScreen extends StatefulWidget {
  final Laborer laborer;

  const LaborerDetailScreen({super.key, required this.laborer});

  @override
  State<LaborerDetailScreen> createState() => _LaborerDetailScreenState();
}

class _LaborerDetailScreenState extends State<LaborerDetailScreen> {
  late Future<Map<String, dynamic>> _laborerDataFuture;

  @override
  void initState() {
    super.initState();
    _refreshLaborerData();
  }

  // Fetches all necessary data for the laborer from the database
  Future<Map<String, dynamic>> _fetchLaborerData() async {
    final assignments = await DatabaseHelper.instance.getProjectsForLaborer(widget.laborer.id);
    final payments = await DatabaseHelper.instance.getWagePayments(widget.laborer.id);
    return {'assignments': assignments, 'payments': payments};
  }

  void _refreshLaborerData() {
    setState(() {
      _laborerDataFuture = _fetchLaborerData();
    });
  }

  void _navigateToAddPayment() async {
    await Navigator.push<WagePayment>(
      context,
      MaterialPageRoute(builder: (context) => AddPaymentScreen(laborerId: widget.laborer.id)),
    );
    _refreshLaborerData();
  }

  void _navigateToEditPayment(WagePayment payment) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditWagePaymentScreen(wagePayment: payment)),
    );
    _refreshLaborerData();
  }

  void _navigateToEditAttendance(AttendanceRecord record) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditAttendanceScreen(attendanceRecord: record)),
    );
    _refreshLaborerData();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(title: Text(widget.laborer.name)),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _laborerDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final assignments = (snapshot.data?['assignments'] as List<ProjectLaborer>?) ?? [];
          final payments = (snapshot.data?['payments'] as List<WagePayment>?) ?? [];

          double totalAttendance = 0;
          double totalWages = 0;
          List<Transaction> transactions = [];

          for (var assignment in assignments) {
            for (var record in assignment.attendance) {
              totalAttendance += record.daysWorked;
              // Use the historical wage for the calculation
              final wageOnDate = assignment.laborer.getWageForDate(record.date);
              final wageEarned = record.daysWorked * wageOnDate;
              totalWages += wageEarned;
              transactions.add(Transaction(
                date: record.date,
                description: 'Work: ${record.daysWorked} days',
                amount: wageEarned,
                isCredit: true,
                originalObject: record,
              ));
            }
          }

          final double totalPayment = payments.fold(0.0, (sum, item) => sum + item.amount);
          for (var payment in payments) {
            transactions.add(Transaction(
              date: payment.date,
              description: 'Payment: ${payment.note}',
              amount: payment.amount,
              isCredit: false,
              originalObject: payment,
            ));
          }

          transactions.sort((a, b) => b.date.compareTo(a.date));
          final double totalBalance = totalWages - totalPayment;

          return Column(
            children: [
              // Financial Summary Card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Financial Summary", style: Theme.of(context).textTheme.titleLarge),
                        const Divider(height: 20),
                        _buildSummaryRow(Icons.calendar_today_outlined, 'Total Attendance', '$totalAttendance Days'),
                        _buildSummaryRow(Icons.add_card, 'Total Wages Earned', currencyFormatter.format(totalWages), color: Colors.green),
                        _buildSummaryRow(Icons.money_off, 'Total Payments Made', currencyFormatter.format(totalPayment), color: Colors.red),
                        const Divider(height: 20),
                        _buildSummaryRow(Icons.account_balance_wallet_outlined, 'Balance Due', currencyFormatter.format(totalBalance), color: Colors.blue, isTotal: true),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _navigateToAddPayment,
                    icon: const Icon(Icons.add_card),
                    label: const Text('Pay Wages'),
                  ),
                ),
              ),
              const Divider(height: 32),
              Text("Transaction History", style: Theme.of(context).textTheme.titleLarge),
              // Transaction List
              Expanded(
                child: transactions.isEmpty
                    ? const Center(child: Text('No attendance or payments recorded.'))
                    : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: transactions.length,
                  itemBuilder: (ctx, index) {
                    final transaction = transactions[index];
                    return Card(
                      color: transaction.isCredit ? Colors.green.shade50 : Colors.red.shade50,
                      child: ListTile(
                        leading: Icon(
                          transaction.isCredit ? Icons.arrow_upward : Icons.arrow_downward,
                          color: transaction.isCredit ? Colors.green : Colors.red,
                        ),
                        title: Text(transaction.description),
                        subtitle: Text(DateFormat.yMMMd().format(transaction.date)),
                        trailing: Text(
                          currencyFormatter.format(transaction.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: transaction.isCredit ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                        onTap: () {
                          if (transaction.originalObject is WagePayment) {
                            _navigateToEditPayment(transaction.originalObject as WagePayment);
                          } else if (transaction.originalObject is AttendanceRecord) {
                            _navigateToEditAttendance(transaction.originalObject as AttendanceRecord);
                          }
                        },
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

  // Helper widget for the summary card
  Widget _buildSummaryRow(IconData icon, String label, String value, {Color? color, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: TextStyle(fontSize: 16, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal))),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
