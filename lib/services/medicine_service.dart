// 📄 File: lib/services/medicine_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../modules/medicine_tracking/models/medicine_model.dart';
import '../modules/medicine_tracking/controller/medicine_controller.dart';

class MedicineService {
  final MedicineController _controller = MedicineController();

  Future<void> addMedicine(Medicine medicine) async {
    await _controller.addMedicine(medicine);
  }

  Future<void> updateMedicine(Medicine medicine) async {
    await _controller.updateMedicine(medicine);
  }

  Future<void> deleteMedicine(String id) async {
    await _controller.deleteMedicine(id);
  }

  Future<List<Medicine>> getAllMedicines() async {
    return await _controller.fetchMedicines();
  }

  Stream<List<Medicine>> getMedicineStream() {
    return _controller.streamMedicines();
  }

  Future<List<Medicine>> getMedicinesForCSV() async {
    return await _controller.fetchMedicinesForExport();
  }

  Future<Medicine?> searchMedicineByBarcode(String barcode) async {
    return await _controller.searchMedicineByBarcode(barcode);
  }

  Future<Medicine?> getMedicineById(String docId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medicines')
        .doc(docId)
        .get();

    if (!docSnapshot.exists) return null;
    return Medicine.fromDocument(docSnapshot);
  }

  Future<bool> updateMedicineQuantity(String docId, int newQuantity) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medicines')
          .doc(docId)
          .update({'quantity': newQuantity});
      return true;
    } catch (e) {
      print('Error updating quantity: $e');
      return false;
    }
  }
}
