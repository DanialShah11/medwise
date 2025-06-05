import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../medicine_tracking/models/medicine_model.dart';
import '../../medicine_tracking/screens/add_medicine_screen.dart';
import '../../medicine_tracking/controller/medicine_controller.dart';
import 'package:Medwise/utils/constants.dart';

class MedicineCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final bool selected;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onTap,
    this.onLongPress,
    this.selectionMode = false,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isExpired = medicine.expiryDate.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (selectionMode)
                Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? Colors.green : Colors.grey,
                )
              else
                CircleAvatar(
                  backgroundColor: isExpired ? Colors.red : primaryColor,
                  child: Icon(
                    isExpired ? Icons.warning : Icons.medication,
                    color: Colors.white,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            medicine.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _getExpiryIcon(medicine),
                      ],
                    ),
                    if (medicine.strength != null && medicine.strength!.isNotEmpty)
                      Text("Strength: ${medicine.strength}"),
                    Text("Qty: ${medicine.quantity}"),
                    Text("Exp: ${DateFormat.yMMMd().format(medicine.expiryDate)}"),
                  ],
                ),
              ),
              if (!selectionMode)
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Colors.blueAccent),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddMedicineScreen(existingMedicine: medicine),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                      onPressed: () => _confirmDelete(context),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _getExpiryIcon(Medicine medicine) {
    final now = DateTime.now();
    final daysLeft = medicine.expiryDate.difference(now).inDays;

    if (medicine.expiryDate.isBefore(now)) {
      return const Tooltip(
        message: "Expired",
        child: Icon(Icons.error, color: Colors.red, size: 18),
      );
    } else if (daysLeft <= 7) {
      return const Tooltip(
        message: "Expires in < 7 days",
        child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
      );
    } else if (daysLeft <= 15) {
      return const Tooltip(
        message: "Expires in < 15 days",
        child: Icon(Icons.warning, color: Colors.amber, size: 18),
      );
    } else if (daysLeft <= 30) {
      return const Tooltip(
        message: "Expires in < 30 days",
        child: Icon(Icons.schedule, color: Colors.yellow, size: 18),
      );
    } else {
      return const Tooltip(
        message: "Valid",
        child: Icon(Icons.check_circle, color: Colors.green, size: 18),
      );
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Medicine"),
        content: const Text("Are you sure you want to delete this medicine?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await MedicineController().deleteMedicine(medicine.id);
              Navigator.of(ctx).pop();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
