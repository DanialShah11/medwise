import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:Medwise/services/local_notification_service.dart';
import 'package:intl/intl.dart';

class ExpiryController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> getAllMedicines() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('medicines')
        .get();

    final meds = snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;

      final expiry = _getExpiryDate(data);
      data['expiryDateFormatted'] =
      expiry != null ? DateFormat('dd MMM yyyy').format(expiry) : 'Unknown';

      return data;
    }).toList();

    return meds;
  }

  DateTime? _getExpiryDate(Map<String, dynamic> med) {
    final raw = med['expiryDate'];
    if (raw == null) return null;

    try {
      if (raw is Timestamp) return raw.toDate();
      if (raw is String) return DateTime.parse(raw);
    } catch (e) {
      print("❌ Failed to parse expiryDate: $raw");
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getExpiredMedicines() async {
    final allMeds = await getAllMedicines();
    final now = DateTime.now();
    return allMeds.where((med) {
      final expiry = _getExpiryDate(med);
      return expiry != null && expiry.isBefore(now);
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getExpiringInDays(int days) async {
    final allMeds = await getAllMedicines();
    final now = DateTime.now();
    final target = now.add(Duration(days: days));
    return allMeds.where((med) {
      final expiry = _getExpiryDate(med);
      return expiry != null && expiry.isAfter(now) && expiry.isBefore(target);
    }).toList();
  }

  void checkAndNotifyExpiringMedicines(List<Map<String, dynamic>> medicines) {
    final now = DateTime.now();
    for (var med in medicines) {
      final expiryDate = _getExpiryDate(med);
      if (expiryDate == null) continue;

      final daysLeft = expiryDate.difference(now).inDays;
      if (daysLeft <= 7 && daysLeft >= 0) {
        LocalNotificationService.showNotification(
          title: 'Medicine Expiry Alert',
          body: '${med['name']} is expiring in $daysLeft day${daysLeft == 1 ? '' : 's'}!',
        );
      }
    }
  }

  Future<void> scheduleAllNotifications() async {
    final allMeds = await getAllMedicines();
    final notificationService = LocalNotificationService();
    await notificationService.cancelAll();
    await notificationService.scheduleExpiryNotifications(allMeds);
  }
}
