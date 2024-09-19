import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'batch_analytics_screen.dart'; // Ensure correct import for BatchAnalyticsScreen
import 'sensor_data_provider.dart'; // Import the provider for sensor data
import 'egg_batch.dart'; // Correct import for EggBatch

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
          print('Error parsing snapshot: $e');
        }
      }
      setState(() {
        _batches = newBatches;
      });
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
    _batchesRef.child(batchId).set(newBatch.toMap());

    final sensorData = Provider.of<SensorDataProvider>(context, listen: false);
    sensorData.addBatchTemperatureData(batchId, newBatch.creationDate.millisecondsSinceEpoch.toDouble());
    sensorData.addBatchHumidityData(batchId, newBatch.creationDate.millisecondsSinceEpoch.toDouble());
  }

  void _deleteBatch(String batchId) {
    _batchesRef.child(batchId).remove();
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

                if (name.isNotEmpty) {
                  _addBatch(name, amount);
                }

                Navigator.of(context).pop();
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
      //title: Text('Egg Batches'),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: _showAddBatchDialog,
            child: Container(
              padding: EdgeInsets.all(8.0), // Padding inside the button
              decoration: BoxDecoration(
                color: Colors.white, // Background color of the button
                borderRadius: BorderRadius.circular(8.0), // Rounded corners
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3), // Shadow position
                  ),
                ],
              ),
              child: Icon(
                Icons.add,
                color: Colors.blue, // Color of the add icon
              ),
            ),
          ),
        ),
      ],
    ),
    body: ListView.builder(
      itemCount: _batches.length,
      itemBuilder: (context, index) {
        final batch = _batches[index];
        return Container(
          margin: EdgeInsets.all(10.0), // Adds spacing around each batch container
          padding: EdgeInsets.all(15.0), // Adds padding inside the container
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: Offset(0, 3), // changes position of the shadow
              ),
            ],
          ),
          child: ListTile(
            title: Text(batch.name),
            subtitle: Text('Amount: ${batch.amount}'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BatchAnalyticsScreen(batch: batch),
                ),
              );
            },
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _deleteBatch(batch.id),
            ),
          ),
        );
      },
    ),
  );
}

}
