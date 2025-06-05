import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:Medwise/modules/medicine_tracking/models/medicine_model.dart';
import 'package:Medwise/modules/medicine_tracking/controller/medicine_controller.dart';

class CSVService {
  static Future<bool> exportToCSV(List<Medicine> medicines) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) return false;

      List<List<dynamic>> rows = [];

      // Header row
      rows.add([
        "Name",
        "Quantity",
        "Expiry Date",
        "Category",
        "Notes",
        "Timestamp",
        "Cartons",
        "Units/Carton",
        "Unit Price",
        "Carton Price",
        "Strength",
        "Wholesale Price",
        "Batch Number",
        "Formula",
        "Barcode",
      ]);

      // Data rows
      for (final med in medicines) {
        rows.add([
          med.name,
          med.quantity,
          med.expiryDate.toIso8601String(),
          med.category,
          med.notes ?? '',
          med.timestamp.toIso8601String(),
          med.cartonsQuantity ?? '',
          med.unitsPerCarton ?? '',
          med.unitPrice ?? '',
          med.cartonPrice ?? '',
          med.strength ?? '',
          med.wholesalePrice ?? '',
          med.batchNumber ?? '',
          med.formula ?? '',
          med.barcode ?? '',
        ]);
      }

      String csv = const ListToCsvConverter().convert(rows);
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) return false;

      final now = DateTime.now();
      final filePath =
          '${directory.path}/medicines_${now.year}-${now.month}-${now.day}_${now.hour}${now.minute}.csv';

      final file = File(filePath);
      await file.writeAsString(csv);

      await OpenFile.open(file.path);
      return true;
    } catch (e) {
      print('Export CSV error: $e');
      return false;
    }
  }

  static Future<bool> importFromCSV(BuildContext context) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) return false;

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) return false;

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final uuid = Uuid();

      List<List<dynamic>> rows =
      const CsvToListConverter().convert(content, eol: '\n');

      final medicines = <Medicine>[];

      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];

        final medicine = Medicine(
          id: uuid.v4(),
          name: row[0].toString(),
          quantity: int.tryParse(row[1].toString()) ?? 0,
          expiryDate: DateTime.tryParse(row[2].toString()) ?? DateTime.now(),
          category: row[3].toString(),
          notes: row.length > 4 ? row[4].toString() : '',
          timestamp: DateTime.tryParse(row.length > 5 ? row[5].toString() : '') ?? DateTime.now(),
          cartonsQuantity: row.length > 6 ? int.tryParse(row[6].toString()) : null,
          unitsPerCarton: row.length > 7 ? int.tryParse(row[7].toString()) : null,
          unitPrice: row.length > 8 ? double.tryParse(row[8].toString()) : null,
          cartonPrice: row.length > 9 ? double.tryParse(row[9].toString()) : null,
          strength: row.length > 10 ? row[10].toString() : '',
          wholesalePrice: row.length > 11 ? double.tryParse(row[11].toString()) : null,
          batchNumber: row.length > 12 ? row[12].toString() : '',
          formula: row.length > 13 ? row[13].toString() : '',
          barcode: row.length > 14 ? row[14].toString() : '',
        );

        medicines.add(medicine);
      }

      final controller = MedicineController();
      for (final med in medicines) {
        await controller.addMedicine(med);
      }

      return true;
    } catch (e) {
      print('Import CSV error: $e');
      return false;
    }
  }
}
