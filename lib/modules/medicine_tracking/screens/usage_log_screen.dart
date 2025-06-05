import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/usage_log_model.dart';

class UsageLogScreen extends StatefulWidget {
  const UsageLogScreen({super.key});

  @override
  State<UsageLogScreen> createState() => _UsageLogScreenState();
}

class _UsageLogScreenState extends State<UsageLogScreen> {
  List<UsageLog> logs = [];
  List<UsageLog> originalLogs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('usage_logs')
        .orderBy('date', descending: true)
        .get();

    final loaded = snapshot.docs.map((doc) => UsageLog.fromMap(doc.data(), doc.id)).toList();
    setState(() {
      logs = loaded;
      originalLogs = loaded;
    });
  }

  void _filterLogs(String query) {
    final term = query.toLowerCase();
    setState(() {
      if (term.isEmpty) {
        logs = List.from(originalLogs);
      } else {
        logs = originalLogs
            .where((log) => log.medicineName.toLowerCase().contains(term))
            .toList();
      }
    });
  }
  void _confirmClearLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All Logs"),
        content: const Text("Are you sure you want to permanently delete all usage logs?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllLogs();
            },
            child: const Text(
              "Delete All",
              style: TextStyle(color: Colors.white), // 🔴 Set text color
            ),


          ),
        ],
      ),
    );
  }
  Future<void> _clearAllLogs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final logRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('usage_logs');

    final snapshot = await logRef.get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }

    setState(() {
      logs.clear();
      originalLogs.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All usage logs deleted.")),
    );
  }

  Widget _buildLogCard(UsageLog log) {
    IconData icon;
    Color color;

    switch (log.reason.toLowerCase()) {
      case "expired":
        icon = Icons.warning_amber;
        color = Colors.deepOrange;
        break;
      case "wasted":
        icon = Icons.delete_forever;
        color = Colors.grey;
        break;
      default:
        icon = Icons.local_pharmacy;
        color = Colors.green;
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          "${log.medicineName} – ${log.quantityUsed} used",
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          "${log.reason} on ${DateFormat.yMMMd().add_jm().format(log.date)}",
        ),
        trailing: log.userEmail != null
            ? Tooltip(message: log.userEmail, child: const Icon(Icons.person, size: 20))
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medicine Usage Log"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: "Clear All Logs",
            onPressed: _confirmClearLogs,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              onChanged: _filterLogs,
              decoration: InputDecoration(
                hintText: "Search by medicine name...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: logs.isEmpty
                  ? const Center(child: Text("No usage logs found"))
                  : ListView.builder(
                itemCount: logs.length,
                itemBuilder: (context, index) => _buildLogCard(logs[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
