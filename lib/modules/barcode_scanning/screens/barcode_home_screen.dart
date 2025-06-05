import 'package:flutter/material.dart';
import 'scan_screen.dart';
import 'package:Medwise/services/medicine_service.dart';
import 'package:Medwise/modules/medicine_tracking/models/medicine_model.dart';
import 'package:Medwise/modules/medicine_tracking/screens/add_medicine_screen.dart';
import 'package:Medwise/modules/medicine_tracking/screens/medicine_detail_screen.dart';
import 'package:uuid/uuid.dart';

class BarcodeHomeScreen extends StatelessWidget {
  const BarcodeHomeScreen({super.key});

  void _handleScan(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ScanScreen(),
      ),

    );
  }

  static void _showNotFoundDialog(BuildContext context, String barcode) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Medicine Not Found"),
        content: Text("No medicine found for barcode:\n\n$barcode\n\nWould you like to add it?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text("Add Medicine"),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMedicineScreen(
                    existingMedicine: Medicine(
                      id: const Uuid().v4(),
                      name: '',
                      quantity: 0,
                      expiryDate: DateTime.now(),
                      category: 'Tablet',
                      notes: '',
                      barcode: barcode,
                      timestamp: DateTime.now(),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static void _showFoundOptions(BuildContext context, Medicine medicine) {
    final now = DateTime.now();
    final isExpired = medicine.expiryDate.isBefore(now);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            runSpacing: 12,
            children: [
              ListTile(
                title: Text("Medicine: ${medicine.name}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Quantity: ${medicine.quantity}\nExpiry: ${medicine.expiryDate.toLocal().toString().split(' ')[0]}"),
              ),
              if (isExpired)
                const Text("⚠️ This medicine is expired!", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text("Update Details"),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddMedicineScreen(existingMedicine: medicine)),
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add +1"),
                    onPressed: () async {
                      await MedicineService().updateMedicineQuantity(medicine.id, medicine.quantity + 1);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quantity increased")));
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.remove),
                    label: const Text("Reduce -1"),
                    onPressed: () async {
                      final newQty = medicine.quantity > 0 ? medicine.quantity - 1 : 0;
                      await MedicineService().updateMedicineQuantity(medicine.id, newQty);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quantity reduced")));
                    },
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.info),
                label: const Text("View Details"),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MedicineDetailScreen(medicine: medicine)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Barcode Scanner"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 100,
              color: Color(0xFF273671),
            ),
            const SizedBox(height: 20),
            const Text(
              "Scan Medicine Barcode",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF273671),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "Quickly identify medicines by scanning their barcode. "
                  "Tap the button below to begin scanning.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            InkWell(
              onTap: () => _handleScan(context),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF273671), Color(0xFF3C4DAF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
                    SizedBox(width: 10),
                    Text(
                      "Start Scanning",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),

    );
  }
}
