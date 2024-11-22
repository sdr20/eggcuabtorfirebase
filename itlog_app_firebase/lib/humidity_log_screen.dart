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
  DateTime selectedDate = DateTime.now();
  late Timer _timer;
  Map<String, Map<int, double>> humidityData = {};
  List<FlSpot> humiditySpots = [];
  late SensorDataProvider sensorData;

  @override
  void initState() {
    super.initState();
    sensorData = Provider.of<SensorDataProvider>(context, listen: false);
    _loadDataLocally();
    _initializeTimer();
  }

  void _initializeTimer() {
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      DateTime now = DateTime.now();
      _updateHumidityData(now);
      _updateFilteredData();
      _saveDataLocally();
    });
  }

  void _updateHumidityData(DateTime now) {
    double currentHumidity = sensorData.humidity;
    String intervalKey = _getIntervalKey();

    if (humidityData[intervalKey] == null) {
      humidityData[intervalKey] = {};
    }

    int key = _getDataKey(now);
    humidityData[intervalKey]![key] = currentHumidity;
  }

  void _updateFilteredData() {
    String intervalKey = _getIntervalKey();
    Map<int, double>? dataForInterval = humidityData[intervalKey];

    humiditySpots = dataForInterval?.entries
            .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
            .toList() ??
        [];
    humiditySpots.sort((a, b) => a.x.compareTo(b.x));
  }

  void _saveDataLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(humidityData);
    await prefs.setString('humidityData', jsonString);
  }

  void _loadDataLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('humidityData');

    if (jsonString != null) {
      Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      setState(() {
        humidityData = jsonMap.map((key, value) {
          Map<int, double> spotMap = Map.from(value);
          return MapEntry(key, spotMap);
        });
        _updateFilteredData();
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getIntervalKey() {
    DateTime now = DateTime.now();
    return "${now.month}-${now.year}-$selectedInterval";
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

  double _getMaxYForInterval() {
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
      appBar: AppBar(
        title: Text('Humidity Log'),
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLiveHumidityDisplay(),
            SizedBox(height: 16),
            _buildIntervalDropdown(),
            SizedBox(height: 16),
            if (selectedInterval == 'Per Minute') _buildDatePicker(),
            Expanded(
              child: _buildHumidityChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveHumidityDisplay() {
    return Card(
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Current Humidity:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              '${sensorData.humidity.toStringAsFixed(1)} %',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntervalDropdown() {
    return DropdownButton<String>(
      value: selectedInterval,
      items: <String>['Per Minute', 'Per Day', 'Per Week', 'Per Month']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          selectedInterval = newValue!;
          _updateFilteredData();
        });
      },
    );
  }

  Widget _buildDatePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text("Select Date:"),
        SizedBox(width: 10),
        ElevatedButton(
          onPressed: _selectDate,
          child: Text("${selectedDate.toLocal()}".split(' ')[0]),
        ),
      ],
    );
  }

  Widget _buildHumidityChart() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: humiditySpots.isEmpty
          ? Center(child: Text('No data available for the selected period.'))
          : LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: humiditySpots,
                    isCurved: true,
                    color: Colors.pinkAccent,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.pinkAccent.withOpacity(0.3),
                    ),
                  ),
                ],
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4.0,
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4.0,
                          child: Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.pinkAccent, width: 1),
                ),
                minX: humiditySpots.isNotEmpty ? humiditySpots.first.x : 0,
                maxX: humiditySpots.isNotEmpty ? humiditySpots.last.x : 1,
                minY: 0,
                maxY: _getMaxYForInterval(),
              ),
            ),
    );
  }
}