// FILE: lib/screens/reports_screen.dart
// This screen displays a financial summary report for all projects.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:right_angle_interior/models/project.dart';
import 'package:right_angle_interior/utils/database_helper.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<Project>> _projectsFuture;

  @override
  void initState() {
    super.initState();
    _projectsFuture = DatabaseHelper.instance.getProjects();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Reports'),
      ),
      body: FutureBuilder<List<Project>>(
        future: _projectsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No projects found to generate a report.'));
          }

          final projects = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];

              // Perform all financial calculations for the report
              final double totalWages = project.assignedLaborers.fold(0.0, (sum, pLaborer) {
                final laborerWages = pLaborer.attendance.fold(0.0, (attSum, record) {
                  final wageOnDate = pLaborer.laborer.getWageForDate(record.date);
                  return attSum + (record.daysWorked * wageOnDate);
                });
                return sum + laborerWages;
              });
              final double totalMaterialExpenses = project.expenses.fold(0.0, (sum, expense) => sum + expense.amount);
              final double grandTotalExpense = totalWages + totalMaterialExpenses;
              final double profitOrLoss = project.budget - grandTotalExpense;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        project.clientName,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const Divider(height: 24),
                      _buildReportRow('Project Budget', currencyFormatter.format(project.budget)),
                      _buildReportRow('Total Wages', currencyFormatter.format(totalWages)),
                      _buildReportRow('Material Expenses', currencyFormatter.format(totalMaterialExpenses)),
                      const Divider(height: 24),
                      _buildReportRow('Total Expenses', currencyFormatter.format(grandTotalExpense), isBold: true),
                      _buildReportRow(
                        'Profit / Loss',
                        currencyFormatter.format(profitOrLoss),
                        isBold: true,
                        valueColor: profitOrLoss >= 0 ? Colors.green.shade700 : Colors.red,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper widget for creating consistent rows in the report card
  Widget _buildReportRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
