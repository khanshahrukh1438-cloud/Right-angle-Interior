// FILE: lib/models/wage_history.dart
// This file defines the data structure for a single wage history entry.

class WageHistory {
  final String id;
  final String laborerId;
  final double perDayWage;
  final DateTime effectiveDate;

  WageHistory({
    required this.id,
    required this.laborerId,
    required this.perDayWage,
    required this.effectiveDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'laborerId': laborerId,
      'perDayWage': perDayWage,
      'effectiveDate': effectiveDate.toIso8601String(),
    };
  }

  factory WageHistory.fromMap(Map<String, dynamic> map) {
    return WageHistory(
      id: map['id'],
      laborerId: map['laborerId'],
      perDayWage: map['perDayWage'],
      effectiveDate: DateTime.parse(map['effectiveDate']),
    );
  }
}
