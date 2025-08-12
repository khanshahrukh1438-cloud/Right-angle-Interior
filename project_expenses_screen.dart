// FILE: lib/screens/project_expenses_screen.dart
// This screen displays and manages expenses for a single project.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:right_angle_interior/models/expense.dart';
import 'package:right_angle_interior/models/project.dart';
import 'package:right_angle_interior/screens/add_expense_screen.dart';
import 'package:right_angle_interior/screens/edit_expense_screen.dart';
import 'package:right_angle_interior/utils/database_helper.dart';

class ProjectExpensesScreen extends StatefulWidget {
  final Project project;

  const ProjectExpensesScreen({super.key, required this.project});

  @override
  State<ProjectExpensesScreen> createState() => _ProjectExpensesScreenState();
}

class _ProjectExpensesScreenState extends State<ProjectExpensesScreen> {
  late Future<List<Expense>> _expensesFuture;
  List<Expense> _allExpenses = [];
  List<Expense> _filteredExpenses = [];
  String? _selectedTypeFilter;
  DateTime? _selectedMonthFilter;

  final List<String> _expenseTypes = [
    'Food', 'Hardware', 'Machine/Tools', 'Material', 'Personal',
    'Petrol/Diesel', 'Ration', 'Rent', 'Travelling',
  ];

  @override
  void initState() {
    super.initState();
    _refreshExpenses();
  }

  void _refreshExpenses() {
    setState(() {
      _expensesFuture = DatabaseHelper.instance.getExpenses(widget.project.id)
          .then((expenses) {
        // Process and sort the data here, outside of the build method
        expenses.sort((a, b) => b.date.compareTo(a.date));
        _allExpenses = expenses;
        _applyFilters(); // Apply filters once after data is fetched
        return expenses; // Return the original list for the FutureBuilder
      });
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredExpenses = _allExpenses.where((expense) {
        final typeMatch = _selectedTypeFilter == null || expense.type == _selectedTypeFilter;
        final monthMatch = _selectedMonthFilter == null ||
            (expense.date.year == _selectedMonthFilter!.year &&
                expense.date.month == _selectedMonthFilter!.month);
        return typeMatch && monthMatch;
      }).toList();
    });
  }

  void _navigateToAddExpense() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(projectId: widget.project.id),
      ),
    );
    _refreshExpenses();
  }

  void _navigateToEditExpense(Expense expense) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditExpenseScreen(expense: expense),
      ),
    );
    _refreshExpenses();
  }

  void _deleteExpense(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Do you want to permanently delete this expense record?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Yes')),
        ],
      ),
    );

    if (confirm == true) {
      await DatabaseHelper.instance.deleteExpense(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted successfully'), backgroundColor: Colors.green),
      );
      _refreshExpenses();
    }
  }

  void _pickMonth() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedMonthFilter ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (pickedDate != null) {
      setState(() {
        _selectedMonthFilter = pickedDate;
        _applyFilters();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.project.name} Expenses'),
      ),
      body: FutureBuilder<List<Expense>>(
        future: _expensesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Data is now processed before this build method runs.
          // We just need to calculate the total for the currently filtered list.
          final totalFilteredExpenses = _filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);

          return Column(
            children: [
              // Filter Section
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedTypeFilter,
                        decoration: InputDecoration(
                          labelText: 'Filter by Type',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.category_outlined),
                        ),
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text('All Types')),
                          ..._expenseTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTypeFilter = value;
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.calendar_month_outlined),
                      tooltip: 'Filter by Month',
                      onPressed: _pickMonth,
                    ),
                    if (_selectedMonthFilter != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        tooltip: 'Clear Month Filter',
                        onPressed: () {
                          setState(() {
                            _selectedMonthFilter = null;
                            _applyFilters();
                          });
                        },
                      ),
                  ],
                ),
              ),
              // Summary Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Displayed', style: Theme.of(context).textTheme.titleLarge),
                        Text(
                          currencyFormatter.format(totalFilteredExpenses),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Expense List
              if (_filteredExpenses.isEmpty)
                const Expanded(child: Center(child: Text('No expenses match your filters.')))
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = _filteredExpenses[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          leading: const Icon(Icons.receipt_long_outlined),
                          title: Text(expense.description),
                          subtitle: Text('${expense.type} - ${DateFormat.yMMMd().format(expense.date)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(currencyFormatter.format(expense.amount)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _deleteExpense(expense.id),
                                tooltip: 'Delete Expense',
                              )
                            ],
                          ),
                          onTap: () => _navigateToEditExpense(expense),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddExpense,
        label: const Text('Add Expense'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
