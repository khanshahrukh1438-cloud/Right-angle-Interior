// FILE: lib/screens/dashboard_screen.dart
// This file contains the UI for the main dashboard.

import 'package:flutter/material.dart';
import 'package:right_angle_interior/screens/laborer_list_screen.dart';
import 'package:right_angle_interior/screens/ledger_list_screen.dart'; // New import
import 'package:right_angle_interior/screens/projects_screen.dart';
import 'package:right_angle_interior/screens/reports_screen.dart';
import 'package:right_angle_interior/screens/select_project_for_attendance_screen.dart';
import 'package:right_angle_interior/screens/select_project_for_expenses_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: <Widget>[
            _buildDashboardItem(
              context,
              'Projects',
              Icons.business_center,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProjectsScreen())),
            ),
            _buildDashboardItem(
              context,
              'Attendance',
              Icons.calendar_today,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectProjectForAttendanceScreen())),
            ),
            _buildDashboardItem(
              context,
              'Labor',
              Icons.people,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LaborerListScreen())),
            ),
            _buildDashboardItem(
              context,
              'Expenses',
              Icons.attach_money,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectProjectForExpensesScreen())),
            ),
            // *** UPDATED NAVIGATION ***
            _buildDashboardItem(
              context,
              'Ledgers',
              Icons.account_balance_wallet,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LedgerListScreen())),
            ),
            _buildDashboardItem(
              context,
              'Reports',
              Icons.bar_chart,
                  () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen())),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 50, color: Theme.of(context).primaryColor),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
