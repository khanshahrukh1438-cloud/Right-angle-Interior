// FILE: lib/screens/project_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:right_angle_interior/models/laborer.dart';
import 'package:right_angle_interior/models/project.dart';
import 'package:right_angle_interior/models/project_laborer.dart';
import 'package:right_angle_interior/screens/assign_laborer_screen.dart';
import 'package:right_angle_interior/screens/edit_project_screen.dart';
import 'package:right_angle_interior/screens/mark_attendance_screen.dart';
import 'package:right_angle_interior/screens/ra_bill_list_screen.dart';
import 'package:right_angle_interior/utils/database_helper.dart';
import 'package:uuid/uuid.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project _project;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
    _refreshProjectDetails();
  }

  void _navigateToAssignLaborerScreen() async {
    final selectedLaborer = await Navigator.push<Laborer>(
      context,
      MaterialPageRoute(builder: (context) => const AssignLaborerScreen()),
    );

    if (selectedLaborer != null) {
      if (_project.assignedLaborers.any((pl) => pl.laborer.id == selectedLaborer.id && pl.isActive)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedLaborer.name} is already actively assigned.')),
        );
        return;
      }

      final newAssignment = ProjectLaborer(
        id: const Uuid().v4(),
        projectId: _project.id,
        laborer: selectedLaborer,
        attendance: [],
      );
      await DatabaseHelper.instance.assignLaborerToProject(newAssignment);
      _refreshProjectDetails();
    }
  }

  void _navigateToMarkAttendance() async {
    final activeLaborers = _project.assignedLaborers.where((pl) => pl.isActive).toList();
    if (activeLaborers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no active laborers to mark attendance for.')),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MarkAttendanceScreen(project: _project),
      ),
    );
    _refreshProjectDetails();
  }

  void _navigateToEditProjectScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProjectScreen(project: _project),
      ),
    );
    _refreshProjectDetails();
  }

  void _navigateToRABillList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RABillListScreen(project: _project),
      ),
    );
  }

  void _unassignLaborer(String projectLaborerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to mark this laborer as inactive for this project? Their past records will be preserved.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.unassignLaborerFromProject(projectLaborerId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laborer marked as inactive.'), backgroundColor: Colors.green),
      );
      _refreshProjectDetails();
    }
  }

  void _reassignLaborer(String projectLaborerId) async {
    await DatabaseHelper.instance.reassignLaborerToProject(projectLaborerId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Laborer has been re-activated.'), backgroundColor: Colors.green),
    );
    _refreshProjectDetails();
  }

  void _refreshProjectDetails() async {
    final projects = await DatabaseHelper.instance.getProjects();
    if(mounted) {
      setState(() {
        _project = projects.firstWhere((p) => p.id == widget.project.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    final int laborerCount = _project.assignedLaborers.where((pl) => pl.isActive).length;
    final double totalAttendance = _project.assignedLaborers.fold(0.0, (sum, pLaborer) =>
    sum + pLaborer.attendance.fold(0.0, (attSum, record) => attSum + record.daysWorked));

    final double totalWages = _project.assignedLaborers.fold(0.0, (sum, pLaborer) {
      final laborerWages = pLaborer.attendance.fold(0.0, (attSum, record) {
        final wageOnDate = pLaborer.laborer.getWageForDate(record.date);
        return attSum + (record.daysWorked * wageOnDate);
      });
      return sum + laborerWages;
    });

    final double totalMaterialExpenses = _project.expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    final double grandTotalExpense = totalWages + totalMaterialExpenses;

    return Scaffold(
      appBar: AppBar(
        title: Text(_project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditProjectScreen,
            tooltip: 'Edit Project',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Project Financial Summary", style: Theme.of(context).textTheme.titleLarge),
                    const Divider(height: 20),
                    _buildSummaryRow(Icons.people_outline, 'Active Workers', '$laborerCount'),
                    _buildSummaryRow(Icons.calendar_today_outlined, 'Total Attendance', '$totalAttendance Days'),
                    const Divider(height: 20),
                    _buildSummaryRow(Icons.account_balance_wallet_outlined, 'Total Wages', currencyFormatter.format(totalWages), color: Colors.orange.shade800),
                    _buildSummaryRow(Icons.shopping_cart_outlined, 'Material Expenses', currencyFormatter.format(totalMaterialExpenses), color: Colors.blue.shade800),
                    const Divider(height: 20),
                    _buildSummaryRow(Icons.monetization_on_outlined, 'Total Project Expense', currencyFormatter.format(grandTotalExpense), color: Colors.red.shade800, isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Assigned Laborers', style: Theme.of(context).textTheme.titleLarge),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.square_foot, color: Colors.teal),
                      onPressed: _navigateToRABillList,
                      tooltip: 'RA Bills & Measurements',
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today, color: Colors.teal),
                      onPressed: _navigateToMarkAttendance,
                      tooltip: 'Mark Attendance',
                    ),
                    IconButton(
                      icon: const Icon(Icons.person_add, color: Colors.teal),
                      onPressed: _navigateToAssignLaborerScreen,
                      tooltip: 'Assign Laborer',
                    ),
                  ],
                )
              ],
            ),
            const Divider(),
            _project.assignedLaborers.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('No laborers assigned yet.')))
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _project.assignedLaborers.length,
              itemBuilder: (ctx, index) {
                final projectLaborer = _project.assignedLaborers[index];
                final totalDays = projectLaborer.attendance.fold(0.0, (sum, record) => sum + record.daysWorked);
                return Card(
                  color: projectLaborer.isActive ? null : Colors.grey.shade300,
                  child: ListTile(
                    title: Text(projectLaborer.laborer.name),
                    subtitle: Text('${currencyFormatter.format(projectLaborer.laborer.currentWage)} / day'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$totalDays Days', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (projectLaborer.isActive)
                          IconButton(
                            icon: const Icon(Icons.person_remove_outlined, color: Colors.redAccent),
                            onPressed: () => _unassignLaborer(projectLaborer.id),
                            tooltip: 'Mark as Inactive',
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.green),
                            onPressed: () => _reassignLaborer(projectLaborer.id),
                            tooltip: 'Re-activate Assignment',
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

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
