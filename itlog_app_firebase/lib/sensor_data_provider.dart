import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class SensorDataProvider extends ChangeNotifier {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  double _humidity = 0.0;
  double _temperature = 0.0;
  double _maxHumidity = 200.0;
  double _maxTemperature = 41.9;
  double _motorOperationTime = 1.0;
  bool _fanOn = false;

  SensorDataProvider() {
    _database.child('sensor_data/humidity').onValue.listen((event) {
      if (event.snapshot.value != null) {
        _humidity = (event.snapshot.value as num).toDouble();
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
        print('Temperature updated: $_temperature');
        notifyListeners();
      } else {
        print('No temperature data');
      }
    }, onError: (error) {
      print('Error fetching temperature data: $error');
    });

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

  double get humidity => _humidity;
  double get temperature => _temperature;
  double get maxHumidity => _maxHumidity;
  double get maxTemperature => _maxTemperature;
  double get motorOperationTime => _motorOperationTime;
  bool get fanOn => _fanOn;

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
}
