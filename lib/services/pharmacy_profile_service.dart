import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PharmacyProfileService {
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance.collection("User").doc(user.uid).get();
    return doc.data();
  }

  static Future<void> savePharmacyInfo({
    required String pharmacyName,
    required String address,
    required String contact,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance.collection("User").doc(user.uid);
    await docRef.set({
      'pharmacyName': pharmacyName,
      'address': address,
      'contact': contact,
    }, SetOptions(merge: true));
  }
}
