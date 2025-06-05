// import 'dart:io';
// import 'package:csv/csv.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:Medwise/modules/medicine_tracking/models/medicine_model.dart';
// import 'package:Medwise/services/csv_service.dart';
//
//
// class CsvService {
//   static Future<void> exportMedicinesToCSV(List<Medicine> medicines) async {
//     List<List<dynamic>> rows = [];
//
//     // Header row
//     rows.add(['Name', 'Quantity', 'Category', 'Expiry Date', 'Notes']);
//
//     // Data rows
//     for (var med in medicines) {
//       rows.add([
//         med.name,
//         med.quantity.toString(),
//         med.category,
//         med.expiryDate,
//         med.notes ?? '',
//       ]);
//     }
//
//     String csv = const ListToCsvConverter().convert(rows);
//     final dir = await getTemporaryDirectory();
//     final file = File('${dir.path}/medicines_export.csv');
//     await file.writeAsString(csv);
//
//     Share.shareXFiles([XFile(file.path)], text: 'Exported Medicines CSV');
//   }
// }
