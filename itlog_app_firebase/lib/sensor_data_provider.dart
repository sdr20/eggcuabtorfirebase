import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'egg_batch.dart'; // Import EggBatch

class SensorDataProvider extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Current sensor values
  double _humidity = 0.0;
  double _temperature = 0.0;
  double _maxHumidity = 200.0;
  double _maxTemperature = 36.5;
  double _motorOperationTime = 1.0;
  bool _fanOn = false;

  // Data storage for monthly data
  Map<String, Map<int, List<double>>> _temperatureData = {};
  Map<String, Map<int, List<double>>> _humidityData = {};

  // Data storage for egg batches
  List<EggBatch> _eggBatches = [];
  // Store active batches to control recording
  Set<String> _activeBatches = {};

  SensorDataProvider() {
    // Using a shared method to reduce redundancy in database listeners
    _databaseListener('sensor_data/humidity', (newValue) {
      if (_humidity != newValue) {
        _humidity = newValue;
        _addHumidityDataForCurrentMonth(_humidity);
        notifyListeners();
        _storeBatchDataForToday();
      }
    });

    _databaseListener('sensor_data/temperature', (newValue) {
      if (_temperature != newValue) {
        _temperature = newValue;
        _addTemperatureDataForCurrentMonth(_temperature);
        notifyListeners();
        _storeBatchDataForToday();
      }
    });

    // Other Firebase listeners for settings and controls
    _database.child('settings/maxHumidity').onValue.listen((event) {
      if (event.snapshot.value != null) {
        _maxHumidity = (event.snapshot.value as num).toDouble();
        notifyListeners();
      }
    });

    _database.child('settings/maxTemperature').onValue.listen((event) {
      if (event.snapshot.value != null) {
        _maxTemperature = (event.snapshot.value as num).toDouble();
        notifyListeners();
      }
    });

    _database.child('control/motorOperationTime').onValue.listen((event) {
      if (event.snapshot.value != null) {
        _motorOperationTime = (event.snapshot.value as num).toDouble();
        notifyListeners();
      }
    });

    _database.child('control/fanOn').onValue.listen((event) {
      if (event.snapshot.value != null) {
        _fanOn = event.snapshot.value as bool;
        notifyListeners();
      }
    });

    // Fetch egg batches when initializing the provider
    _fetchEggBatches();
  }

  // Reduce redundancy by using a common database listener method
  void _databaseListener(String path, Function(double) onValue) {
    _database.child(path).onValue.listen((event) {
      if (event.snapshot.value != null) {
        final newValue = (event.snapshot.value as num).toDouble();
        onValue(newValue);
      }
    });
  }

  // Fetch egg batches from Firebase
  void _fetchEggBatches() {
    _database.child('egg_batches').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> batchesMap = event.snapshot.value as Map<dynamic, dynamic>;

        _eggBatches.clear();

        batchesMap.forEach((key, value) {
          final batchData = value as Map<dynamic, dynamic>;

          if (batchData['creationDate'] != null) {
            final String id = batchData['id']?.toString() ?? 'Unknown';
            final String name = batchData['name']?.toString() ?? 'Unnamed Batch';
            final int amount = batchData['amount'] != null ? batchData['amount'] as int : 0;

            DateTime creationDate;
            try {
              creationDate = DateTime.parse(batchData['creationDate'].toString());
            } catch (e) {
              print('Invalid date format for batch $id: $e');
              creationDate = DateTime.now();
            }

            final eggBatch = EggBatch(
              id: id,
              name: name,
              amount: amount,
              creationDate: creationDate,
            );
            _eggBatches.add(eggBatch);
          } else {
            print('Batch $key does not have a creationDate and was skipped.');
          }
        });

        notifyListeners();
      }
    });
  }

  // Getters for the current values
  double get humidity => _humidity;
  double get temperature => _temperature;
  double get maxHumidity => _maxHumidity;
  double get maxTemperature => _maxTemperature;
  double get motorOperationTime => _motorOperationTime;
  bool get fanOn => _fanOn;

  // Getter to retrieve the egg batches
  List<EggBatch> get eggBatches => _eggBatches;

  // Get batch by id safely (returns null if not found)
  EggBatch? getBatchById(String id) {
    try {
      return _eggBatches.firstWhere((batch) => batch.id == id);
    } catch (e) {
      print('Batch not found for ID: $id');
      return null;
    }
  }

  // **NEW**: Start recording for a specific batch
  void startRecordingForBatch(String batchId) {
    print('Started recording for batch: $batchId');
    _activeBatches.add(batchId);
    _storeBatchDataForToday();
  }

  // **NEW**: Stop recording for a specific batch
  void stopRecordingForBatch(String batchId) {
    print('Stopped recording for batch: $batchId');
    _activeBatches.remove(batchId);
  }

  // Update methods for settings and controls
  void updateMaxHumidity(double value) {
    _maxHumidity = value;
    _database.child('settings/maxHumidity').set(value).then((_) {
      notifyListeners();
    }).catchError((error) {
      print('Error setting max humidity: $error');
    });
  }

  void updateMaxTemperature(double value) {
    _maxTemperature = value;
    _database.child('settings/maxTemperature').set(value).then((_) {
      notifyListeners();
    }).catchError((error) {
      print('Error setting max temperature: $error');
    });
  }

  void updateMotorOperationTime(double value) {
    _motorOperationTime = value;
    _database.child('control/motorOperationTime').set(value).then((_) {
      notifyListeners();
    }).catchError((error) {
      print('Error setting motor operation time: $error');
    });
  }

  void updateFanOn(bool value) {
    _fanOn = value;
    _database.child('control/fanOn').set(value).then((_) {
      notifyListeners();
    }).catchError((error) {
      print('Error setting fan status: $error');
    });
  }

  // Add temperature data to the current month
  void _addTemperatureDataForCurrentMonth(double temp) {
    final String currentMonth = DateTime.now().month.toString();
    final int currentYear = DateTime.now().year;

    _temperatureData.putIfAbsent(currentMonth, () => {});
    _temperatureData[currentMonth]!.putIfAbsent(currentYear, () => []);
    _temperatureData[currentMonth]![currentYear]!.add(temp);

    print('Added temperature data: $temp for $currentMonth/$currentYear');
  }

  // Add humidity data to the current month
  void _addHumidityDataForCurrentMonth(double humid) {
    final String currentMonth = DateTime.now().month.toString();
    final int currentYear = DateTime.now().year;

    _humidityData.putIfAbsent(currentMonth, () => {});
    _humidityData[currentMonth]!.putIfAbsent(currentYear, () => []);
    _humidityData[currentMonth]![currentYear]!.add(humid);

    print('Added humidity data: $humid for $currentMonth/$currentYear');
  }

  // Retrieve temperature data for a specific month and year
  List<double> getTemperatureDataForMonth(String month, int year) {
    return _temperatureData[month]?[year] ?? [];
  }

  // Retrieve humidity data for a specific month and year
  List<double> getHumidityDataForMonth(String month, int year) {
    return _humidityData[month]?[year] ?? [];
  }

  // **NEW: Retrieve historical temperature data for a specific batch**
  Future<List<double>> getBatchTemperatureData(String batchId, {int limit = 30}) async {
    try {
      final snapshot = await _database.child('batch_data/$batchId/temperature')
          .orderByKey().limitToLast(limit).get();
      if (snapshot.exists && snapshot.value is Map<dynamic, dynamic>) {
        final dataMap = snapshot.value as Map<dynamic, dynamic>;
        return dataMap.values.map((value) => (value as num).toDouble()).toList();
      }
    } catch (error) {
      _logError('Error retrieving temperature data', error);
    }
    return [];
  }

  // **NEW: Retrieve historical humidity data for a specific batch**
  Future<List<double>> getBatchHumidityData(String batchId, {int limit = 30}) async {
    try {
      final snapshot = await _database.child('batch_data/$batchId/humidity')
          .orderByKey().limitToLast(limit).get();
      if (snapshot.exists && snapshot.value is Map<dynamic, dynamic>) {
        final dataMap = snapshot.value as Map<dynamic, dynamic>;
        return dataMap.values.map((value) => (value as num).toDouble()).toList();
      }
    } catch (error) {
      _logError('Error retrieving humidity data', error);
    }
    return [];
  }

  // Retrieve latest temperature for a specific batch
  Future<double?> getLatestBatchTemperature(String batchId) async {
    try {
      final snapshot = await _database.child('batch_data/$batchId/temperature')
          .orderByKey().limitToLast(1).get();
      if (snapshot.exists && snapshot.value is Map<dynamic, dynamic>) {
        final dataMap = snapshot.value as Map<dynamic, dynamic>;
        return (dataMap.values.first as num).toDouble();
      }
    } catch (error) {
      _logError('Error retrieving latest temperature', error);
    }
    return null;
  }

  // Retrieve latest humidity for a specific batch
  Future<double?> getLatestBatchHumidity(String batchId) async {
    try {
      final snapshot = await _database.child('batch_data/$batchId/humidity')
          .orderByKey().limitToLast(1).get();
      if (snapshot.exists && snapshot.value is Map<dynamic, dynamic>) {
        final dataMap = snapshot.value as Map<dynamic, dynamic>;
        return (dataMap.values.first as num).toDouble();
      }
    } catch (error) {
      _logError('Error retrieving latest humidity', error);
    }
    return null;
  }

  // Store today's batch data in the database
  void _storeBatchDataForToday() {
    DateTime now = DateTime.now();
    String todayKey = '${now.year}-${now.month}-${now.day}';

    for (var batch in _eggBatches) {
      // Only store data if the batch is active
      if (_activeBatches.contains(batch.id)) {
        _database.child('batch_data/${batch.id}/temperature/$todayKey').set(_temperature);
        _database.child('batch_data/${batch.id}/humidity/$todayKey').set(_humidity);
        print('Stored data for batch ${batch.id}: Temperature: $_temperature, Humidity: $_humidity');
      }
    }
  }

  // Prune old data older than 30 days
  void _pruneOldData() {
    final DateTime now = DateTime.now();
    final DateTime cutoffDate = now.subtract(Duration(days: 30));

    _temperatureData.removeWhere((month, yearMap) {
      yearMap.removeWhere((year, data) {
        return year < cutoffDate.year || (year == cutoffDate.year && int.parse(month) < cutoffDate.month);
      });
      return yearMap.isEmpty;
    });

    _humidityData.removeWhere((month, yearMap) {
      yearMap.removeWhere((year, data) {
        return year < cutoffDate.year || (year == cutoffDate.year && int.parse(month) < cutoffDate.month);
      });
      return yearMap.isEmpty;
    });

    print('Pruned old data older than 30 days.');
  }

  // Error logging utility
  void _logError(String message, dynamic error) {
    print('$message: $error');
  }
}
