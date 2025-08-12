// FILE: lib/models/measurement.dart
// This file defines the data structure for a single measurement entry.

class Measurement {
  final String id;
  final String raBillId; // Changed from projectId
  final String description;
  final double length;
  final double width; // Can be used for Width or Height
  final double quantity;
  final String unit;
  final double rate;

  Measurement({
    required this.id,
    required this.raBillId,
    required this.description,
    required this.length,
    required this.width,
    required this.quantity,
    required this.unit,
    required this.rate,
  });

  double get totalArea {
    if (unit == 'Nos.') {
      return quantity;
    }
    return length * width * quantity;
  }

  double get totalAmount {
    return totalArea * rate;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'raBillId': raBillId,
      'description': description,
      'length': length,
      'width': width,
      'quantity': quantity,
      'unit': unit,
      'rate': rate,
    };
  }

  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'],
      raBillId: map['raBillId'],
      description: map['description'],
      length: map['length'],
      width: map['width'],
      quantity: map['quantity'],
      unit: map['unit'],
      rate: map['rate'] ?? 0.0,
    );
  }
}
