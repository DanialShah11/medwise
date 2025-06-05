import 'package:flutter/material.dart';
import 'package:Medwise/modules/medicine_tracking/controller/medicine_controller.dart';
import 'package:Medwise/utils/constants.dart';
import 'package:Medwise/modules/report_generation/screens/export_report_screen.dart';
import 'package:Medwise/modules/report_generation/services/report_generator_service.dart';
import 'package:Medwise/modules/report_generation/screens/export_history_screen.dart';

class ReportHomeScreen extends StatefulWidget {
  const ReportHomeScreen({super.key});

  @override
  State<ReportHomeScreen> createState() => _ReportHomeScreenState();
}

class _ReportHomeScreenState extends State<ReportHomeScreen> {
  int totalMedicines = 0;
  int lowStock = 0;
  int nearExpiry = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final controller = MedicineController();
    final all = await controller.getTotalMedicinesCount();
    final low = (await controller.fetchMedicines()).where((m) => m.quantity <= 10).length;
    final exp = await controller.getNearExpiryCount();

    setState(() {
      totalMedicines = all;
      lowStock = low;
      nearExpiry = exp;
    });
  }

  Widget _buildStatCard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text("$value", style: TextStyle(fontSize: 18, color: color)),
      ),
    );
  }

  Widget _buildMainButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF273671),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }


  Widget _buildQuickExportButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.file_download,  color: Colors.white),
      label: const Text("Quick Export", style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF273671),
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Text("Quick Export Options", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.file_download),
                title: const Text("Export Full CSV"),
                onTap: () async {
                  Navigator.pop(ctx);
                  final success = await ReportGeneratorService().generateCSV({
                    "reportType": "Inventory Report",
                    "format": "CSV",
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success != null ? "CSV exported!" : "Export failed."),
                  ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text("Export Full PDF"),
                onTap: () async {
                  Navigator.pop(ctx);
                  final success = await ReportGeneratorService().generatePDF({
                    "reportType": "Inventory Report",
                    "format": "PDF",
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(success != null ? "PDF exported!" : "Export failed."),
                  ));
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF273671),
        title: const Text(
          "Report Generator",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              " Summary",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildStatCard("Total Medicines", totalMedicines, Icons.inventory, Colors.blue),
            _buildStatCard("Low Stock (≤10)", lowStock, Icons.warning, Colors.orange),
            _buildStatCard("Near Expiry (≤30 days)", nearExpiry, Icons.schedule, Colors.red),

            const SizedBox(height: 24),
            const Text(
              " Export Options",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Quick Export Button (Bottom Sheet)
            _buildQuickExportButton(),

            const SizedBox(height: 12),

            // Go to Full Export With Filters
            _buildMainButton("Export with Filters", Icons.tune, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExportReportScreen(),
                ),
              );
            }),
            const SizedBox(height: 12),

            _buildMainButton("Export History", Icons.history, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ExportHistoryScreen(),
                ),
              );
            }),

          ],
        ),
      ),
    );
  }
}
