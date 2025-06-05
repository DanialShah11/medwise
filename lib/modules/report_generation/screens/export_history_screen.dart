import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';
import 'package:Medwise/modules/report_generation/models/export_metadata.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExportHistoryScreen extends StatefulWidget {
  const ExportHistoryScreen({super.key});

  @override
  State<ExportHistoryScreen> createState() => _ExportHistoryScreenState();
}

class _ExportHistoryScreenState extends State<ExportHistoryScreen> {
  List<ExportMetadata> history = [];
  List<ExportMetadata> filtered = [];
  final TextEditingController searchController = TextEditingController();
  final Set<int> selectedIndexes = {};
  bool selectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('export_history') ?? [];
    final localHistory = rawList.map((e) => ExportMetadata.fromJson(jsonDecode(e))).toList();

    final user = FirebaseAuth.instance.currentUser;
    List<ExportMetadata> cloudHistory = [];

    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("export_history")
          .orderBy("timestamp", descending: true)
          .get();

      cloudHistory = snapshot.docs.map((doc) {
        final data = doc.data();
        return ExportMetadata.fromJson(data);
      }).toList();
    }

    // Merge cloud + local and remove duplicates by fileName
    final all = <String, ExportMetadata>{};

    for (var item in [...cloudHistory, ...localHistory]) {
      all[item.fileName] = item; // overwrite if duplicate
    }

    setState(() {
      history = all.values.toList();
      filtered = all.values.toList();
    });
  }


  void _search(String query) {
    final q = query.toLowerCase();
    setState(() {
      filtered = history.where((e) => p.basename(e.fileName).toLowerCase().contains(q)).toList();
    });
  }

  Future<void> _deleteSelected() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList('export_history') ?? [];

    // Get fileNames of selected items from the filtered list
    final selectedFiles = selectedIndexes.map((i) => filtered[i].fileName).toSet();

    // Decode rawList and only keep items not selected
    final updatedRawList = rawList.where((e) {
      final data = ExportMetadata.fromJson(jsonDecode(e));
      return !selectedFiles.contains(data.fileName);
    }).map((e) => jsonEncode(jsonDecode(e))).toList();

    await prefs.setStringList('export_history', updatedRawList);

    // Optionally remove from Firestore as well
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("export_history")
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (selectedFiles.contains(data['fileName'])) {
          await doc.reference.delete();
        }
      }
    }

    selectedIndexes.clear();
    selectionMode = false;
    _loadHistory();
  }


  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('export_history');

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("export_history")
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }

    _loadHistory();
  }

  void _toggleSelection(int index) {
    setState(() {
      if (selectedIndexes.contains(index)) {
        selectedIndexes.remove(index);
        if (selectedIndexes.isEmpty) selectionMode = false;
      } else {
        selectedIndexes.add(index);
        selectionMode = true;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      selectedIndexes.clear();
      selectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectionMode
            ? "${selectedIndexes.length} Selected"
            : "Export History"),
        leading: selectionMode
            ? IconButton(
          icon: const Icon(Icons.close),
          onPressed: _exitSelectionMode,
        )
            : null,
        actions: [
          if (selectionMode)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteSelected,
            ),
          if (!selectionMode)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _clearAll,
              tooltip: "Delete All",
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: _search,
              decoration: const InputDecoration(
                hintText: "Search by file name...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text("No export history."))
                : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final item = filtered[index];
                final date = DateFormat.yMMMd().add_jm().format(item.timestamp);
                final isSelected = selectedIndexes.contains(index);

                return ListTile(
                  tileColor: isSelected ? Colors.grey.shade300 : null,
                  leading: selectionMode
                      ? Icon(
                    isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                    color: isSelected ? Colors.blue : null,
                  )
                      : null,
                  title: Text(p.basename(item.fileName)),
                  subtitle: Text("Format: ${item.format} • $date"),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: selectionMode
                      ? () => _toggleSelection(index)
                      : () => OpenFile.open(item.fileName),
                  onLongPress: () => _toggleSelection(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
