import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login.dart';
import 'package:Medwise/modules/medicine_tracking/models/medicine_model.dart';
import 'package:Medwise/modules/medicine_tracking/screens/medicine_home_screen.dart';
import 'package:Medwise/modules/report_generation/screens/report_home_screen.dart';
import 'package:Medwise/modules/barcode_scanning/screens/barcode_home_screen.dart';
import 'package:Medwise/modules/expiry_alerts/screens/expiry_alerts_screen.dart';
import 'package:Medwise/modules/auth_module/widgets/fancy_home_button.dart';
import 'package:Medwise/modules/auth_module/widgets/pharmacy_info_prompt.dart'; // ✅ added
import 'package:flutter_animate/flutter_animate.dart'; // Add this to pubspec.yaml

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();

}
Widget _drawerItem({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
  Color color = Colors.black,
}) {
  return ListTile(
    leading: Icon(icon, color: color),
    title: Text(label, style: TextStyle(color: color)),
    onTap: onTap,
  );
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();
    _checkPharmacyInfo();
  }

  Future<void> _checkPharmacyInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    while (true) {
      final doc = await FirebaseFirestore.instance.collection("User").doc(user.uid).get();
      final data = doc.data();
      print("Firestore data: ${doc.data()}");
      final isInfoMissing = data == null ||
          (data['pharmacyName'] == null || (data['pharmacyName'] as String).trim().isEmpty) ||
          (data['address'] == null || (data['address'] as String).trim().isEmpty) ||
          (data['contact'] == null || (data['contact'] as String).trim().isEmpty);

      if (!isInfoMissing) break; // All info present → exit loop

      final result = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const PharmacyInfoPrompt(),
      );

      if (result != true) {
        // User did not provide info → show warning and retry
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pharmacy info is required to continue.")),
        );
      }
    }
  }


  Future<List<Medicine>> fetchAllMedicines() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('medicines')
          .get();

      return snapshot.docs.map((doc) {
        try {
          return Medicine.fromMap(doc.data(), doc.id);
        } catch (e) {
          print("Error parsing medicine doc ${doc.id}: $e");
          return null;
        }
      }).whereType<Medicine>().toList();
    } catch (e) {
      print("Error loading medicines from Firestore: $e");
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            // Drawer Header with Close Icon
            Container(
              padding: const EdgeInsets.only(top: 40, left: 16, right: 8, bottom: 20),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF273671),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Stack(
                children: [
                  // ❌ Close Button at Top Right
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),

                  // Logo + Title + Tagline
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'images/ren.png', // 🔁 Use your small logo path here
                            height: 60,
                            width: 60,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Medwise',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Smarter Pharmacy. Simpler Workflow.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),

            ),

            const SizedBox(height: 10),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    onTap: () => Navigator.pop(context),
                  ),
                  _drawerItem(
                    icon: Icons.inventory_2,
                    label: 'Medicines',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MedicineHomeScreen()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.insert_chart,
                    label: 'Reports',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ReportHomeScreen()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.qr_code_scanner,
                    label: 'Barcode Scanner',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BarcodeHomeScreen()),
                      );
                    },
                  ),
                  _drawerItem(
                    icon: Icons.notifications_active,
                    label: 'Expiry Alerts',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ExpiryAlertsScreen()),
                      );
                    },
                  ),
                  const Divider(),
                  _drawerItem(
                    icon: Icons.logout,
                    label: 'Logout',
                    color: Colors.redAccent,
                    onTap: () async {
                      Navigator.of(context).pop();
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LogIn()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),


      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (user != null)
              Animate(
                effects: [
                  FadeEffect(duration: 400.ms),
                  SlideEffect(begin: Offset(0, -0.2), duration: 400.ms),
                  ScaleEffect(begin: Offset(0.95, 0.95), duration: 400.ms),

                ],
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFfdfbfb), Color(0xFFebedee)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFd1d1d1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Signed in as",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email ?? '',
                              style: const TextStyle(
                                color: Color(0xFF273671),
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.verified_user, color: Color(0xFF273671), size: 28),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: FutureBuilder<List<Medicine>>(
                future: fetchAllMedicines(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text("Failed to load medicines"));
                  } else {
                    final medicinesList = snapshot.data ?? [];
                    return ListView(
                      children: [
                        FancyHomeButton(
                          label: 'Medicine Tracker',
                          icon: Icons.medical_services,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MedicineHomeScreen(),
                              ),
                            );
                          },
                        ),
                        FancyHomeButton(
                          label: 'Report Generator',
                          icon: Icons.insert_chart,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ReportHomeScreen(),
                              ),
                            );
                          },
                        ),
                        FancyHomeButton(
                          label: 'Barcode Scanner',
                          icon: Icons.qr_code_scanner,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BarcodeHomeScreen(),
                              ),
                            );
                          },
                        ),
                        FancyHomeButton(
                          label: 'Expiry Alerts',
                          icon: Icons.notifications_active,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ExpiryAlertsScreen(),
                              ),
                            );
                          },
                        ),
                        FancyHomeButton(
                          label: 'Logout',
                          icon: Icons.logout,
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const LogIn()),
                            );
                          },
                          color: Colors.redAccent,
                        ),
                      ],
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
