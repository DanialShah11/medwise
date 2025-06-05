import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:Medwise/modules/medicine_tracking/controller/medicine_controller.dart';
import 'package:Medwise/modules/medicine_tracking/models/medicine_model.dart';
import 'package:Medwise/modules/report_generation/models/export_metadata.dart';

class ReportGeneratorService {
  final _controller = MedicineController();

  Future<String?> generatePDF(Map<String, dynamic> filters) async {
    final reportType = filters["reportType"];
    File? file;

    if (reportType == 'Inventory Report') {
      file = await _generateInventoryPDF(filters);
    } else if (reportType == 'Expiry Report') {
      file = await _generateExpiryPDF(filters);
    } else {
      return null;
    }

    if (file != null) {
      await _saveExportHistory(file.path, filters);
      await _syncExportToFirebase(file.path, "PDF", filters);
      await OpenFile.open(file.path);
      return file.path;
    }

    return null;
  }

  Future<String?> generateCSV(Map<String, dynamic> filters) async {
    final filtered = await _applyFilters(filters);
    final csvData = <List<dynamic>>[
      [
        "Name", "Barcode", "Quantity", "Cartons", "Units/Carton", "Unit Price",
        "Carton Price", "Wholesale Price", "Strength", "Batch No.", "Formula",
        "Expiry Date", "Category", "Notes", "Added On"
      ]
    ];

    for (var m in filtered) {
      csvData.add([
        m.name,
        m.barcode ?? '',
        m.quantity,
        m.cartonsQuantity ?? '',
        m.unitsPerCarton ?? '',
        m.unitPrice ?? '',
        m.cartonPrice ?? '',
        m.wholesalePrice ?? '',
        m.strength ?? '',
        m.batchNumber ?? '',
        m.formula ?? '',
        m.expiryDate.toIso8601String(),
        m.category,
        m.notes ?? '',
        m.timestamp.toIso8601String(),
      ]);
    }

    final csv = const ListToCsvConverter().convert(csvData);
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/report_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File(path);
    await file.writeAsString(csv);

    await _saveExportHistory(file.path, filters);
    await _syncExportToFirebase(file.path, "CSV", filters);
    await OpenFile.open(file.path);
    return path;
  }

  Future<void> _saveExportHistory(String filePath, Map<String, dynamic> filters) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('export_history') ?? [];

    final entry = ExportMetadata(
      fileName: filePath,
      format: filters["format"] ?? "Unknown",
      timestamp: DateTime.now(),
      filters: filters,
    );

    history.insert(0, jsonEncode(entry.toJson()));
    await prefs.setStringList('export_history', history);
  }

  Future<void> _syncExportToFirebase(String path, String format, Map<String, dynamic> filters) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final metadata = ExportMetadata(
      fileName: path,
      format: format,
      timestamp: DateTime.now(),
      filters: filters,
    );

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("export_history")
        .add(metadata.toMap());
  }

  Future<List<Medicine>> _applyFilters(Map<String, dynamic> filters) async {
    List<Medicine> all = await _controller.fetchMedicines();

    if (filters['category'] != null && filters['category'] != 'All') {
      all = all.where((m) => m.category == filters['category']).toList();
    }

    if (filters['stock'] == 'Low Stock (≤10)') {
      all = all.where((m) => m.quantity <= 10 && m.quantity > 0).toList();
    } else if (filters['stock'] == 'Out of Stock') {
      all = all.where((m) => m.quantity == 0).toList();
    }

    final now = DateTime.now();
    if (filters['expiry'] == 'Expired') {
      all = all.where((m) => m.expiryDate.isBefore(now)).toList();
    } else if (filters['expiry'] == '≤ 7 Days') {
      all = all.where((m) => m.expiryDate.isAfter(now) && m.expiryDate.isBefore(now.add(const Duration(days: 7)))).toList();
    } else if (filters['expiry'] == '≤ 15 Days') {
      all = all.where((m) => m.expiryDate.isAfter(now) && m.expiryDate.isBefore(now.add(const Duration(days: 15)))).toList();
    } else if (filters['expiry'] == '≤ 30 Days') {
      all = all.where((m) => m.expiryDate.isAfter(now) && m.expiryDate.isBefore(now.add(const Duration(days: 30)))).toList();
    }

    final fromDate = filters['fromDate'] != null ? DateTime.tryParse(filters['fromDate']) : null;
    final toDate = filters['toDate'] != null ? DateTime.tryParse(filters['toDate']) : null;

    if (fromDate != null && toDate != null && fromDate.isAfter(toDate)) {
      return [];
    }

    if (fromDate != null) {
      all = all.where((m) => m.timestamp.isAfter(fromDate)).toList();
    }
    if (toDate != null) {
      all = all.where((m) => m.timestamp.isBefore(toDate)).toList();
    }

    if (filters['barcode'] != null) {
      all = all.where((m) => m.barcode == filters['barcode']).toList();
    }

    if (filters['batch'] != null) {
      all = all.where((m) => m.batchNumber == filters['batch']).toList();
    }

    return all;
  }

  Future<File?> _generateInventoryPDF(Map<String, dynamic> filters) async {
    final pdf = pw.Document();
    final filtered = await _applyFilters(filters);
    final now = DateTime.now();
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    String pharmacyName = "Unknown Pharmacy";
    String address = "Unknown Address";
    String contact = "Unknown Contact";

    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection("User").doc(uid).get();
      pharmacyName = userDoc.data()?['pharmacyName'] ?? pharmacyName;
      address = userDoc.data()?['address'] ?? address;
      contact = userDoc.data()?['contact'] ?? contact;
    }

    final expiringSoonCount = filtered.where((m) => m.expiryDate.isBefore(now.add(const Duration(days: 30)))).length;
    final lowStockCount = filtered.where((m) => m.quantity <= 10).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (_) => [
          // Header Section
          pw.Column(children: [
            pw.Text("Inventory Report",
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Divider(thickness: 1),

            // Pharmacy Info in Table Layout
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Pharmacy Name: $pharmacyName"),
                    pw.Text("Address: $address"),
                    pw.Text("Contact: $contact"),
                  ],
                ),
                pw.Text("Generated On: ${now.toString().split('.')[0]}",
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ]),

          pw.SizedBox(height: 20),

          // Table Section
          pw.Table.fromTextArray(
            headers: ["Name", "Category", "Strength", "Qty", "Expiry", "Unit Price", "Cartons", "Units/Carton"],
            data: filtered.map((m) => [
              m.name,
              m.category,
              m.strength ?? '',
              m.quantity,
              m.expiryDate.toIso8601String().split('T')[0],
              m.unitPrice?.toStringAsFixed(2) ?? '',
              m.cartonsQuantity ?? '',
              m.unitsPerCarton ?? '',
            ]).toList(),
          ),

          // Summary Section
          pw.SizedBox(height: 25),
          pw.Text("Summary", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Container(
            alignment: pw.Alignment.centerLeft,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Total Medicines Listed: ${filtered.length} items"),
                pw.Text("Expiring in next 30 days: $expiringSoonCount items"),
                pw.Text("Low Stock Count (less then 10): $lowStockCount items"),
                if (user != null) pw.Text("Generated by: ${user.email}"),
              ],
            ),
          ),

          pw.SizedBox(height: 40),
          pw.Divider(thickness: 0.5),
          // pw.Text("Signature / Approval:"),
          pw.SizedBox(height: 40),
          pw.Text("...................................................."),
          pw.Text("Pharmacist / Admin Signature"),
        ],
      ),
    );

    return _savePDF(pdf, 'inventory_report');
  }


  Future<File?> _generateExpiryPDF(Map<String, dynamic> filters) async {
    final pdf = pw.Document();
    final filtered = await _applyFilters(filters);
    final now = DateTime.now();
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    String pharmacyName = "Unknown Pharmacy";
    String address = "Unknown Address";
    String contact = "Unknown Contact";

    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance.collection("User").doc(uid).get();
      pharmacyName = userDoc.data()?['pharmacyName'] ?? pharmacyName;
      address = userDoc.data()?['address'] ?? address;
      contact = userDoc.data()?['contact'] ?? contact;
    }

    final lowStockCount = filtered.where((m) => m.quantity <= 10).length;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (_) => [
          // Header Section
          pw.Column(children: [
            pw.Text("Expiry Report", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Divider(thickness: 1),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text("Pharmacy Name: $pharmacyName"),
                    pw.Text("Address: $address"),
                    pw.Text("Contact: $contact"),
                  ],
                ),
                pw.Text("Generated On: ${now.toString().split('.')[0]}",
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ]),

          pw.SizedBox(height: 20),

          // Table Section
          pw.Table.fromTextArray(
            headers: ["Name", "Category", "Qty", "Expiry Date"],
            data: filtered.map((m) => [
              m.name,
              m.category,
              m.quantity,
              m.expiryDate.toIso8601String().split('T')[0],
            ]).toList(),
          ),

          // Summary Section
          pw.SizedBox(height: 25),
          pw.Text("Summary", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Container(
            alignment: pw.Alignment.centerLeft,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("Total Medicines Listed: ${filtered.length} items"),
                pw.Text("Low Stock Count (≤10): $lowStockCount items"),
                if (user != null) pw.Text("Generated by: ${user.email}"),
              ],
            ),
          ),

          pw.SizedBox(height: 40),
          pw.Divider(thickness: 0.5),
          // pw.Text("Signature / Approval:"),
          pw.SizedBox(height: 40),
          pw.Text("...................................................."),
          pw.Text("Pharmacist / Admin Signature"),
        ],
      ),
    );

    return _savePDF(pdf, 'expiry_report');
  }


  Future<File> _savePDF(pw.Document pdf, String namePrefix) async {
    final dir = Platform.isAndroid
        ? Directory('/storage/emulated/0/Download')
        : await getApplicationDocumentsDirectory();

    final file = File('${dir.path}/${namePrefix}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }
}
