import 'package:flutter/material.dart';
import 'package:Medwise/modules/medicine_tracking/controller/medicine_controller.dart';
import 'package:Medwise/modules/medicine_tracking/models/medicine_model.dart';

class MedicineSummaryScreen extends StatefulWidget {
  const MedicineSummaryScreen({super.key});

  @override
  State<MedicineSummaryScreen> createState() => _MedicineSummaryScreenState();
}

class _MedicineSummaryScreenState extends State<MedicineSummaryScreen> {
  final controller = MedicineController();
  int total = 0;
  int lowStock = 0;
  int outOfStock = 0;
  int expiringSoon = 0;

  @override
  void initState() {
    super.initState();
    _calculateStats();
  }

  Future<void> _calculateStats() async {
    final meds = await controller.fetchMedicines();
    final now = DateTime.now();

    setState(() {
      total = meds.length;
      lowStock = meds.where((m) => m.quantity > 0 && m.quantity <= 10).length;
      outOfStock = meds.where((m) => m.quantity == 0).length;
      expiringSoon = meds.where((m) => m.expiryDate.isBefore(now.add(const Duration(days: 30)))).length;
    });
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.white),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
                Text(
                  value.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inventory Summary")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard("Total Medicines", total, Icons.medical_services, Colors.blue),
            const SizedBox(height: 12),
            _buildStatCard("Low Stock (≤ 10)", lowStock, Icons.warning_amber, Colors.orange),
            const SizedBox(height: 12),
            _buildStatCard("Out of Stock", outOfStock, Icons.close, Colors.red),
            const SizedBox(height: 12),
            _buildStatCard("Expiring in 30 Days", expiringSoon, Icons.hourglass_bottom, Colors.deepPurple),
          ],
        ),
      ),
    );
  }
}
