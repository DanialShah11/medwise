import 'package:cloud_firestore/cloud_firestore.dart';

class Medicine {
  final String id;
  final String name;
  final String? barcode;
  final int quantity; // existing
  final DateTime expiryDate;
  final String category;
  final String? notes;
  final DateTime timestamp;

  // ✅ New Fields
  final int? cartonsQuantity;         // Total no. of cartons
  final int? unitsPerCarton;          // How many units in one carton
  final double? unitPrice;            // Selling price per unit
  final double? cartonPrice;          // Price per carton
  final String? strength;             // e.g. 20mg or 5ml
  final double? wholesalePrice;       // Optional wholesale price per unit
  final String? batchNumber;          // Optional batch number
  final String? formula;              // Optional formula

  Medicine({
    required this.id,
    required this.name,
    required this.quantity,
    required this.expiryDate,
    required this.category,
    required this.timestamp,
    this.notes,
    this.barcode,
    this.cartonsQuantity,
    this.unitsPerCarton,
    this.unitPrice,
    this.cartonPrice,
    this.strength,
    this.wholesalePrice,
    this.batchNumber,
    this.formula,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'quantity': quantity,
      'expiryDate': expiryDate.toIso8601String(),
      'category': category,
      'notes': notes,
      'timestamp': timestamp.toIso8601String(),
      // New Fields
      'cartonsQuantity': cartonsQuantity,
      'unitsPerCarton': unitsPerCarton,
      'unitPrice': unitPrice,
      'cartonPrice': cartonPrice,
      'strength': strength,
      'wholesalePrice': wholesalePrice,
      'batchNumber': batchNumber,
      'formula': formula,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map, [String? id]) {
    return Medicine(
      id: id ?? map['id'],
      name: map['name'],
      barcode: map['barcode'],
      quantity: map['quantity'],
      expiryDate: DateTime.parse(map['expiryDate']),
      category: map['category'],
      notes: map['notes'],
      timestamp: DateTime.parse(map['timestamp']),
      cartonsQuantity: map['cartonsQuantity'],
      unitsPerCarton: map['unitsPerCarton'],
      unitPrice: (map['unitPrice'] as num?)?.toDouble(),
      cartonPrice: (map['cartonPrice'] as num?)?.toDouble(),
      strength: map['strength'],
      wholesalePrice: (map['wholesalePrice'] as num?)?.toDouble(),
      batchNumber: map['batchNumber'],
      formula: map['formula'],
    );
  }

  factory Medicine.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Medicine.fromMap(data, doc.id); // ✅ correct
  }
  Medicine copyWith({
    String? id,
    String? name,
    String? barcode,
    int? quantity,
    DateTime? expiryDate,
    String? category,
    String? notes,
    DateTime? timestamp,
    int? cartonsQuantity,
    int? unitsPerCarton,
    double? unitPrice,
    double? cartonPrice,
    String? strength,
    double? wholesalePrice,
    String? batchNumber,
    String? formula,
  }) {
    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      barcode: barcode ?? this.barcode,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      timestamp: timestamp ?? this.timestamp,
      cartonsQuantity: cartonsQuantity ?? this.cartonsQuantity,
      unitsPerCarton: unitsPerCarton ?? this.unitsPerCarton,
      unitPrice: unitPrice ?? this.unitPrice,
      cartonPrice: cartonPrice ?? this.cartonPrice,
      strength: strength ?? this.strength,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      batchNumber: batchNumber ?? this.batchNumber,
      formula: formula ?? this.formula,
    );
  }

}
