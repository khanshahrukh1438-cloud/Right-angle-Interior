// FILE: lib/models/ledger_transfer.dart
// This file defines the data structure for a transfer between two payers.

class LedgerTransfer {
  final String id;
  final String fromPayerId;
  final String toPayerId;
  final double amount;
  final DateTime date;

  LedgerTransfer({
    required this.id,
    required this.fromPayerId,
    required this.toPayerId,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromPayerId': fromPayerId,
      'toPayerId': toPayerId,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory LedgerTransfer.fromMap(Map<String, dynamic> map) {
    return LedgerTransfer(
      id: map['id'],
      fromPayerId: map['fromPayerId'],
      toPayerId: map['toPayerId'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
    );
  }
}
