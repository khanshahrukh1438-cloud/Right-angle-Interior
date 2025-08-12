// FILE: lib/models/project.dart
import 'package:right_angle_interior/models/expense.dart';
import 'package:right_angle_interior/models/project_laborer.dart';

class Project {
  final String id;
  final String name;
  final String clientName;
  // Address fields are now more detailed
  final String addressLine1;
  final String? addressLine2;
  final String pincode;
  final String city;
  final String state;
  final DateTime startDate;
  final DateTime? endDate;
  final double budget;
  final String status;
  List<Expense> expenses;
  List<ProjectLaborer> assignedLaborers;

  Project({
    required this.id,
    required this.name,
    required this.clientName,
    required this.addressLine1,
    this.addressLine2,
    required this.pincode,
    required this.city,
    required this.state,
    required this.startDate,
    this.endDate,
    required this.budget,
    required this.status,
    required this.expenses,
    required this.assignedLaborers,
  });

  // Convert a Project object into a Map object for the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'clientName': clientName,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'pincode': pincode,
      'city': city,
      'state': state,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'budget': budget,
      'status': status,
    };
  }

  // Create a Project object from a Map object from the database.
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'],
      clientName: map['clientName'],
      addressLine1: map['addressLine1'] ?? '',
      addressLine2: map['addressLine2'],
      pincode: map['pincode'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      startDate: DateTime.parse(map['startDate']),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      budget: map['budget'],
      status: map['status'],
      // These lists will be loaded separately in a later step.
      expenses: [],
      assignedLaborers: [],
    );
  }
}
