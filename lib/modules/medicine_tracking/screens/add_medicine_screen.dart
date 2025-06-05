import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:Medwise/services/medicine_service.dart';
import 'package:Medwise/modules/medicine_tracking/models/medicine_model.dart';
import 'package:Medwise/utils/constants.dart';
import 'package:Medwise/modules/medicine_tracking/controller/medicine_controller.dart';
import 'package:Medwise/modules/barcode_scanning/screens/simple_scan_screen.dart';

class AddMedicineScreen extends StatefulWidget {
  final Medicine? existingMedicine;
  final String? initialBarcode; // ✅ add this
  const AddMedicineScreen({
    super.key,
    this.existingMedicine,
    this.initialBarcode, // ✅ initialize here
  });

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = MedicineController();

  final nameController = TextEditingController();
  final strengthController = TextEditingController();
  final formulaController = TextEditingController();
  final quantityController = TextEditingController();
  final cartonsController = TextEditingController();
  final unitsPerCartonController = TextEditingController();
  final unitPriceController = TextEditingController();
  final cartonPriceController = TextEditingController();
  final wholesalePriceController = TextEditingController();
  final batchNumberController = TextEditingController();
  final notesController = TextEditingController();
  final barcodeController = TextEditingController();
  bool _expiryDateMissing = false;

  DateTime? selectedDate;
  String selectedCategory = 'Tablet';
  final List<String> categories = ['Tablet', 'Syrup', 'Capsule', 'Injection', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.existingMedicine != null) {
      final m = widget.existingMedicine!;
      nameController.text = m.name;
      strengthController.text = m.strength ?? '';
      formulaController.text = m.formula ?? '';
      quantityController.text = m.quantity.toString();
      cartonsController.text = m.cartonsQuantity?.toString() ?? '';
      unitsPerCartonController.text = m.unitsPerCarton?.toString() ?? '';
      unitPriceController.text = m.unitPrice?.toString() ?? '';
      cartonPriceController.text = m.cartonPrice?.toString() ?? '';
      wholesalePriceController.text = m.wholesalePrice?.toString() ?? '';
      batchNumberController.text = m.batchNumber ?? '';
      notesController.text = m.notes ?? '';
      selectedDate = m.expiryDate;
      selectedCategory = m.category;
      barcodeController.text = m.barcode ?? '';
    }else if (widget.initialBarcode != null) {
      barcodeController.text = widget.initialBarcode!;
    }
  }

  void _openScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SimpleScanScreen(
          onDetect: (barcode) => Navigator.pop(context, barcode),
        ),
      ),
    );

    if (result != null && result is String) {
      final trimmed = result.trim();
      final existing = await MedicineService().searchMedicineByBarcode(trimmed);

      if (existing != null) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Already Exists"),
            content: Text('A medicine with barcode "$trimmed" already exists.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        setState(() => barcodeController.text = trimmed);
      }
    }
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _saveMedicine() async {
    if (selectedDate == null) {
      setState(() {
        _expiryDateMissing = true;
      });
    } else {
      setState(() {
        _expiryDateMissing = false;
      });
    }

    if (_formKey.currentState!.validate() && selectedDate != null) {
      final medicine = Medicine(
        id: widget.existingMedicine?.id ?? const Uuid().v4(),
        name: nameController.text.trim(),
        strength: strengthController.text.trim(),
        formula: formulaController.text.trim(),
        quantity: int.parse(quantityController.text),
        cartonsQuantity: int.tryParse(cartonsController.text),
        unitsPerCarton: int.tryParse(unitsPerCartonController.text),
        unitPrice: double.tryParse(unitPriceController.text),
        cartonPrice: double.tryParse(cartonPriceController.text),
        wholesalePrice: double.tryParse(wholesalePriceController.text),
        batchNumber: batchNumberController.text.trim().isNotEmpty
            ? batchNumberController.text.trim()
            : null,
        expiryDate: selectedDate!,
        category: selectedCategory,
        notes: notesController.text.trim(),
        barcode: barcodeController.text.trim(),
        timestamp: widget.existingMedicine?.timestamp ?? DateTime.now(),
      );

      if (widget.existingMedicine != null) {
        await _controller.updateMedicine(medicine);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Medicine updated")));
      } else {
        await _controller.addMedicine(medicine);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Medicine added")));
      }

      Navigator.pop(context);
    }
  }


  @override
  void dispose() {
    nameController.dispose();
    strengthController.dispose();
    formulaController.dispose();
    quantityController.dispose();
    cartonsController.dispose();
    unitsPerCartonController.dispose();
    unitPriceController.dispose();
    cartonPriceController.dispose();
    wholesalePriceController.dispose();
    batchNumberController.dispose();
    notesController.dispose();
    barcodeController.dispose();
    super.dispose();
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 25, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primaryColor),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: required
          ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingMedicine != null ? "Edit Medicine" : "Add Medicine",
          style: const TextStyle(color: Colors.white), // ✅ Make text white
        ),
        iconTheme: const IconThemeData(color: Colors.white), // ✅ Make back icon white too
        backgroundColor: const Color(0xFF273671),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _sectionTitle("Basic Info"),
              _inputField(controller: nameController, label: "Medicine Name", required: true),
              const SizedBox(height: 10),
              _inputField(controller: strengthController, label: "Strength (e.g. 20mg/20ml)"),
              const SizedBox(height: 10),
              _inputField(controller: formulaController, label: "Formula (Optional)"),
              const SizedBox(height: 10),

              _sectionTitle("Stock Details"),
              _inputField(controller: quantityController, label: "Unit/Packet Quantity", required: true, keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _inputField(controller: cartonsController, label: "Number of Cartons", keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _inputField(controller: unitsPerCartonController, label: "Units per Carton", keyboardType: TextInputType.number),

              _sectionTitle("Pricing"),
              _inputField(controller: unitPriceController, label: "Selling Price (per unit/packet box)", required: true, keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _inputField(controller: cartonPriceController, label: "Carton Price", keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _inputField(controller: wholesalePriceController, label: "Wholesale Price (Optional)", keyboardType: TextInputType.number),

              _sectionTitle("Extra Info"),
              _inputField(controller: batchNumberController, label: "Batch Number (Optional)"),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedDate == null
                        ? "No expiry date selected"
                        : "Expiry: ${DateFormat.yMMMd().format(selectedDate!)}",
                    style: TextStyle(
                      color: selectedDate == null && _expiryDateMissing ? Colors.red : Colors.black,
                      fontWeight: selectedDate == null && _expiryDateMissing ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _pickExpiryDate,
                    child: const Text("Pick Date"),
                  ),
                ],
              ),

              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) => setState(() => selectedCategory = val!),
              ),
              const SizedBox(height: 15),
              _inputField(controller: notesController, label: "Notes (Optional)"),
              const SizedBox(height: 15),
              TextFormField(
                controller: barcodeController,
                decoration: InputDecoration(
                  labelText: 'Barcode',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: _openScanner,
                  ),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton.icon(
                onPressed: _saveMedicine,
                icon: Icon(
                  widget.existingMedicine != null ? Icons.update : Icons.save,
                  size: 22,
                  color: Colors.white, // ✅ Icon color white
                ),
                label: Text(
                  widget.existingMedicine != null ? "Update Medicine" : "Save Medicine",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF273671),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 4,
                  shadowColor: Colors.black87,
                ),
              ),


            ],
          ),
        ),
      ),
    );
  }
}
