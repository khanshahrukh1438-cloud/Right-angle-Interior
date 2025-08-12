// FILE: lib/models/attendance_record.dart
class AttendanceRecord {
  final String id;
  final String projectLaborerId;
  final DateTime date;
  final double daysWorked;

  AttendanceRecord({
    required this.id,
    required this.projectLaborerId,
    required this.date,
    required this.daysWorked,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'projectLaborerId': projectLaborerId,
      'date': date.toIso8601String(),
      'daysWorked': daysWorked,
    };
  }

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'],
      projectLaborerId: map['projectLaborerId'],
      date: DateTime.parse(map['date']),
      daysWorked: map['daysWorked'],
    );
  }
}
