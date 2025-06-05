import 'package:flutter/material.dart';
import 'package:Medwise/modules/medicine_tracking/models/medicine_model.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart' show Share, XFile;
import 'package:share_plus/share_plus.dart';

import 'dart:io';
import 'package:Medwise/services/csv_service.dart';
import 'package:Medwise/services/medicine_service.dart';

class ExpiryAlertsScreen extends StatefulWidget {
  const ExpiryAlertsScreen({super.key});

  @override
  State<ExpiryAlertsScreen> createState() => _ExpiryAlertsScreenState();
}

class _ExpiryAlertsScreenState extends State<ExpiryAlertsScreen> {
  final MedicineService _medicineService = MedicineService();
  String searchQuery = '';
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime plus7 = now.add(const Duration(days: 7));
    DateTime plus15 = now.add(const Duration(days: 15));
    DateTime plus30 = now.add(const Duration(days: 30));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expiry Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download CSV',
            onPressed: () async {
              final allMeds = await _medicineService.getAllMedicines();
              final filtered = _filterMedicines(allMeds);

              final success = await CSVService.exportToCSV(filtered);

              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ Failed to export CSV")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ CSV downloaded to Downloads folder")),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share CSV',
            onPressed: () async {
              final allMeds = await _medicineService.getAllMedicines();
              final filtered = _filterMedicines(allMeds);

              final now = DateTime.now();
              final filename =
                  'medicines_${now.year}-${now.month}-${now.day}_${now.hour}${now.minute}.csv';

              final directory = Directory('/storage/emulated/0/Download');
              final path = '${directory.path}/$filename';
              final file = File(path);

              if (!await file.exists()) {
                // If file doesn't exist yet, generate it first
                final success = await CSVService.exportToCSV(filtered);
                if (!success) return;
              }

              await Share.shareXFiles(
                [XFile(path)],
                text: 'Expiry Alerts CSV',
              );
            },
          ),
        ],

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 12),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search medicines...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var f in ['All', 'Expired', '7 Days', '15 Days', '30 Days'])
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: filter == f,
                            onSelected: (_) {
                              setState(() {
                                filter = f;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Medicine>>(
        stream: _medicineService.getMedicineStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          List<Medicine> filteredMedicines = _filterMedicines(snapshot.data!);
          filteredMedicines.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));

          if (filteredMedicines.isEmpty) {
            return const Center(child: Text('No matching medicines.'));
          }

          return ListView.builder(
            itemCount: filteredMedicines.length,
            itemBuilder: (context, index) {
              final med = filteredMedicines[index];
              final expiry = med.expiryDate;
              final isExpired = expiry.isBefore(now);
              final isExpiring7 = !isExpired && expiry.isBefore(plus7);
              final isExpiring15 = !isExpired && expiry.isAfter(plus7) && expiry.isBefore(plus15);
              final isExpiring30 = !isExpired && expiry.isAfter(plus15) && expiry.isBefore(plus30);

              Color cardColor = Colors.green[100]!;
              String status = 'Safe';
              Color statusColor = Colors.green;

              if (isExpired) {
                cardColor = Colors.red[100]!;
                status = 'Expired';
                statusColor = Colors.red;
              } else if (isExpiring7) {
                cardColor = Colors.orange[100]!;
                status = 'Expires in <7 days';
                statusColor = Colors.orange;
              } else if (isExpiring15) {
                cardColor = Colors.yellow[100]!;
                status = 'Expires in <15 days';
                statusColor = Colors.orangeAccent;
              } else if (isExpiring30) {
                cardColor = Colors.yellow[50]!;
                status = 'Expires in <30 days';
                statusColor = Colors.orangeAccent;
              }

              return Card(
                color: cardColor,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(med.name),
                  subtitle: Text('Expiry: ${DateFormat.yMMMd().format(med.expiryDate)}'),
                  trailing: Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<Medicine> _filterMedicines(List<Medicine> allMedicines) {
    DateTime now = DateTime.now();
    DateTime plus7 = now.add(const Duration(days: 7));
    DateTime plus15 = now.add(const Duration(days: 15));
    DateTime plus30 = now.add(const Duration(days: 30));

    return allMedicines.where((medicine) {
      final nameLower = medicine.name.toLowerCase();
      final matchesSearch = nameLower.contains(searchQuery.toLowerCase());

      final expiry = medicine.expiryDate;
      final isExpired = expiry.isBefore(now);
      final isExpiring7 = !isExpired && expiry.isBefore(plus7);
      final isExpiring15 = !isExpired && expiry.isAfter(plus7) && expiry.isBefore(plus15);
      final isExpiring30 = !isExpired && expiry.isAfter(plus15) && expiry.isBefore(plus30);

      bool matchesFilter = false;
      switch (filter) {
        case 'All':
          matchesFilter = true;
          break;
        case 'Expired':
          matchesFilter = isExpired;
          break;
        case '7 Days':
          matchesFilter = isExpiring7;
          break;
        case '15 Days':
          matchesFilter = isExpiring15;
          break;
        case '30 Days':
          matchesFilter = isExpiring30;
          break;
      }

      return matchesSearch && matchesFilter;
    }).toList();
  }

  // Future<void> exportToCSV(List<Medicine> medicines) async {
  //   List<List<String>> rows = [
  //     ['Name', 'Quantity', 'Expiry Date', 'Category', 'Notes'],
  //     ...medicines.map((med) => [
  //       med.name,
  //       med.quantity.toString(),
  //       DateFormat.yMd().format(med.expiryDate),
  //       med.category,
  //       med.notes ?? ''
  //     ])
  //   ];
  //
  //   String csvData = const ListToCsvConverter().convert(rows);
  //   final directory = await getTemporaryDirectory();
  //   final path = '${directory.path}/expiry_alerts.csv';
  //   final file = File(path);
  //   await file.writeAsString(csvData);
  //
  //   await Share.shareXFiles([XFile(path)], text: 'Expiry Alerts CSV Export');
  // }
}
