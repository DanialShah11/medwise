import 'package:flutter/material.dart';
import 'package:Medwise/services/pharmacy_profile_service.dart';

class PharmacyInfoPrompt extends StatefulWidget {
  const PharmacyInfoPrompt({super.key});

  @override
  State<PharmacyInfoPrompt> createState() => _PharmacyInfoPromptState();
}

class _PharmacyInfoPromptState extends State<PharmacyInfoPrompt> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _pharmacyNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  String _countryCode = "+92"; // Default to Pakistan, change if needed

  Future<void> _saveInfo() async {
    if (_formKey.currentState!.validate()) {
      final contact = '$_countryCode${_contactController.text.trim()}';

      await PharmacyProfileService.savePharmacyInfo(
        pharmacyName: _pharmacyNameController.text.trim(),
        address: _addressController.text.trim(),
        contact: contact,
      );

      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Pharmacy Info Required"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _pharmacyNameController,
                decoration: const InputDecoration(labelText: "Pharmacy Name"),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: "Address"),
                validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _countryCode,
                    onChanged: (value) => setState(() => _countryCode = value!),
                    items: const [
                      DropdownMenuItem(value: "+92", child: Text("+92 🇵🇰")),
                      DropdownMenuItem(value: "+91", child: Text("+91 🇮🇳")),
                      DropdownMenuItem(value: "+1", child: Text("+1 🇺🇸")),
                      DropdownMenuItem(value: "+44", child: Text("+44 🇬🇧")),
                      // Add more as needed
                    ],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: "Phone Number"),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (!RegExp(r'^\d{6,15}$').hasMatch(value)) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saveInfo,
          child: const Text("Save"),
        ),
      ],
    );
  }
}
