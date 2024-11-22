import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'batch_analytics_screen.dart';
import 'sensor_data_provider.dart';
import 'egg_batch.dart';

class EggBatchesScreen extends StatefulWidget {
  @override
  _EggBatchesScreenState createState() => _EggBatchesScreenState();
}

class _EggBatchesScreenState extends State<EggBatchesScreen> {
  final DatabaseReference _batchesRef = FirebaseDatabase.instance.ref().child('egg_batches');
  List<EggBatch> _batches = [];
  late StreamSubscription<DatabaseEvent> _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = _batchesRef.onValue.listen((DatabaseEvent event) {
      if (!mounted) return;

      List<EggBatch> newBatches = [];
      for (var snapshot in event.snapshot.children) {
        try {
          newBatches.add(EggBatch.fromSnapshot(snapshot));
        } catch (e) {
          print('Error parsing snapshot for ${snapshot.key}: $e');
        }
      }
      
      // Debugging output
      print('Fetched ${newBatches.length} batches from Firebase.');

      setState(() {
        _batches = newBatches;
      });
    }, onError: (error) {
      print('Error listening for batch changes: $error');
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _addBatch(String name, int amount) {
    final String batchId = _batchesRef.push().key!;
    final newBatch = EggBatch(
      id: batchId,
      name: name,
      amount: amount,
      creationDate: DateTime.now(),
    );

    _batchesRef.child(batchId).set(newBatch.toMap()).then((_) {
      print('Batch added: ${newBatch.name}');
    }).catchError((error) {
      print('Error adding batch: $error');
    });

    final sensorData = Provider.of<SensorDataProvider>(context, listen: false);
    sensorData.startRecordingForBatch(batchId);
  }

  void _deleteBatch(String batchId) {
    _batchesRef.child(batchId).remove().then((_) {
      print('Batch deleted: $batchId');
    }).catchError((error) {
      print('Error deleting batch: $error');
    });
  }

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
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please provide valid batch details.')),
                  );
                }
              },
              child: Text('Add'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Egg Batches'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: _showAddBatchDialog,
              child: Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  borderRadius: BorderRadius.circular(50.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _batches.isEmpty
          ? Center(child: Text('No batches available.'))
          : ListView.builder(
              itemCount: _batches.length,
              itemBuilder: (context, index) {
                final batch = _batches[index];
                return Card(
                  margin: EdgeInsets.all(10.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 5,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(15.0),
                    title: Text(
                      batch.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(
                      'Amount: ${batch.amount}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BatchAnalyticsScreen(batch: batch),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteBatch(batch.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}