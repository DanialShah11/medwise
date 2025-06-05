import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medicine_model.dart';
import '../../../services/local_notification_service.dart';

class MedicineController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _medicineCollection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception("User not logged in");
    }
    return _firestore.collection('users').doc(uid).collection('medicines');
  }

  Future<void> addMedicine(Medicine medicine) async {
    await _medicineCollection.doc(medicine.id).set(medicine.toMap());
    _checkExpiryAndNotify(medicine);
  }

  Future<void> updateMedicine(Medicine medicine) async {
    await _medicineCollection.doc(medicine.id).update(medicine.toMap());
    _checkExpiryAndNotify(medicine);
  }

  Future<void> deleteMedicine(String id) async {
    await _medicineCollection.doc(id).delete();
  }

  Future<List<Medicine>> fetchMedicines() async {
    final snapshot = await _medicineCollection.orderBy('expiryDate').get();
    return snapshot.docs.map((doc) => Medicine.fromDocument(doc)).toList();
  }

  Stream<List<Medicine>> streamMedicines() {
    return _medicineCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Medicine.fromDocument(doc)).toList());
  }

  Future<List<Medicine>> fetchMedicinesForExport() async {
    final snapshot =
    await _medicineCollection.orderBy('timestamp', descending: true).get();
    return snapshot.docs.map((doc) => Medicine.fromDocument(doc)).toList();
  }

  Future<int> getTotalMedicinesCount() async {
    final snapshot = await _medicineCollection.get();
    return snapshot.size;
  }

  Future<int> getNearExpiryCount() async {
    final now = DateTime.now();
    final cutoff = now.add(const Duration(days: 30));
    final snapshot = await _medicineCollection
        .where('expiryDate', isGreaterThanOrEqualTo: now.toIso8601String())
        .where('expiryDate', isLessThanOrEqualTo: cutoff.toIso8601String())
        .get();
    return snapshot.size;
  }

  Future<Map<String, int>> getMedicinesCountByCategory() async {
    final snapshot = await _medicineCollection.get();
    final Map<String, int> categoryCounts = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final category = data['category'] ?? 'Uncategorized';
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }
    return categoryCounts;
  }

  void _checkExpiryAndNotify(Medicine medicine) {
    final now = DateTime.now();
    final difference = medicine.expiryDate.difference(now).inDays;

    if (difference <= 3 && difference >= 0) {
      LocalNotificationService.showNotification(
        title: "Expiry Alert: ${medicine.name}",
        body: "This medicine will expire in $difference day(s).",
      );
    } else if (difference < 0) {
      // Already expired
      LocalNotificationService.showNotification(
        title: "Expired: ${medicine.name}",
        body: "This medicine expired ${difference.abs()} day(s) ago!",
      );
    }
  }
  Future<Medicine?> searchMedicineByBarcode(String barcode) async {
    final querySnapshot = await _medicineCollection
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return Medicine.fromDocument(querySnapshot.docs.first);
    }
    return null;
  }



}
