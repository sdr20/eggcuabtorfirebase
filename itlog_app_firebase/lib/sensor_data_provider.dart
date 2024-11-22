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
  double _motorOperationTime = 1.0; // Start with 1 hour

  // Data storage for monthly data
  Map<String, Map<int, List<double>>> _temperatureData = {};
  Map<String, Map<int, List<double>>> _humidityData = {};

  // Data storage for egg batches
  List<EggBatch> _eggBatches = [];
  Set<String> _activeBatches = {};

  SensorDataProvider() {
    _initializeListeners();
    _fetchEggBatches();
  }

  void _initializeListeners() {
    _createDatabaseListener('sensor_data/humidity', (newValue) {
      if (_humidity != newValue) {
        _humidity = newValue;
        _addHumidityDataForCurrentMonth(_humidity);
        notifyListeners();
        _storeBatchDataForToday();
      }
    });

    _createDatabaseListener('sensor_data/temperature', (newValue) {
      if (_temperature != newValue) {
        _temperature = newValue;
        _addTemperatureDataForCurrentMonth(_temperature);
        notifyListeners();
        _storeBatchDataForToday();
      }
    });

    _createDatabaseListener('settings/maxHumidity', (newValue) {
      _maxHumidity = newValue;
      notifyListeners();
    });

    _createDatabaseListener('settings/maxTemperature', (newValue) {
      _maxTemperature = newValue;
      notifyListeners();
    });

    _createDatabaseListener('control/motorOperationTime', (newValue) {
      _setMotorOperationTimeFromMilliseconds(newValue);
    });
  }

  void _createDatabaseListener(String path, Function(double) onValue) {
    _database.child(path).onValue.listen((event) {
      if (event.snapshot.value != null) {
        final newValue = (event.snapshot.value as num).toDouble();
        onValue(newValue);
      }
    }).onError((error) {
      _logError('Error listening to $path', error);
    });
  }

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
            final int amount = batchData['amount'] as int? ?? 0;

            DateTime creationDate;
            try {
              creationDate = DateTime.parse(batchData['creationDate'].toString());
            } catch (e) {
              _logError('Invalid date format for batch $id', e);
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
            _logError('Batch $key does not have a creationDate and was skipped.', null);
          }
        });

        notifyListeners();
      } else {
        _logError('No egg batches found.', null);
      }
    }).onError((error) {
      _logError('Error fetching egg batches', error);
    });
  }

  // Getters for current values
  double get humidity => _humidity;
  double get temperature => _temperature;
  double get maxHumidity => _maxHumidity;
  double get maxTemperature => _maxTemperature;
  double get motorOperationTime => _motorOperationTime;

  // Getter to retrieve the egg batches
  List<EggBatch> get eggBatches => _eggBatches;

  // Getter for active batches
  Set<String> get activeBatches => _activeBatches;

  // Get batch by id safely (returns null if not found)
  EggBatch? getBatchById(String id) {
    try {
      return _eggBatches.firstWhere((batch) => batch.id == id);
    } catch (e) {
      _logError('Batch not found for ID: $id', e);
      return null;
    }
  }

  // Start recording for a specific batch
  void startRecordingForBatch(String batchId) {
    _activeBatches.add(batchId);
    _storeBatchDataForToday();
  }

  // Stop recording for a specific batch
  void stopRecordingForBatch(String batchId) {
    _activeBatches.remove(batchId);
  }

  // Update methods for settings and controls
  void updateMaxHumidity(double value) {
    _maxHumidity = value;
    _updateSetting('settings/maxHumidity', value);
  }

  void updateMaxTemperature(double value) {
    _maxTemperature = value;
    _updateSetting('settings/maxTemperature', value);
  }

  void updateMotorOperationTime(double value) {
    if (value >= 0 && value <= 12) {
      // Convert from hours back to milliseconds for storage
      _motorOperationTime = value;
      _updateSetting('control/motorOperationTime', value * 1000 * 60 * 60); // Convert to milliseconds
    }
  }

  void _setMotorOperationTimeFromMilliseconds(double milliseconds) {
    _motorOperationTime = milliseconds / (1000 * 60 * 60); // Convert to hours
    if (_motorOperationTime > 12) {
      _motorOperationTime = 12; // Cap to max value
    }
    notifyListeners();
  }

  void _updateSetting(String path, double value) {
    _database.child(path).set(value).then((_) {
      notifyListeners();
    }).catchError((error) {
      _logError('Error setting $path', error);
    });
  }

  // Add temperature data to the current month
  void _addTemperatureDataForCurrentMonth(double temp) {
    final String currentMonth = DateTime.now().month.toString();
    final int currentYear = DateTime.now().year;

    _temperatureData.putIfAbsent(currentMonth, () => {});
    _temperatureData[currentMonth]!.putIfAbsent(currentYear, () => []);
    _temperatureData[currentMonth]![currentYear]!.add(temp);
  }

  // Add humidity data to the current month
  void _addHumidityDataForCurrentMonth(double humid) {
    final String currentMonth = DateTime.now().month.toString();
    final int currentYear = DateTime.now().year;

    _humidityData.putIfAbsent(currentMonth, () => {});
    _humidityData[currentMonth]!.putIfAbsent(currentYear, () => []);
    _humidityData[currentMonth]![currentYear]!.add(humid);
  }

  // Retrieve temperature data for a specific month and year
  List<double> getTemperatureDataForMonth(String month, int year) {
    return _temperatureData[month]?[year] ?? [];
  }

  // Retrieve humidity data for a specific month and year
  List<double> getHumidityDataForMonth(String month, int year) {
    return _humidityData[month]?[year] ?? [];
  }

  // Retrieve historical temperature data for a specific batch
  Future<List<double>> getBatchTemperatureData(String batchId, {int limit = 30}) async {
    return await _retrieveBatchData(batchId, 'temperature');
  }

  // Retrieve historical humidity data for a specific batch
  Future<List<double>> getBatchHumidityData(String batchId, {int limit = 30}) async {
    return await _retrieveBatchData(batchId, 'humidity');
  }

  Future<List<double>> _retrieveBatchData(String batchId, String dataType, {int limit = 30}) async {
    try {
      final snapshot = await _database.child('batch_data/$batchId/$dataType')
          .orderByKey().limitToLast(limit).get();
      if (snapshot.exists && snapshot.value is Map<dynamic, dynamic>) {
        final dataMap = snapshot.value as Map<dynamic, dynamic>;
        return dataMap.values.map((value) => (value as num).toDouble()).toList();
      }
    } catch (error) {
      _logError('Error retrieving $dataType data', error);
    }
    return [];
  }

  // Retrieve latest temperature for a specific batch
  Future<double?> getLatestBatchTemperature(String batchId) async {
    return await _retrieveLatestBatchData(batchId, 'temperature');
  }

  // Retrieve latest humidity for a specific batch
  Future<double?> getLatestBatchHumidity(String batchId) async {
    return await _retrieveLatestBatchData(batchId, 'humidity');
  }

  Future<double?> _retrieveLatestBatchData(String batchId, String dataType) async {
    try {
      final snapshot = await _database.child('batch_data/$batchId/$dataType').orderByKey().limitToLast(1).get();
      if (snapshot.exists) {
        final latestData = (snapshot.value as Map<dynamic, dynamic>).values.first;
        return (latestData as num).toDouble();
      }
    } catch (error) {
      _logError('Error retrieving latest $dataType', error);
    }
    return null;
  }

  // Log errors for debugging
  void _logError(String message, dynamic error) {
    print('$message: $error');
  }

  // Store batch data for today
  void _storeBatchDataForToday() {
    final String today = DateTime.now().toIso8601String().split('T')[0];

    for (String batchId in _activeBatches) {
      _database.child('batch_data/$batchId/$today').set({
        'temperature': _temperature,
        'humidity': _humidity,
      }).then((_) {
        print('Stored batch data for $batchId on $today');
      }).catchError((error) {
        _logError('Error storing batch data for $batchId', error);
      });
    }
  }
}