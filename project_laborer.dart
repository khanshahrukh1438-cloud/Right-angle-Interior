// FILE: lib/models/project_laborer.dart
import 'package:right_angle_interior/models/attendance_record.dart';
import 'package:right_angle_interior/models/laborer.dart';

class ProjectLaborer {
  final String id;
  final String projectId;
  final Laborer laborer;
  List<AttendanceRecord> attendance;
  bool isActive;

  ProjectLaborer({
    required this.id,
    required this.projectId,
    required this.laborer,
    required this.attendance,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectId': projectId,
      'laborerId': laborer.id,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory ProjectLaborer.fromMap(Map<String, dynamic> map, Laborer laborer) {
    return ProjectLaborer(
      id: map['id'],
      projectId: map['projectId'],
      laborer: laborer,
      attendance: [], // Loaded separately
      // FIX: This now correctly handles old data by defaulting to true if the value is null.
      isActive: map['isActive'] == null ? true : map['isActive'] == 1,
    );
  }
}