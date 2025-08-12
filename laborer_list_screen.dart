// FILE: lib/screens/laborer_list_screen.dart
// This screen displays a list of all laborers from the database with a financial summary.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:right_angle_interior/models/laborer.dart';
import 'package:right_angle_interior/screens/add_laborer_screen.dart';
import 'package:right_angle_interior/screens/edit_laborer_screen.dart';
import 'package:right_angle_interior/screens/laborer_detail_screen.dart';
import 'package:right_angle_interior/utils/database_helper.dart';

// Helper class to hold the calculated summary for each laborer
class LaborerSummary {
  final Laborer laborer;
  final double totalAttendance;
  final double balance;

  LaborerSummary({
    required this.laborer,
    required this.totalAttendance,
    required this.balance,
  });
}

class LaborerListScreen extends StatefulWidget {
  const LaborerListScreen({super.key});

  @override
  State<LaborerListScreen> createState() => _LaborerListScreenState();
}

class _LaborerListScreenState extends State<LaborerListScreen> {
  late Future<List<LaborerSummary>> _laborersFuture;
  List<LaborerSummary> _allLaborers = [];
  List<LaborerSummary> _filteredLaborers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _laborersFuture = _loadLaborerSummaries();
    _searchController.addListener(_filterLaborers);
  }

  // Fetches all laborers and calculates their financial summary
  Future<List<LaborerSummary>> _loadLaborerSummaries() async {
    final db = DatabaseHelper.instance;
    final laborers = await db.getLaborers();
    final List<LaborerSummary> summaries = [];

    for (var laborer in laborers) {
      final assignments = await db.getProjectsForLaborer(laborer.id);
      final payments = await db.getWagePayments(laborer.id);

      double totalAttendance = 0;
      double totalWagesEarned = 0;

      for (var assignment in assignments) {
        for (var record in assignment.attendance) {
          totalAttendance += record.daysWorked;
          final wageOnDate = laborer.getWageForDate(record.date);
          totalWagesEarned += record.daysWorked * wageOnDate;
        }
      }

      final double totalPaymentsMade = payments.fold(0.0, (sum, item) => sum + item.amount);
      final double balance = totalWagesEarned - totalPaymentsMade;

      summaries.add(LaborerSummary(
        laborer: laborer,
        totalAttendance: totalAttendance,
        balance: balance,
      ));
    }

    // Sort laborers alphabetically by name
    summaries.sort((a, b) => a.laborer.name.compareTo(b.laborer.name));

    if (mounted) {
      setState(() {
        _allLaborers = summaries;
        _filteredLaborers = summaries;
      });
    }
    return summaries;
  }

  void _filterLaborers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLaborers = _allLaborers.where((summary) {
        return summary.laborer.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _refreshLaborers() {
    setState(() {
      _laborersFuture = _loadLaborerSummaries();
    });
  }

  void _navigateToAddLaborerScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddLaborerScreen()),
    );
    _refreshLaborers();
  }

  void _navigateToEditLaborerScreen(Laborer laborer) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditLaborerScreen(laborer: laborer)),
    );
    _refreshLaborers();
  }

  void _deleteLaborer(BuildContext context, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to permanently delete this laborer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteLaborer(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Laborer deleted successfully'),
            backgroundColor: Colors.green),
      );
      _refreshLaborers();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laborers'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Name',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<LaborerSummary>>(
              future: _laborersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (_filteredLaborers.isEmpty) {
                  return const Center(child: Text('No laborers found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _filteredLaborers.length,
                  itemBuilder: (context, index) {
                    final summary = _filteredLaborers[index];
                    final laborer = summary.laborer;

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LaborerDetailScreen(laborer: laborer),
                            ),
                          );
                          _refreshLaborers();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      laborer.name,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  // Row for Edit and Delete buttons
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.edit_outlined, color: Colors.blue.shade700),
                                        onPressed: () => _navigateToEditLaborerScreen(laborer),
                                        tooltip: 'Edit Laborer',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                        onPressed: () => _deleteLaborer(context, laborer.id),
                                        tooltip: 'Delete Laborer',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                laborer.trade,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const Divider(height: 24),
                              _buildInfoRow(
                                Icons.currency_rupee,
                                'Current Wage',
                                '${currencyFormatter.format(laborer.currentWage)} / day',
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.calendar_today_outlined,
                                'Total Attendance',
                                '${summary.totalAttendance} Days',
                              ),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                Icons.account_balance_wallet_outlined,
                                'Balance Amount',
                                currencyFormatter.format(summary.balance),
                                valueColor: summary.balance >= 0 ? Colors.green : Colors.red,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddLaborerScreen,
        tooltip: 'Add Laborer',
        icon: const Icon(Icons.add),
        label: const Text('Add Laborer'),
      ),
    );
  }

  // Helper widget for creating consistent info rows
  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(color: Colors.grey.shade800))),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}
