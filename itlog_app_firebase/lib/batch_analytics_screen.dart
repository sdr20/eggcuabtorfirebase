import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'sensor_data_provider.dart';
import 'egg_batch.dart';

class BatchAnalyticsScreen extends StatefulWidget {
  final EggBatch batch;

  BatchAnalyticsScreen({required this.batch});

  @override
  _BatchAnalyticsScreenState createState() => _BatchAnalyticsScreenState();
}

class _BatchAnalyticsScreenState extends State<BatchAnalyticsScreen> {
  late int daysSinceCreation;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _updateDaysSinceCreation();
    _startAutoUpdate();
  }

  void _updateDaysSinceCreation() {
    setState(() {
      daysSinceCreation = DateTime.now().difference(widget.batch.creationDate).inDays + 1;

      // Stop recording data after 25 days
      if (daysSinceCreation >= 25) {
        Provider.of<SensorDataProvider>(context, listen: false).stopRecordingForBatch(widget.batch.id);
      }
    });
  }

  void _startAutoUpdate() {
    // Update every 24 hours
    _timer = Timer.periodic(Duration(days: 1), (timer) {
      _updateDaysSinceCreation();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sensorData = Provider.of<SensorDataProvider>(context);

    // Start recording when the batch is created
    sensorData.startRecordingForBatch(widget.batch.id);

    return Scaffold(
      appBar: AppBar(title: Text('Analytics for ${widget.batch.name}')),
      body: FutureBuilder<Map<String, List<FlSpot>>>(
        future: Future.wait([
          sensorData.getBatchTemperatureData(widget.batch.id),
          sensorData.getBatchHumidityData(widget.batch.id),
        ]).then((results) {
          if (results.isEmpty || results[0].isEmpty || results[1].isEmpty) {
            return <String, List<FlSpot>>{
              'temperature': [],
              'humidity': [],
            };
          }

          final List<FlSpot> temperatureSpots = results[0]
              .asMap()
              .entries
              .map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value); 
              })
              .toList();

          final List<FlSpot> humiditySpots = results[1]
              .asMap()
              .entries
              .map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value); 
              })
              .toList();

          return {
            'temperature': temperatureSpots,
            'humidity': humiditySpots,
          };
        }),
        builder: (context, AsyncSnapshot<Map<String, List<FlSpot>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          }

          final List<FlSpot> temperatureSpots = snapshot.data!['temperature'] ?? [];
          final List<FlSpot> humiditySpots = snapshot.data!['humidity'] ?? [];

          if (temperatureSpots.isEmpty || humiditySpots.isEmpty) {
            return Center(child: Text('No data available for this batch.'));
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Batch: ${widget.batch.name}', style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                Text('Amount: ${widget.batch.amount}', style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                Text('Days since creation: $daysSinceCreation', style: TextStyle(fontSize: 18)),
                SizedBox(height: 20),

                // Temperature Chart with styled design
                Text('Temperature Data:', style: TextStyle(fontSize: 18)),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, _) {
                              if (value.toInt() < temperatureSpots.length) {
                                final date = widget.batch.creationDate.add(Duration(days: value.toInt()));
                                return RotatedBox(
                                  quarterTurns: 1,
                                  child: Text('${date.month}/${date.day}', style: TextStyle(fontSize: 10)),
                                );
                              }
                              return Container();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, _) {
                              if (value % 5 == 0) {
                                return Text('${value.toInt()}°C', style: TextStyle(fontSize: 10));
                              }
                              return Container();
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, _) {
                              if (value % 5 == 0) {
                                return Text('${value.toInt()}°C', style: TextStyle(fontSize: 10));
                              }
                              return Container();
                            },
                          ),
                        ),
                      ),
                      clipData: FlClipData.all(),
                      minY: 20,
                      maxY: 45,
                      lineBarsData: [
                        LineChartBarData(
                          spots: temperatureSpots,
                          isCurved: true,
                          color: const Color.fromARGB(255, 236, 1, 1),
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.3),
                          ),
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Humidity Chart with styled design
                Text('Humidity Data:', style: TextStyle(fontSize: 18)),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, _) {
                              if (value.toInt() < humiditySpots.length) {
                                final date = widget.batch.creationDate.add(Duration(days: value.toInt()));
                                return RotatedBox(
                                  quarterTurns: 1,
                                  child: Text('${date.month}/${date.day}', style: TextStyle(fontSize: 10)),
                                );
                              }
                              return Container();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, _) {
                              if (value % 10 == 0) {
                                return Text('${value.toInt()}%', style: TextStyle(fontSize: 10));
                              }
                              return Container();
                            },
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, _) {
                              if (value % 10 == 0) {
                                return Text('${value.toInt()}%', style: TextStyle(fontSize: 10));
                              }
                              return Container();
                            },
                          ),
                        ),
                      ),
                      clipData: FlClipData.all(),
                      minY: 30,
                      maxY: 90,
                      lineBarsData: [
                        LineChartBarData(
                          spots: humiditySpots,
                          isCurved: true,
                          color: const Color.fromARGB(255, 0, 25, 247),
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.3),
                          ),
                          dotData: FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
