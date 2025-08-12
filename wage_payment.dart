// FILE: lib/models/wage_payment.dart
class WagePayment {
  final String id;
  final String laborerId;
  final String? payerId; // New field to track who made the payment
  final double amount;
  final DateTime date;
  final String note;

  WagePayment({
    required this.id,
    required this.laborerId,
    this.payerId,
    required this.amount,
    required this.date,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'laborerId': laborerId,
      'payerId': payerId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory WagePayment.fromMap(Map<String, dynamic> map) {
    return WagePayment(
      id: map['id'],
      laborerId: map['laborerId'],
      payerId: map['payerId'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      note: map['note'],
    );
  }
}
