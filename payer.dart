// FILE: lib/models/payer.dart
// This file defines the data structure for a single Payer (for the ledger).

class Payer {
  final String id;
  final String name;
  final double openingBalance; // New field for the opening balance
  final bool isCompanyAccount;

  Payer({
    required this.id,
    required this.name,
    this.openingBalance = 0.0, // Default to 0
    this.isCompanyAccount = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'openingBalance': openingBalance,
      'isCompanyAccount': isCompanyAccount ? 1 : 0,
    };
  }

  factory Payer.fromMap(Map<String, dynamic> map) {
    return Payer(
      id: map['id'],
      name: map['name'],
      openingBalance: map['openingBalance'] ?? 0.0,
      isCompanyAccount: map['isCompanyAccount'] == 1,
    );
  }
}
