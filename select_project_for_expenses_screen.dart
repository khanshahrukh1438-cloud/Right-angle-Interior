// FILE: lib/screens/select_project_for_expenses_screen.dart
// This screen displays a list of all projects to select for viewing expenses.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:right_angle_interior/models/project.dart';
import 'package:right_angle_interior/screens/project_expenses_screen.dart';
import 'package:right_angle_interior/utils/database_helper.dart';

class SelectProjectForExpensesScreen extends StatefulWidget {
  const SelectProjectForExpensesScreen({super.key});

  @override
  State<SelectProjectForExpensesScreen> createState() => _SelectProjectForExpensesScreenState();
}

class _SelectProjectForExpensesScreenState extends State<SelectProjectForExpensesScreen> {
  late Future<List<Project>> _projectsFuture;
  List<Project> _allProjects = [];
  List<Project> _filteredProjects = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _projectsFuture = _loadProjects();
    _searchController.addListener(_filterProjects);
  }

  Future<List<Project>> _loadProjects() async {
    final projects = await DatabaseHelper.instance.getProjects();
    // Sort projects alphabetically by name
    projects.sort((a, b) => a.name.compareTo(b.name));
    if (mounted) {
      setState(() {
        _allProjects = projects;
        _filteredProjects = projects;
      });
    }
    return projects;
  }

  void _filterProjects() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProjects = _allProjects.where((project) {
        return project.name.toLowerCase().contains(query) ||
            project.clientName.toLowerCase().contains(query);
      }).toList();
    });
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
        title: const Text('Select Project'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by Project or Client',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Project>>(
              future: _projectsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (_filteredProjects.isEmpty) {
                  return const Center(child: Text('No projects found.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: _filteredProjects.length,
                  itemBuilder: (context, index) {
                    final project = _filteredProjects[index];
                    // Calculate total expenses for this project
                    final totalExpenses = project.expenses.fold(0.0, (sum, expense) => sum + expense.amount);

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColorLight,
                          child: const Icon(Icons.work_outline),
                        ),
                        title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(project.clientName),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormatter.format(totalExpenses),
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Expenses'),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProjectExpensesScreen(project: project),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
