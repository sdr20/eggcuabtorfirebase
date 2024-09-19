import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'sensor_data_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TemperatureLogScreen extends StatefulWidget {
  @override
  _TemperatureLogScreenState createState() => _TemperatureLogScreenState();
}

class _TemperatureLogScreenState extends State<TemperatureLogScreen> {
  String selectedInterval = 'Per Day'; // Default interval
  DateTime selectedDate = DateTime.now(); // Real-time date
  late DateTime previousDate; // Tracks the previous date for day change detection
  int selectedDay = DateTime.now().day; // Default to current day for "Per Minute"
  late Timer _timer;
  Map<String, Map<int, double>> temperatureData = {}; // Storing data for all intervals
  List<FlSpot> temperatureSpots = [];
  late SensorDataProvider sensorData;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    sensorData = Provider.of<SensorDataProvider>(context, listen: false);
    _loadDataLocally();

    // Set the initial previous date to the current date
    previousDate = DateTime.now();

    // Periodic updates based on real-time clock
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      DateTime now = DateTime.now();

      // Detect if the day has changed
      if (now.day != previousDate.day) {
        // Update selectedDay and selectedDate for the new day
        setState(() {
          selectedDay = now.day;
          selectedDate = now;
          previousDate = now; // Update previous date to current day
        });

        // Initialize new day data
        _initializeNewDayData(now);
        
        // Clear previous data to avoid mixing with new day's data
        temperatureSpots.clear();
      }

      setState(() {
        _updateTemperatureData();
        _updateFilteredData();
        _saveDataLocally();
      });
    });
  }

  void _initializeNewDayData(DateTime now) {
    // Create a new entry for the new day
    String intervalKey = _getIntervalKeyForDay(now);
    if (temperatureData[intervalKey] == null) {
      temperatureData[intervalKey] = {};
    }
  }

  void _updateTemperatureData() {
    DateTime now = DateTime.now();
    String intervalKey = _getIntervalKey();
    double currentTemperature = sensorData.temperature;

    if (temperatureData[intervalKey] == null) {
      temperatureData[intervalKey] = {};
    }

    int key = _getDataKey(now); // Get data key based on current time
    temperatureData[intervalKey]![key] = currentTemperature;
  }

  void _updateFilteredData() {
    String intervalKey = _getIntervalKey();
    Map<int, double>? dataForInterval = temperatureData[intervalKey];

    if (dataForInterval != null) {
      temperatureSpots = dataForInterval.entries
          .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
          .toList();
    } else {
      temperatureSpots = [];
    }

    temperatureSpots.sort((a, b) => a.x.compareTo(b.x));
  }

  void _saveDataLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, List<Map<String, double>>> serializedData = temperatureData.map((key, value) {
      return MapEntry(
        key,
        value.entries.map((e) => {"x": e.key.toDouble(), "y": e.value}).toList(),
      );
    });

    String jsonString = jsonEncode(serializedData);
    await prefs.setString('temperatureData', jsonString);
  }

  void _loadDataLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('temperatureData');

    if (jsonString != null) {
      Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      setState(() {
        temperatureData = jsonMap.map((key, value) {
          List<dynamic> spotsList = List<dynamic>.from(value);
          Map<int, double> spotMap = {};
          for (var spot in spotsList) {
            if (spot is Map<String, dynamic>) {
              int x = (spot["x"] as num).toInt();
              double y = (spot["y"] as num).toDouble();
              spotMap[x] = y;
            }
          }
          return MapEntry(key, spotMap);
        });
        _updateFilteredData();
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  String _getIntervalKey() {
    // Use selectedDate instead of real-time DateTime.now() for historical data lookup
    return "${selectedDate.month}-${selectedDate.year}-$selectedInterval-$selectedDay";
  }

  String _getIntervalKeyForDay(DateTime date) {
    // Generate a key for a specific day
    return "${date.month}-${date.year}-$selectedInterval-${date.day}";
  }

  int _getDataKey(DateTime now) {
    switch (selectedInterval) {
      case 'Per Minute':
        return now.hour * 60 + now.minute;
      case 'Per Day':
        return now.day;
      case 'Per Week':
        return now.weekday;
      case 'Per Month':
        return now.month;
      default:
        return now.day;
    }
  }

  double _getMaxXForInterval() {
    switch (selectedInterval) {
      case 'Per Minute':
        return 24 * 60.toDouble(); // 24 hours * 60 minutes
      case 'Per Day':
        return 31.toDouble(); // Max days in a month
      case 'Per Week':
        return 7.toDouble(); // Number of days in a week
      case 'Per Month':
        return 12.toDouble(); // Max 12 months in a year
      default:
        return 31.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    sensorData = Provider.of<SensorDataProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Temperature Log')),
      body: Column(
        children: [
          // Dropdown for interval selection
          _buildIntervalDropdown(),
          _buildLiveTemperatureDisplay(),
          // Date Picker for historical data selection
          _buildDatePicker(),
          
          // Day dropdown for 'Per Minute' selection
          if (selectedInterval == 'Per Minute') _buildDayDropdown(), 
          
          // Expanded section for the chart
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AspectRatio(
                aspectRatio: 1,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: _scrollController,
                  physics: BouncingScrollPhysics(),
                  child: temperatureSpots.isEmpty
                      ? Center(child: Text('No data available for the selected period.'))
                      : SizedBox(
                          width: _getMaxXForInterval() * 20, // Adjust width for scrolling
                          child: LineChart(
                            LineChartData(
                              lineBarsData: [
                                LineChartBarData(
                                  spots: temperatureSpots,
                                  isCurved: true,
                                  color: const Color.fromRGBO(108, 192, 132, 1),
                                  barWidth: 3,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: const Color.fromRGBO(108, 192, 132, 0.3),
                                  ),
                                ),
                              ],
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: true,
                                drawHorizontalLine: true,
                                getDrawingHorizontalLine: (value) {
                                  return FlLine(
                                    color: Colors.grey,
                                    strokeWidth: 0.5,
                                  );
                                },
                              ),
                              titlesData: FlTitlesData(
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 60,
                                    getTitlesWidget: (value, meta) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text('${value.toInt()}'),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 50,
                                    getTitlesWidget: (value, meta) {
                                      return SideTitleWidget(
                                        axisSide: meta.axisSide,
                                        child: Text('${value.toInt()}°C'),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(
                                show: true,
                                border: Border.all(
                                  color: const Color.fromRGBO(0, 0, 0, 0.1),
                                ),
                              ),
                              maxX: _getMaxXForInterval(),
                              minY: 25,   // Start Y-axis at 25°C
                              maxY: 50,   // Set max Y-axis at 50°C
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTemperatureDisplay() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Current Temperature: ',
            style: TextStyle(fontSize: 18),
          ),
          Text(
            '${sensorData.temperature}°C',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalDropdown() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButton<String>(
        value: selectedInterval,
        onChanged: (String? newValue) {
          setState(() {
            selectedInterval = newValue!;
            // Reset to current day when interval changes
            selectedDay = DateTime.now().day;
            selectedDate = DateTime.now();
            _updateFilteredData();
            _saveDataLocally();
          });
        },
        items: <String>['Per Minute', 'Per Day', 'Per Week', 'Per Month']
            .map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
          );
          if (pickedDate != null && pickedDate != selectedDate) {
            setState(() {
              selectedDate = pickedDate;
              _updateFilteredData();
              _saveDataLocally();
            });
          }
        },
        child: Text('Select Date: ${selectedDate.toLocal()}'.split(' ')[0]),
      ),
    );
  }

  Widget _buildDayDropdown() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: DropdownButton<int>(
        value: selectedDay,
        onChanged: (int? newValue) {
          setState(() {
            selectedDay = newValue!;
            _updateFilteredData();
            _saveDataLocally();
          });
        },
        items: List.generate(
          31,
          (index) => DropdownMenuItem<int>(
            value: index + 1,
            child: Text('${index + 1}'),
          ),
        ),
      ),
    );
  }
}
