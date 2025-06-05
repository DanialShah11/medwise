import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Medwise/utils/constants.dart';
import 'package:Medwise/modules/report_generation/services/report_generator_service.dart';
import 'package:Medwise/modules/barcode_scanning/screens/simple_scan_screen.dart';

import 'dart:convert';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:Medwise/modules/report_generation/models/export_metadata.dart';

class ExportReportScreen extends StatefulWidget {
  final String? presetFormat;
  const ExportReportScreen({super.key, this.presetFormat});

  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  String selectedReportType = 'Inventory Report';
  final List<String> reportTypes = ['Inventory Report', 'Expiry Report'];
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController batchNumberController = TextEditingController();

  String selectedCategory = 'All';
  String stockStatus = 'All';
  String expiryFilter = 'All';
  String exportFormat = 'CSV';
  DateTime? fromDate;
  DateTime? toDate;

  final List<String> categories = ['All', 'Tablet', 'Syrup', 'Capsule', 'Injection', 'Other'];
  final List<String> stockOptions = ['All', 'Low Stock (≤10)', 'Out of Stock'];
  final List<String> expiryOptions = ['All', 'Expired', '≤ 7 Days', '≤ 15 Days', '≤ 30 Days'];
  final List<String> exportFormats = ['CSV', 'PDF'];

  Future<void> _pickDateRange({required bool isFrom}) async {
    DateTime initial = DateTime.now();
    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2100);

    if (isFrom && toDate != null) {
      lastDate = toDate!;
    } else if (!isFrom && fromDate != null) {
      firstDate = fromDate!;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? fromDate ?? initial : toDate ?? initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  void _applyQuickRange(String label) {
    final now = DateTime.now();
    DateTime from;

    switch (label) {
      case '7 Days':
        from = now.subtract(const Duration(days: 7));
        break;
      case '15 Days':
        from = now.subtract(const Duration(days: 15));
        break;
      case '30 Days':
        from = now.subtract(const Duration(days: 30));
        break;
      case 'This Month':
        from = DateTime(now.year, now.month, 1);
        break;
      default:
        from = now;
    }

    setState(() {
      fromDate = from;
      toDate = now;
    });
  }

  void _submit() async {
    final filters = {
      "reportType": selectedReportType,
      "category": selectedCategory,
      "stock": stockStatus,
      "expiry": expiryFilter,
      "fromDate": fromDate?.toIso8601String(),
      "toDate": toDate?.toIso8601String(),
      "format": exportFormat,
      "barcode": barcodeController.text.trim().isNotEmpty ? barcodeController.text.trim() : null,
      "batch": batchNumberController.text.trim().isNotEmpty ? batchNumberController.text.trim() : null,
    };

    final reportService = ReportGeneratorService();
    String? path;

    if (exportFormat == "CSV") {
      path = await reportService.generateCSV(filters);
    } else {
      path = await reportService.generatePDF(filters);
    }

    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Report generated: ${path.split('/').last}")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to generate report.")),
      );
    }
  }

  Widget _buildQuickTimeButtons() {
    final List<String> labels = ['7 Days', '15 Days', '30 Days', 'This Month'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: labels.map((label) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton(
              onPressed: () => _applyQuickRange(label),
              child: Text(label),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.black,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF273671),
        title: const Text(
          "📑 Export With Filters",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Select Report Type"),
          DropdownButtonFormField<String>(
            value: selectedReportType,
            items: reportTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
            onChanged: (val) => setState(() => selectedReportType = val!),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),

          const Text("Filter by Category"),
          DropdownButtonFormField<String>(
            value: selectedCategory,
            items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
            onChanged: (val) => setState(() => selectedCategory = val!),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),

          const Text("Filter by Stock Status"),
          DropdownButtonFormField<String>(
            value: stockStatus,
            items: stockOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) => setState(() => stockStatus = val!),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),

          const Text("Filter by Expiry"),
          DropdownButtonFormField<String>(
            value: expiryFilter,
            items: expiryOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) => setState(() => expiryFilter = val!),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),

          const Text("Filter by Date Added"),
          const SizedBox(height: 16),
          const Text("Filter by Barcode"),
          TextFormField(
            controller: barcodeController,
            readOnly: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SimpleScanScreen(
                    onDetect: (code) {
                      Navigator.pop(context); // Close scanner
                      setState(() {
                        barcodeController.text = code;
                      });
                    },
                  ),
                ),
              );
            },
            decoration: InputDecoration(
              labelText: 'Tap to Scan Barcode',
              border: const OutlineInputBorder(),
              suffixIcon: const Icon(Icons.qr_code_scanner),
            ),
          ),

          const SizedBox(height: 16),
          const Text("Filter by Batch Number (Optional)"),
          TextFormField(
            controller: batchNumberController,
            decoration: const InputDecoration(
              labelText: 'Batch No.',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 8),
          _buildQuickTimeButtons(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _pickDateRange(isFrom: true),
                  child: Text(fromDate == null ? "From" : DateFormat.yMMMd().format(fromDate!)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _pickDateRange(isFrom: false),
                  child: Text(toDate == null ? "To" : DateFormat.yMMMd().format(toDate!)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Text("Select Export Format"),
          DropdownButtonFormField<String>(
            value: exportFormat,
            items: exportFormats.map((f) => DropdownMenuItem(value: f, child: Text(f))).toList(),
            onChanged: (val) => setState(() => exportFormat = val!),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),

          const SizedBox(height: 30),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: const Text(
              "Generate Report",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF273671),
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          )

        ],
      ),
    );
  }
}
