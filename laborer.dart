// FILE: lib/models/laborer.dart
import 'package:right_angle_interior/models/wage_history.dart';
import 'package:right_angle_interior/models/wage_payment.dart';

class Laborer {
  final String id;
  final String name;
  final String fatherName;
  final String trade;
  final String contactNumber;
  final String address;
  List<WageHistory> wageHistory; // Use a list for wage history
  List<WagePayment> wagePayments;

  Laborer({
    required this.id,
    required this.name,
    required this.fatherName,
    required this.trade,
    required this.contactNumber,
    required this.address,
    required this.wageHistory, // Updated constructor
    required this.wagePayments,
  });

  // Helper method to get the current wage based on the latest effective date
  double get currentWage {
    if (wageHistory.isEmpty) {
      return 0.0;
    }
    // The list is sorted by date, so the first item is the most recent.
    return wageHistory.first.perDayWage;
  }

  // Finds the correct wage for a specific date
  double getWageForDate(DateTime date) {
    if (wageHistory.isEmpty) return 0.0;
    // Find the first wage record where the effective date is on or before the given date.
    // Since the list is sorted from newest to oldest, this will be the correct one.
    final applicableWage = wageHistory.firstWhere(
          (wh) => !wh.effectiveDate.isAfter(date),
      orElse: () => wageHistory.last, // Fallback to the oldest wage if no other matches
    );
    return applicableWage.perDayWage;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fatherName': fatherName,
      'trade': trade,
      'contactNumber': contactNumber,
      'address': address,
    };
  }

  factory Laborer.fromMap(Map<String, dynamic> map) {
    return Laborer(
      id: map['id'],
      name: map['name'],
      fatherName: map['fatherName'] ?? '',
      trade: map['trade'],
      contactNumber: map['contactNumber'],
      address: map['address'] ?? '',
      wageHistory: [], // Loaded separately
      wagePayments: [], // Loaded separately
    );
  }
}
