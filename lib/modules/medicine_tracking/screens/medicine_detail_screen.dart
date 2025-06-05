import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:Medwise/modules/medicine_tracking/models/medicine_model.dart';
import 'package:Medwise/modules/medicine_tracking/screens/add_medicine_screen.dart';
import 'package:Medwise/utils/constants.dart';
import 'package:Medwise/services/usage_log_service.dart';

class MedicineDetailScreen extends StatefulWidget {
  final Medicine medicine;

  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  late Medicine medicine;

  @override
  void initState() {
    super.initState();
    medicine = widget.medicine;
  }

  void _editMedicine() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicineScreen(existingMedicine: medicine),
      ),
    );

    if (updated != null && updated is Medicine) {
      setState(() {
        medicine = updated;
      });
    }
  }

  void _showLogUsageDialog(Medicine medicine) {
    final qtyController = TextEditingController();
    String selectedReason = "Sold";
    final List<String> reasons = ["Sold", "Expired", "Wasted"];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Log Usage: ${medicine.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity Used"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedReason,
              decoration: const InputDecoration(labelText: "Reason"),
              items: reasons.map((reason) {
                return DropdownMenuItem(value: reason, child: Text(reason));
              }).toList(),
              onChanged: (value) {
                selectedReason = value!;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final qty = int.tryParse(qtyController.text.trim());
              if (qty == null || qty <= 0) return;

              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;

              final newQty = medicine.quantity - qty;
              if (newQty < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Not enough stock")),
                );
                return;
              }

              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('medicines')
                  .doc(medicine.id)
                  .update({'quantity': newQty});

              await UsageLogService.logMedicineUsage(
                medicineId: medicine.id,
                medicineName: medicine.name,
                quantityUsed: qty,
                reason: selectedReason,
              );

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("${medicine.name}: $qty units logged as $selectedReason")),
              );

              setState(() {
                medicine = medicine.copyWith(quantity: newQty);
              });
            },
            child: const Text("Log Usage"),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF273671),
        title: const Text(
          "Medicine Details",
          style: TextStyle(color: Colors.white), // ✅ white title
        ),
        iconTheme: const IconThemeData(color: Colors.white), // ✅ white back icon
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow("Name", medicine.name),
                    if (medicine.strength?.isNotEmpty == true)
                      _detailRow("Strength", medicine.strength!),
                    if (medicine.formula?.isNotEmpty == true)
                      _detailRow("Formula", medicine.formula!),
                    _detailRow("Quantity", medicine.quantity.toString()),
                    if (medicine.cartonsQuantity != null)
                      _detailRow("Cartons", medicine.cartonsQuantity.toString()),
                    if (medicine.unitsPerCarton != null)
                      _detailRow("Units/Carton", medicine.unitsPerCarton.toString()),
                    if (medicine.unitPrice != null)
                      _detailRow("Unit Price", "Rs.${medicine.unitPrice!.toStringAsFixed(2)}"),
                    if (medicine.cartonPrice != null)
                      _detailRow("Carton Price", "Rs.${medicine.cartonPrice!.toStringAsFixed(2)}"),
                    if (medicine.wholesalePrice != null)
                      _detailRow("Wholesale Price", "Rs.${medicine.wholesalePrice!.toStringAsFixed(2)}"),
                    if (medicine.batchNumber?.isNotEmpty == true)
                      _detailRow("Batch No", medicine.batchNumber!),
                    _detailRow("Expiry", DateFormat.yMMMd().format(medicine.expiryDate)),
                    _detailRow("Category", medicine.category),
                    if (medicine.notes?.isNotEmpty == true)
                      _detailRow("Notes", medicine.notes!),
                    if (medicine.barcode?.isNotEmpty == true)
                      _detailRow("Barcode", medicine.barcode!),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        "Added: ${DateFormat.yMMMd().add_jm().format(medicine.timestamp)}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.history),
              label: const Text("Log Usage / Expiry"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _showLogUsageDialog(medicine),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _editMedicine,
        child: const Icon(Icons.edit),
        tooltip: 'Edit Medicine',
      ),
    );
  }
}
