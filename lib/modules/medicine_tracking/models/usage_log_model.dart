class UsageLog {
  final String id;
  final String medicineName;
  final String medicineId;
  final int quantityUsed;
  final String reason; // e.g. Sold, Expired, Discarded
  final DateTime date;
  final String? userEmail;

  UsageLog({
    required this.id,
    required this.medicineName,
    required this.medicineId,
    required this.quantityUsed,
    required this.reason,
    required this.date,
    this.userEmail,
  });

  Map<String, dynamic> toMap() {
    return {
      'medicineName': medicineName,
      'medicineId': medicineId,
      'quantityUsed': quantityUsed,
      'reason': reason,
      'date': date.toIso8601String(),
      'userEmail': userEmail,
    };
  }

  factory UsageLog.fromMap(Map<String, dynamic> map, String id) {
    return UsageLog(
      id: id,
      medicineName: map['medicineName'],
      medicineId: map['medicineId'],
      quantityUsed: map['quantityUsed'],
      reason: map['reason'],
      date: DateTime.parse(map['date']),
      userEmail: map['userEmail'],
    );
  }
}
