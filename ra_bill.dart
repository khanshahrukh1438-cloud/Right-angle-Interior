// FILE: lib/models/ra_bill.dart
// This file defines the data structure for a single RA Bill.

import 'package:right_angle_interior/models/measurement.dart';

class RABill {
  final String id;
  final String projectId;
  final String billName; // e.g., "RA Bill 1", "Final Bill"
  final DateTime date;
  List<Measurement> measurements;

  RABill({
    required this.id,
    required this.projectId,
    required this.billName,
    required this.date,
    required this.measurements,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'billName': billName,
      'date': date.toIso8601String(),
    };
  }

  factory RABill.fromMap(Map<String, dynamic> map) {
    return RABill(
      id: map['id'],
      projectId: map['projectId'],
      billName: map['billName'],
      date: DateTime.parse(map['date']),
      measurements: [], // Loaded separately
    );
  }
}
