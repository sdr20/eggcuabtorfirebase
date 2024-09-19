import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'sensor_data_provider.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HumidityLogScreen extends StatefulWidget {
  @override
  _HumidityLogScreenState createState() => _HumidityLogScreenState();
}

class _HumidityLogScreenState extends State<HumidityLogScreen> {
  String selectedInterval = 'Per Day'; // Default interval
  DateTime selectedDate = DateTime.now(); // Real-time date
  late DateTime previousDate; // Tracks the previous date for day change detection
  late Timer _timer;
  Map<String, Map<int, double>> humidityData = {}; // Storing data for all intervals
  List<FlSpot> humiditySpots = [];
  late SensorDataProvider sensorData;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    sensorData = Provider.of<SensorDataProvider>(context, listen: false);
    _loadDataLocally(); // Load historical data

    // Set the initial previous date to the current date
    previousDate = DateTime.now();

    // Periodic updates based on real-time clock
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      DateTime now = DateTime.now();

      // Detect if the day has changed
      if (now.day != previousDate.day) {
        setState(() {
          selectedDate = now;
          previousDate = now; // Update previous date to current day
        });

        // Initialize new day data
        _initializeNewDayData(now);

        // Clear previous data to avoid mixing with new day's data
        humiditySpots.clear();
      }

      setState(() {
        _updateHumidityData();
        _updateFilteredData();
        _saveDataLocally(); // Save historical data
      });
    });
  }

  void _initializeNewDayData(DateTime now) {
    // Create a new entry for the new day
    String intervalKey = _getIntervalKeyForDay(now);
    if (humidityData[intervalKey] == null) {
      humidityData[intervalKey] = {};
    }
  }

  void _updateHumidityData() {
    DateTime now = DateTime.now();
    String intervalKey = _getIntervalKey();
    double currentHumidity = sensorData.humidity;

    if (humidityData[intervalKey] == null) {
      humidityData[intervalKey] = {};
    }

    int key = _getDataKey(now); // Get data key based on current time
    humidityData[intervalKey]![key] = currentHumidity;
  }

  void _updateFilteredData() {
    String intervalKey = _getIntervalKey();
    Map<int, double>? dataForInterval = humidityData[intervalKey];

    if (dataForInterval != null) {
      humiditySpots = dataForInterval.entries
          .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
          .toList();
    } else {
      humiditySpots = [];
    }

    humiditySpots.sort((a, b) => a.x.compareTo(b.x));
  }

  void _saveDataLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, List<Map<String, double>>> serializedData = humidityData.map((key, value) {
      return MapEntry(
        key,
        value.entries.map((e) => {"x": e.key.toDouble(), "y": e.value}).toList(),
      );
    });

    String jsonString = jsonEncode(serializedData);
    await prefs.setString('humidityData', jsonString);
  }

  void _loadDataLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('humidityData');

    if (jsonString != null) {
      Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      setState(() {
        humidityData = jsonMap.map((key, value) {
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
    DateTime now = DateTime.now(); // Get real-time month and year
    return "${now.month}-${now.year}-$selectedInterval-${selectedDate.day}";
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

  double _getMaxYForInterval() {
    // Set max Y value to 100
    return 100;
  }

  Future<void> _selectDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        _updateFilteredData();
        _saveDataLocally();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    sensorData = Provider.of<SensorDataProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Humidity Log')),
      body: Column(
        children: [
          _buildLiveHumidityDisplay(), // Live Humidity Display
          _buildIntervalDropdown(),
          if (selectedInterval == 'Per Minute') _buildDatePickerButton(), // Show date picker button only for 'Per Minute'
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _scrollController,
              physics: BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.all(8.0),
                child: humiditySpots.isEmpty
                    ? Center(child: Text('No data available for the selected period.'))
                    : SizedBox(
                        width: _getMaxXForInterval() * 20, // Adjust width as needed
                        child: LineChart(
                          LineChartData(
                            lineBarsData: [
                              LineChartBarData(
                                spots: humiditySpots,
                                isCurved: true,
                                color: const Color.fromRGBO(192, 108, 132, 1), // Line color
                                barWidth: 3, // Line width
                                dotData: FlDotData(show: true), // Show dots
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: const Color.fromRGBO(192, 108, 132, 0.3), // Area color
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
                                      child: Text('${value.toInt()}%'),
                                    );
                                  },
                                ),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(
                                color: const Color.fromRGBO(0, 0, 0, 0.1),
                                width: 1,
                              ),
                            ),
                            minX: 0,
                            maxX: _getMaxXForInterval(),
                            minY: 30, // Set min Y value to 30
                            maxY: _getMaxYForInterval(), // Set max Y value to 100
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

  Widget _buildLiveHumidityDisplay() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Current Humidity: ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '${sensorData.humidity.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 18, color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildIntervalDropdown() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Interval: ', style: TextStyle(fontSize: 16)),
          DropdownButton<String>(
            value: selectedInterval,
            items: ['Per Minute', 'Per Day', 'Per Week', 'Per Month']
                .map((interval) => DropdownMenuItem<String>(
                      value: interval,
                      child: Text(interval),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() {
                selectedInterval = value!;
                _updateFilteredData();
                // Reset to current day when interval changes
                selectedDate = DateTime.now();
                _updateFilteredData();
                _saveDataLocally();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerButton() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Select Date: ', style: TextStyle(fontSize: 16)),
          ElevatedButton(
            onPressed: _selectDate,
            child: Text(
              '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
