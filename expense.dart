// FILE: lib/models/expense.dart
// This file defines the data structure for a single Expense.

class Expense {
  final String id;
  final String projectId;
  final String? payerId; // New field to track who made the payment
  final String description;
  final String type;
  final double amount;
  final DateTime date;

  Expense({
    required this.id,
    required this.projectId,
    this.payerId,
    required this.description,
    required this.type,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'payerId': payerId,
      'description': description,
      'type': type,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      projectId: map['projectId'],
      payerId: map['payerId'],
      description: map['description'],
      type: map['type'] ?? 'Other',
      amount: map['amount'],
      date: DateTime.parse(map['date']),
    );
  }
}
