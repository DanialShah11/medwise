import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:Medwise/modules/expiry_alerts/controller/expiry_controller.dart';

class ExpiryHomeScreen extends StatefulWidget {
  const ExpiryHomeScreen({super.key});

  @override
  State<ExpiryHomeScreen> createState() => _ExpiryHomeScreenState();
}

class _ExpiryHomeScreenState extends State<ExpiryHomeScreen> with SingleTickerProviderStateMixin {
  final ExpiryController _controller = ExpiryController();
  late TabController _tabController;
  List<Map<String, dynamic>> _medicines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMedicines(0); // default to expired tab
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _loadMedicines(_tabController.index);
      }
    });
  }

  void _loadMedicines(int tabIndex) async {
    setState(() => _loading = true);
    List<Map<String, dynamic>> meds;

    switch (tabIndex) {
      case 0:
        meds = await _controller.getExpiredMedicines();
        break;
      case 1:
        meds = await _controller.getExpiringInDays(7);
        break;
      case 2:
        meds = await _controller.getExpiringInDays(15);
        break;
      case 3:
        meds = await _controller.getExpiringInDays(30);
        break;
      default:
        meds = [];
    }

    setState(() {
      _medicines = meds;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Icon _getStatusIcon(DateTime expiryDate) {
    final now = DateTime.now();
    if (expiryDate.isBefore(now)) {
      return const Icon(Icons.warning, color: Colors.red);
    } else {
      return const Icon(Icons.warning_amber, color: Colors.orange);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expiry Alerts"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: "Expired"),
            Tab(text: "In 7 Days"),
            Tab(text: "In 15 Days"),
            Tab(text: "In 30 Days"),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _medicines.isEmpty
          ? const Center(child: Text("No medicines found."))
          : ListView.builder(
        itemCount: _medicines.length,
        itemBuilder: (context, index) {
          final med = _medicines[index];
          final medicineData = _medicines[index]; // ✅ Define it here
          final expiry = DateTime.parse(medicineData['expiryDate']);
          final formattedDate = DateFormat('dd MMM yyyy').format(expiry);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: _getStatusIcon(expiry),
              title: Text(med['name'] ?? 'Unnamed'),
              subtitle: Text("Expiry: $formattedDate"),
            ),
          );
        },
      ),
    );
  }
}
