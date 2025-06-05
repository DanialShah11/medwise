import 'package:flutter/material.dart';
import 'view_medicines_screen.dart';
import 'add_medicine_screen.dart';
import 'package:Medwise/modules/expiry_alerts/screens/debug_expiry_screen.dart';
import 'package:Medwise/modules/medicine_tracking/screens/stock_alerts_screen.dart';
import 'package:Medwise/modules/medicine_tracking/screens/medicine_summary_screen.dart';
import 'package:Medwise/modules/medicine_tracking/screens/batch_tracker_screen.dart';
import 'package:Medwise/modules/medicine_tracking/screens/usage_log_screen.dart';

class MedicineHomeScreen extends StatelessWidget {
  const MedicineHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Tracking'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildCard(
              context,
              title: 'Add to Stock',
              icon: Icons.add_box,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddMedicineScreen()),
                );
              },
            ),
            _buildCard(
              context,
              title: 'View All Stock',
              icon: Icons.list_alt,
              color: Colors.blue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewMedicinesScreen()),
                );
              },
            ),
            _buildCard(
              context,
              title: 'Stock Alerts',
              icon: Icons.warning_amber_rounded,
              color: Colors.deepOrange, // ✅ Different color from the others
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StockAlertsScreen()),
                );
              },
            ),

            _buildCard(
              context,
              title: 'Items Summary',
              icon: Icons.pie_chart_outline,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MedicineSummaryScreen()),
                );
              },
            ),

            _buildCard(
              context,
              title: 'Batch Tracker',
              icon: Icons.qr_code_2,
              color: Colors.cyan,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BatchTrackerScreen()),
                );
              },
            ),

            _buildCard(
              context,
              title: 'Usage Log',
              icon: Icons.history,
              color: Colors.yellow.shade800,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsageLogScreen()),
                );
              },
            ),

            // ElevatedButton(
            //   child: Text("🧪 Test Expiry Logic"),
            //   onPressed: () {
            //     Navigator.push(context, MaterialPageRoute(
            //       builder: (context) => DebugExpiryScreen(),
            //     ));
            //   },
            // ),

            // Uncomment this when the analytics dashboard screen is added
            /*
            _buildCard(
              context,
              title: 'Analytics',
              icon: Icons.pie_chart,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MedicineDashboardScreen()),
                );
              },
            ),
            */
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context,
      {required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        color: color,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
