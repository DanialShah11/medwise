import 'package:flutter/material.dart';
import 'package:Medwise/modules/medicine_tracking/screens/add_medicine_screen.dart';
import 'package:Medwise/modules/medicine_tracking/screens/medicine_detail_screen.dart';
import 'package:Medwise/modules/medicine_tracking/models/medicine_model.dart';
import 'package:Medwise/modules/medicine_tracking/controller/medicine_controller.dart';
import 'package:Medwise/modules/medicine_tracking/widgets/medicine_card.dart';
import 'package:Medwise/modules/medicine_tracking/widgets/empty_state_widget.dart';
import 'package:Medwise/services/csv_service.dart';
import 'package:Medwise/services/local_notification_service.dart';
import 'package:Medwise/services/medicine_service.dart';
import 'package:Medwise/modules/barcode_scanning/screens/simple_scan_screen.dart';

class ViewMedicinesScreen extends StatefulWidget {
  const ViewMedicinesScreen({super.key});

  @override
  State<ViewMedicinesScreen> createState() => _ViewMedicinesScreenState();
}

class _ViewMedicinesScreenState extends State<ViewMedicinesScreen> {
  final controller = MedicineController();

  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _selectionMode = false;
  Set<String> _selectedIds = {};

  void _toggleSelection(String id) {
    setState(() {
      _selectedIds.contains(id)
          ? _selectedIds.remove(id)
          : _selectedIds.add(id);
    });
  }

  void _toggleSelectAll(List<Medicine> medicines) {
    final allIds = medicines.map((m) => m.id).toSet();
    setState(() {
      if (_selectedIds.length == medicines.length) {
        _selectedIds.clear(); // Unselect all
      } else {
        _selectedIds = allIds; // Select all
      }
    });
  }


  void _clearSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _deleteSelected() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Bulk Deletion"),
        content:
        Text("Are you sure you want to delete ${_selectedIds.length} medicines?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      for (final id in _selectedIds) {
        await controller.deleteMedicine(id);
      }
      _clearSelection();
    }
  }

  void _exportCSV() async {
    final medicines = await controller.fetchMedicinesForExport();
    final success = await CSVService.exportToCSV(medicines);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? "CSV exported successfully!" : "Export failed."),
    ));
  }

  void _importCSV() async {
    final success = await CSVService.importFromCSV(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? "CSV imported successfully!" : "Import failed."),
    ));
  }

  void _startBarcodeSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SimpleScanScreen(
          onDetect: (barcode) => Navigator.pop(context, barcode),
        ),
      ),
    );

    if (result != null && result is String) {
      final trimmedBarcode = result.trim();
      final medicine = await MedicineService().searchMedicineByBarcode(trimmedBarcode);

      if (medicine != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MedicineDetailScreen(medicine: medicine),
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Medicine Not Found"),
            content: Text('No medicine was found for barcode:\n\n"$trimmedBarcode"'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
          ),
        );
      }
    }
  }

  List<Medicine> _filterMedicines(List<Medicine> medicines) {
    return medicines.where((medicine) {
      final matchesSearch =
      medicine.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' ||
          medicine.category.toLowerCase() == _selectedCategory.toLowerCase();
      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    LocalNotificationService.initialize(context);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectionMode) {
          _clearSelection();
          return false; // Prevent back navigation and exit selection mode
        }
        return true; // Allow normal back
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selectionMode
              ? "${_selectedIds.length} Selected"
              : "Your Medicines"),
          actions: _selectionMode
              ? [
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Toggle Select All',
              onPressed: () async {
                final all = await controller.fetchMedicines();
                setState(() {
                  if (_selectedIds.length == all.length) {
                    _selectedIds.clear(); // just unselect
                  } else {
                    _selectedIds = all.map((m) => m.id).toSet(); // select all
                  }
                });
              },

            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Selected',
              onPressed: _deleteSelected,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: _clearSelection,
            ),
          ]
              : [
            IconButton(
                icon: const Icon(Icons.upload_file), onPressed: _importCSV),
            IconButton(
                icon: const Icon(Icons.download), onPressed: _exportCSV),
            IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: _startBarcodeSearch),
          ],
          bottom: !_selectionMode
              ? PreferredSize(
            preferredSize: const Size.fromHeight(135),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by name...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 10),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: 'All', child: Text('All Categories')),
                      DropdownMenuItem(
                          value: 'Tablet', child: Text('Tablet')),
                      DropdownMenuItem(
                          value: 'Capsule', child: Text('Capsule')),
                      DropdownMenuItem(
                          value: 'Syrup', child: Text('Syrup')),
                      DropdownMenuItem(
                          value: 'Injection', child: Text('Injection')),
                      DropdownMenuItem(
                          value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedCategory = value!),
                  ),
                  const SizedBox(height: 6),
                  const SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green, size: 18),
                        SizedBox(width: 4),
                        Text("Valid  "),
                        Icon(Icons.schedule,
                            color: Colors.yellow, size: 18),
                        SizedBox(width: 4),
                        Text("< 30 Days  "),
                        Icon(Icons.warning,
                            color: Colors.amber, size: 18),
                        SizedBox(width: 4),
                        Text("< 15 Days  "),
                        Icon(Icons.warning_amber_outlined,
                            color: Colors.orange, size: 18),
                        SizedBox(width: 4),
                        Text("< 7 Days  "),
                        Icon(Icons.error, color: Colors.red, size: 18),
                        SizedBox(width: 4),
                        Text("Expired"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
              : null,
        ),
        body: StreamBuilder<List<Medicine>>(
          stream: controller.streamMedicines(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const EmptyStateWidget(
                title: "No Medicines",
                subtitle: "Start adding your stock using the + button below.",
                icon: Icons.inventory_2_outlined,
              );
            }

            final filtered = _filterMedicines(snapshot.data!);

            return ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final medicine = filtered[index];
                return MedicineCard(
                  medicine: medicine,
                  selectionMode: _selectionMode,
                  selected: _selectedIds.contains(medicine.id),
                  onTap: () {
                    if (_selectionMode) {
                      _toggleSelection(medicine.id);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MedicineDetailScreen(medicine: medicine),
                        ),
                      );
                    }
                  },
                  onLongPress: () {
                    if (!_selectionMode) {
                      setState(() {
                        _selectionMode = true;
                        _selectedIds.add(medicine.id);
                      });
                    }
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: !_selectionMode
            ? FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddMedicineScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
          tooltip: 'Add Medicine',
        )
            : null,
      ),
    );
  }

}
