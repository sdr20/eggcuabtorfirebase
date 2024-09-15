import 'package:firebase_database/firebase_database.dart';

class EggBatch {
  final String id;
  final String name;
  final int amount;
  final DateTime creationDate;

  EggBatch({
    required this.id,
    required this.name,
    required this.amount,
    required this.creationDate,
  });

  // Convert to Firebase-compatible map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'creationDate': creationDate.toIso8601String(),
    };
  }

  // Create EggBatch object from Firebase snapshot
  static EggBatch fromSnapshot(DataSnapshot snapshot) {
    final data = snapshot.value as Map<dynamic, dynamic>?;

    if (data == null) {
      throw Exception('Snapshot data is null');
    }

    // Handle null or invalid 'creationDate'
    DateTime creationDate;
    if (data['creationDate'] != null) {
      try {
        creationDate = DateTime.parse(data['creationDate'] as String);
      } catch (e) {
        print('Invalid date format for batch ${snapshot.key}: $e');
        creationDate = DateTime.now();  // Use current date if parsing fails
      }
    } else {
      print('creationDate is null for batch ${snapshot.key}, defaulting to current date.');
      creationDate = DateTime.now();  // Handle null date by using current date
    }

    return EggBatch(
      id: snapshot.key ?? '',
      name: data['name'] as String? ?? 'Unnamed Batch',
      amount: (data['amount'] as int?) ?? 0,
      creationDate: creationDate,
    );
  }
}
