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

  SensorDataProvider() {
    // Listen to real-time updates for humidity and temperature
    _database.child('sensor_data/humidity').onValue.listen((event) {
      if (event.snapshot.value != null) {
        _humidity = (event.snapshot.value as num).toDouble();
        _addHumidityDataForCurrentMonth(_humidity);
        notifyListeners();
      }
    });

    _database.child('sensor_data/temperature').onValue.listen((event) {
      if (event.snapshot.value != null) {
        _temperature = (event.snapshot.value as num).toDouble();
        _addTemperatureDataForCurrentMonth(_temperature);
        notifyListeners();
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

  // Fetch egg batches from Firebase
  void _fetchEggBatches() {
    _database.child('egg_batches').onValue.listen((event) {
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> batchesMap = event.snapshot.value as Map<dynamic, dynamic>;

        _eggBatches.clear();

        batchesMap.forEach((key, value) {
          final batchData = value as Map<dynamic, dynamic>;

          final String id = (batchData['id'] != null) ? batchData['id'].toString() : 'Unknown';
          final String name = (batchData['name'] != null) ? batchData['name'].toString() : 'Unnamed Batch';
          final int amount = (batchData['amount'] != null) ? batchData['amount'] as int : 0;

          // Handling the creationDate safely
          DateTime creationDate;
          if (batchData['creationDate'] != null) {
            try {
              creationDate = DateTime.parse(batchData['creationDate'].toString());
            } catch (e) {
              print('Invalid date format for batch $id: $e');
              creationDate = DateTime.now(); // Default to current date in case of failure
            }
          } else {
            creationDate = DateTime.now(); // Handle null date by using current date
            print('creationDate is null for batch $id, defaulting to current date.');
          }

          final eggBatch = EggBatch(
            id: id,
            name: name,
            amount: amount,
            creationDate: creationDate,
          );
          _eggBatches.add(eggBatch);
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
  Future<List<double>> getBatchTemperatureData(String batchId) async {
    try {
      final snapshot = await _database.child('batch_data/$batchId/temperature').get();
      if (snapshot.exists && snapshot.value is Map<dynamic, dynamic>) {
        final dataMap = snapshot.value as Map<dynamic, dynamic>;
        return dataMap.values.map((value) => (value as num).toDouble()).toList();
      } else {
        return [];
      }
    } catch (error) {
      print('Error retrieving temperature data: $error');
      return [];
    }
  }

  // Retrieve historical humidity data for a specific batch
  Future<List<double>> getBatchHumidityData(String batchId) async {
    try {
      final snapshot = await _database.child('batch_data/$batchId/humidity').get();
      if (snapshot.exists && snapshot.value is Map<dynamic, dynamic>) {
        final dataMap = snapshot.value as Map<dynamic, dynamic>;
        return dataMap.values.map((value) => (value as num).toDouble()).toList();
      } else {
        return [];
      }
    } catch (error) {
      print('Error retrieving humidity data: $error');
      return [];
    }
  }

  // Retrieve latest temperature for a specific batch
  Future<double> getLatestBatchTemperature(String batchId) async {
    try {
      final snapshot = await _database.child('batch_data/$batchId/temperature').orderByKey().limitToLast(1).get();
      if (snapshot.exists && snapshot.value is Map<dynamic, dynamic>) {
        final dataMap = snapshot.value as Map<dynamic, dynamic>;
        final latestValue = dataMap.values.last as num;
        return latestValue.toDouble();
      } else {
        throw Exception('No temperature data found for batch $batchId');
      }
    } catch (error) {
      print('Error retrieving latest temperature data: $error');
      return 0.0;
    }
  }

  // Retrieve latest humidity for a specific batch
  Future<double> getLatestBatchHumidity(String batchId) async {
    try {
      final snapshot = await _database.child('batch_data/$batchId/humidity').orderByKey().limitToLast(1).get();
      if (snapshot.exists && snapshot.value is Map<dynamic, dynamic>) {
        final dataMap = snapshot.value as Map<dynamic, dynamic>;
        final latestValue = dataMap.values.last as num;
        return latestValue.toDouble();
      } else {
        throw Exception('No humidity data found for batch $batchId');
      }
    } catch (error) {
      print('Error retrieving latest humidity data: $error');
      return 0.0;
    }
  }

  // Add temperature data for a specific batch
  void addBatchTemperatureData(String batchId, double temperature) {
    final batchTemperatureRef = _database.child('batch_data/$batchId/temperature');
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    batchTemperatureRef.child('$timestamp').set(temperature).then((_) {
      print('Temperature data added for batch $batchId: $temperature');
    }).catchError((error) {
      print('Error adding temperature data for batch $batchId: $error');
    });
  }

  // Add humidity data for a specific batch
  void addBatchHumidityData(String batchId, double humidity) {
    final batchHumidityRef = _database.child('batch_data/$batchId/humidity');
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    batchHumidityRef.child('$timestamp').set(humidity).then((_) {
      print('Humidity data added for batch $batchId: $humidity');
    }).catchError((error) {
      print('Error adding humidity data for batch $batchId: $error');
    });
  }
}
