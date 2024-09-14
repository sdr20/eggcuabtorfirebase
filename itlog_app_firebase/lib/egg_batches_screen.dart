import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async'; // For StreamSubscription
import 'batch_analytics_screen.dart';
import 'sensor_data_provider.dart';

class EggBatch {
  final String id;
  final String name;
  final int amount;

  EggBatch({required this.id, required this.name, required this.amount});

  // Convert to Firebase compatible map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
    };
  }

  // Create EggBatch object from Firebase snapshot
  static EggBatch fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>?;

    if (data == null) {
      throw Exception('Snapshot data is null');
    }

    return EggBatch(
      id: snapshot.key ?? '',
      name: data['name'] as String? ?? '',
      amount: (data['amount'] as int?) ?? 0,
    );
  }
}

class EggBatchesScreen extends StatefulWidget {
  @override
  _EggBatchesScreenState createState() => _EggBatchesScreenState();
}

class _EggBatchesScreenState extends State<EggBatchesScreen> {
  final DatabaseReference _batchesRef =
      FirebaseDatabase.instance.ref().child('egg_batches');
  List<EggBatch> _batches = [];
  late StreamSubscription<DatabaseEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _batchesRef.onValue.listen((DatabaseEvent event) {
      if (!mounted) return; // Check if the widget is still mounted

      List<EggBatch> newBatches = [];
      event.snapshot.children.forEach((snapshot) {
        newBatches.add(EggBatch.fromSnapshot(snapshot));
      });
      setState(() {
        _batches = newBatches;
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel(); // Cancel the subscription when the widget is disposed
    super.dispose();
  }

  // Add new batch to Firebase
  void _addBatch(String name, int amount) {
    final String batchId = _batchesRef.push().key!;
    final newBatch = EggBatch(id: batchId, name: name, amount: amount);
    _batchesRef.child(batchId).set(newBatch.toMap());
  }

  // Delete a batch from Firebase
  void _deleteBatch(String batchId) {
    _batchesRef.child(batchId).remove();
  }

  // Function to show dialog to add batch
  void _showAddBatchDialog() {
    final TextEditingController _nameController = TextEditingController();
    final TextEditingController _amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Egg Batch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Batch Name'),
              ),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Amount of Eggs'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final String name = _nameController.text;
                final int amount = int.tryParse(_amountController.text) ?? 0;

                if (name.isNotEmpty && amount > 0) {
                  _addBatch(name, amount);
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Add Batch'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog without adding
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Navigate to batch analytics screen
  void _goToAnalytics(EggBatch batch) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BatchAnalyticsScreen(batch: batch),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _showAddBatchDialog,
              child: Text('Add New Batch'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _batches.length,
              itemBuilder: (context, index) {
                final batch = _batches[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              batch.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text('Amount: ${batch.amount}'),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.analytics, color: Colors.blue),
                            onPressed: () => _goToAnalytics(batch),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // Show confirmation dialog before deleting
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Delete Batch'),
                                    content: Text('Are you sure you want to delete this batch?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Close the dialog
                                        },
                                        child: Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          _deleteBatch(batch.id);
                                          Navigator.of(context).pop(); // Close the dialog
                                        },
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
