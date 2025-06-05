import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UsageLogService {
  static Future<void> logMedicineUsage({
    required String medicineId,
    required String medicineName,
    required int quantityUsed,
    required String reason,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final usageRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('usage_logs');

    await usageRef.add({
      'medicineId': medicineId,
      'medicineName': medicineName,
      'quantityUsed': quantityUsed,
      'reason': reason,
      'date': DateTime.now().toIso8601String(),
      'userEmail': user.email,
    });
  }
}
