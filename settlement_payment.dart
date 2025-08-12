// FILE: lib/models/settlement_payment.dart
// This file defines the data structure for a settlement payment made to a payer.

class SettlementPayment {
  final String id;
  final String payerId;
  final double amount;
  final DateTime date;

  SettlementPayment({
    required this.id,
    required this.payerId,
    required this.amount,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'payerId': payerId,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory SettlementPayment.fromMap(Map<String, dynamic> map) {
    return SettlementPayment(
      id: map['id'],
      payerId: map['payerId'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
    );
  }
}
