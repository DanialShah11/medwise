// ✅ Enhanced ScanScreen with delete fix and overflow-safe layout
import 'package:Medwise/modules/medicine_tracking/screens/add_medicine_screen.dart';
import 'package:Medwise/modules/medicine_tracking/screens/medicine_detail_screen.dart';
import 'package:Medwise/modules/medicine_tracking/screens/view_medicines_screen.dart';
import 'package:Medwise/modules/medicine_tracking/widgets/medicine_card.dart';
import 'package:Medwise/services/medicine_service.dart';
import 'package:Medwise/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../modules/medicine_tracking/models/medicine_model.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController controller = MobileScannerController();
  String? scannedBarcode;
  Medicine? scannedMedicine;
  bool isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (isProcessing) return;
    final barcode = capture.barcodes.first.rawValue;
    if (barcode == null) return;

    setState(() {
      isProcessing = true;
    });

    final med = await MedicineService().searchMedicineByBarcode(barcode);
    setState(() {
      scannedBarcode = barcode;
      scannedMedicine = med;
      isProcessing = false;
    });
  }

  void _openAddMedicine() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMedicineScreen(
          existingMedicine: null,
          initialBarcode: scannedBarcode, // ✅ pass barcode directly
        ),
        settings: RouteSettings(arguments: scannedBarcode),
      ),
    );

    if (result != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Success"),
          content: const Text("Medicine added successfully!"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }

    final med = await MedicineService().searchMedicineByBarcode(scannedBarcode!);
    setState(() {
      scannedMedicine = med;
    });
  }

  void _openUpdateQuantityDialog() {
    final TextEditingController qtyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Update Stock Quantity"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Current Quantity: ${scannedMedicine?.quantity ?? 0}"),
            const SizedBox(height: 10),
            const Text("Enter quantity to add (+5) or remove (-2):"),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: "+5 or -2"),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
              onPressed: () async {
                final val = int.tryParse(qtyController.text.trim());
                if (val != null && scannedMedicine != null) {
                  final newQty = scannedMedicine!.quantity + val;
                  await MedicineService().updateMedicineQuantity(
                    scannedMedicine!.id,
                    newQty < 0 ? 0 : newQty,
                  );
                  Navigator.pop(context);
                  final med = await MedicineService().searchMedicineByBarcode(scannedBarcode!);
                  setState(() {
                    scannedMedicine = med;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Stock updated successfully"),
                  ));
                }
              },
              child: const Text("Update"))
        ],
      ),
    );
  }

  void _validateExpiry() {
    if (scannedMedicine == null) return;
    final now = DateTime.now();
    final isExpired = scannedMedicine!.expiryDate.isBefore(now);
    final formattedDate = "${scannedMedicine!.expiryDate.toLocal()}".split(' ')[0];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Expiry Date"),
        content: Text(isExpired
            ? "⚠️ This medicine is expired on $formattedDate"
            : "✅ This medicine will expire on $formattedDate"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _refreshMedicine() async {
    if (scannedBarcode != null) {
      final med = await MedicineService().searchMedicineByBarcode(scannedBarcode!);
      setState(() {
        scannedMedicine = med;
        if (scannedMedicine == null) scannedBarcode = null; // Reset UI if deleted
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF273671),
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Barcode Scanner",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: MobileScanner(
              controller: controller,
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: scannedBarcode == null
                  ? const Center(child: Text("Scan a barcode to begin..."))
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "Scanned: $scannedBarcode",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (scannedMedicine == null)
                    ElevatedButton.icon(
                      onPressed: _openAddMedicine,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        "Add New Medicine",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF273671),
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    )

                  else ...[
                    ElevatedButton(
                      onPressed: _openUpdateQuantityDialog,
                      child: const Text("Update Stock"),
                    ),
                    ElevatedButton(
                      onPressed: _validateExpiry,
                      child: const Text("Expiry Date"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ViewMedicinesScreen()),
                      ),
                      child: const Text("View Real-time Medicine List"),
                    ),
                    const SizedBox(height: 10),
                    if (scannedMedicine != null)
                      MedicineCard(
                        medicine: scannedMedicine!,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MedicineDetailScreen(
                                medicine: scannedMedicine!,
                              ),
                            ),
                          );
                          _refreshMedicine();
                        },
                      )
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
