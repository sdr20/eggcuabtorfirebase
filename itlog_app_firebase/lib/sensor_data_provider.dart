import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SensorDataProvider extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  
  // Current values
  double _humidity = 0.0;
  double _temperature = 0.0;
  double _maxHumidity = 200.0;
  double _maxTemperature = 36.5;
  double _motorOperationTime = 1.0;
  bool _fanOn = false;

  // Data storage for monthly data
  Map<String, Map<int, List<double>>> _temperatureData = {};
  Map<String, Map<int, List<double>>> _humidityData = {};

  SensorDataProvider() {
    // Listen to real-time updates for humidity and temperature
    _database.child('sensor_data/humidity').onValue.listen((event) {
      if (event.snapshot.value != null) {
        _humidity = (event.snapshot.value as num).toDouble();
        _addHumidityDataForCurrentMonth(_humidity);
        print('Humidity updated: $_humidity');
        notifyListeners();
      } else {
        print('No humidity data');
      }
    }, onError: (error) {
      print('Error fetching humidity data: $error');
    });

    _database.child('sensor_data/temperature').onValue.listen((event) {
      if (event.snapshot.value != null) {
        _temperature = (event.snapshot.value as num).toDouble();
        _addTemperatureDataForCurrentMonth(_temperature);
        print('Temperature updated: $_temperature');
        notifyListeners();
      } else {
        print('No temperature data');
      }
    }, onError: (error) {
      print('Error fetching temperature data: $error');
    });

    // Other Firebase listeners for settings and controls
    _database.child('settings/maxHumidity').onValue.listen((event) {
      if (event.snapshot.value != null) {
        _maxHumidity = (event.snapshot.value as num).toDouble();
        print('Max Humidity updated: $_maxHumidity');
        notifyListeners();
      } else {
        print('No max humidity data');
      }
    }, onError: (error) {
      print('Error fetching max humidity data: $error');
    });

    _database.child('settings/maxTemperature').onValue.listen((event) {
      if (event.snapshot.value != null) {
        _maxTemperature = (event.snapshot.value as num).toDouble();
        print('Max Temperature updated: $_maxTemperature');
        notifyListeners();
      } else {
        print('No max temperature data');
      }
    }, onError: (error) {
      print('Error fetching max temperature data: $error');
    });

    _database.child('control/motorOperationTime').onValue.listen((event) {
      if (event.snapshot.value != null) {
        _motorOperationTime = (event.snapshot.value as num).toDouble();
        print('Motor Operation Time updated: $_motorOperationTime');
        notifyListeners();
      } else {
        print('No motor operation time data');
      }
    }, onError: (error) {
      print('Error fetching motor operation time data: $error');
    });

    _database.child('control/fanOn').onValue.listen((event) {
      if (event.snapshot.value != null) {
        _fanOn = event.snapshot.value as bool;
        print('Fan status updated: $_fanOn');
        notifyListeners();
      } else {
        print('No fan status data');
      }
    }, onError: (error) {
      print('Error fetching fan status data: $error');
    });
  }

  // Getters for the current values
  double get humidity => _humidity;
  double get temperature => _temperature;
  double get maxHumidity => _maxHumidity;
  double get maxTemperature => _maxTemperature;
  double get motorOperationTime => _motorOperationTime;
  bool get fanOn => _fanOn;

  // Update methods for settings and controls
  void updateMaxHumidity(double value) {
    _maxHumidity = value;
    _database.child('settings/maxHumidity').set(value).then((_) {
      print('Max Humidity set to $value');
    }).catchError((error) {
      print('Error setting max humidity: $error');
    });
    notifyListeners();
  }

  void updateMaxTemperature(double value) {
    _maxTemperature = value;
    _database.child('settings/maxTemperature').set(value).then((_) {
      print('Max Temperature set to $value');
    }).catchError((error) {
      print('Error setting max temperature: $error');
    });
    notifyListeners();
  }

  void updateMotorOperationTime(double value) {
    _motorOperationTime = value;
    _database.child('control/motorOperationTime').set(value).then((_) {
      print('Motor Operation Time set to $value');
    }).catchError((error) {
      print('Error setting motor operation time: $error');
    });
    notifyListeners();
  }

  void updateFanOn(bool value) {
    _fanOn = value;
    _database.child('control/fanOn').set(value).then((_) {
      print('Fan status set to $value');
    }).catchError((error) {
      print('Error setting fan status: $error');
    });
    notifyListeners();
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

  // Retrieve batch temperature data for a specific year
  Map<int, List<double>> getBatchTemperatureData(String month) {
    return _temperatureData[month] ?? {};
  }

  // Retrieve batch humidity data for a specific year
  Map<int, List<double>> getBatchHumidityData(String month) {
    return _humidityData[month] ?? {};
  }

  // Color scheme based on temperature values
  Color getTemperatureColor(double temp) {
    if (temp > _maxTemperature) {
      return Colors.red;
    } else if (temp < _maxTemperature * 0.8) {
      return Colors.blue;
    } else {
      return Colors.orange;
    }
  }

  // Color scheme based on humidity values
  Color getHumidityColor(double humid) {
    if (humid > _maxHumidity) {
      return Colors.red;
    } else if (humid < _maxHumidity * 0.8) {
      return Colors.blue;
    } else {
      return Colors.green;
    }
  }
}
