import 'package:flutter/material.dart';
import 'package:Medwise/modules/medicine_tracking/controller/medicine_controller.dart';
import 'package:Medwise/modules/medicine_tracking/models/medicine_model.dart';

class BatchTrackerScreen extends StatefulWidget {
  const BatchTrackerScreen({super.key});

  @override
  State<BatchTrackerScreen> createState() => _BatchTrackerScreenState();
}

class _BatchTrackerScreenState extends State<BatchTrackerScreen> {
  final controller = MedicineController();
  final TextEditingController searchController = TextEditingController();
  Map<String, List<Medicine>> batchMap = {};
  Map<String, List<Medicine>> displayedBatches = {};

  @override
  void initState() {
    super.initState();
    _loadBatches();
  }

  Future<void> _loadBatches() async {
    final meds = await controller.fetchMedicines();
    final Map<String, List<Medicine>> map = {};

    for (final med in meds) {
      final batch = med.batchNumber?.trim() ?? 'No Batch';
      map.putIfAbsent(batch, () => []);
      map[batch]!.add(med);
    }

    setState(() {
      batchMap = map;
      displayedBatches = Map.from(batchMap);
    });
  }

  void _filterBatches(String query) {
    final term = query.toLowerCase();
    if (term.isEmpty) {
      setState(() => displayedBatches = Map.from(batchMap));
    } else {
      final filtered = batchMap.entries
          .where((entry) => entry.key.toLowerCase().contains(term))
          .map((e) => MapEntry(e.key, e.value))
          .toList();
      setState(() => displayedBatches = Map.fromEntries(filtered));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Batch Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: _filterBatches,
              decoration: InputDecoration(
                hintText: "Search batch number...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: displayedBatches.isEmpty
                  ? const Center(child: Text("No batches found"))
                  : ListView(
                children: displayedBatches.entries.map((entry) {
                  return ExpansionTile(
                    title: Text("Batch: ${entry.key}"),
                    children: entry.value.map((med) {
                      return ListTile(
                        title: Text(med.name),
                        subtitle: Text("Qty: ${med.quantity} | Exp: ${med.expiryDate.toIso8601String().split('T')[0]}"),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
