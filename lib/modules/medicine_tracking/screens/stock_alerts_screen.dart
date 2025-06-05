import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Medwise/modules/medicine_tracking/models/medicine_model.dart';
import 'package:Medwise/modules/medicine_tracking/controller/medicine_controller.dart';
import 'package:Medwise/services/usage_log_service.dart';


class StockAlertsScreen extends StatefulWidget {
  const StockAlertsScreen({super.key});

  @override
  State<StockAlertsScreen> createState() => _StockAlertsScreenState();
}

class _StockAlertsScreenState extends State<StockAlertsScreen> {
  final controller = MedicineController();
  final TextEditingController _searchController = TextEditingController();
  String searchTerm = '';

  List<Medicine> lowStock = [];
  List<Medicine> outOfStock = [];
  List<Medicine> originalLowStock = [];
  List<Medicine> originalOutOfStock = [];


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _applySearchFilter() {
    final term = searchTerm.toLowerCase();

    setState(() {
      if (term.isEmpty) {
        lowStock = List.from(originalLowStock);
        outOfStock = List.from(originalOutOfStock);
      } else {
        lowStock = originalLowStock.where((m) => m.name.toLowerCase().contains(term)).toList();
        outOfStock = originalOutOfStock.where((m) => m.name.toLowerCase().contains(term)).toList();
      }
    });
  }


  Future<void> _loadData() async {
    final all = await controller.fetchMedicines();

    originalLowStock = all.where((m) => m.quantity > 0 && m.quantity <= 10).toList();
    originalOutOfStock = all.where((m) => m.quantity == 0).toList();

    _applySearchFilter(); // Apply search to the fresh full data
  }

  void _showRestockDialog(Medicine medicine) {
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Restock: ${medicine.name}"),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Add Quantity",
            hintText: "Enter amount to add",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final input = int.tryParse(qtyController.text.trim());
              if (input != null && input > 0) {
                final newQty = medicine.quantity + input;

                final uid = FirebaseAuth.instance.currentUser?.uid;
                if (uid == null) return;

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('medicines')
                    .doc(medicine.id)
                    .update({'quantity': newQty});

                Navigator.pop(context);
                await _loadData();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${medicine.name} restocked (+$input)")),
                );
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  Widget _buildList(String title, List<Medicine> items, Color color, IconData icon) {
    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...items.map((m) => Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  m.quantity == 0 ? Icons.close : Icons.warning_amber_rounded,
                  color: m.quantity == 0 ? Colors.red : Colors.orange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        "Qty: ${m.quantity} | Exp: ${m.expiryDate.toIso8601String().split('T')[0]}",
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => _showRestockDialog(m),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEE720D),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Restock",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid == null) return;

                        final newQty = m.quantity - 5;

                        if (newQty >= 0) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('medicines')
                              .doc(m.id)
                              .update({'quantity': newQty});

                          await UsageLogService.logMedicineUsage(
                            medicineId: m.id,
                            medicineName: m.name,
                            quantityUsed: 5,
                            reason: "Sold",
                          );

                          await _loadData();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${m.name} — 5 units marked as sold")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Not enough stock to use.")),
                          );
                        }
                      },
                      child: const Text(
                        "Use 5",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )),
        const SizedBox(height: 20),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Stock Alerts")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search medicine...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                searchTerm = value.trim();
                _applySearchFilter();
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildList("Low Stock (≤ 10)", lowStock, Colors.orange, Icons.warning_amber_rounded),
                  _buildList("Out of Stock", outOfStock, Colors.red, Icons.error_outline),
                  if (lowStock.isEmpty && outOfStock.isEmpty)
                    const Center(child: Text("No stock issues found", style: TextStyle(fontSize: 16))),
                ],
              ),
            ),
          ],
        ),

      ),
    );
  }
}
