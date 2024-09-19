import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'sensor_data_provider.dart';
import 'egg_batch.dart'; // Import EggBatch

class BatchAnalyticsScreen extends StatelessWidget {
  final EggBatch batch;

  BatchAnalyticsScreen({required this.batch});

  @override
  Widget build(BuildContext context) {
    final sensorData = Provider.of<SensorDataProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Analytics for ${batch.name}')),
      body: FutureBuilder<Map<String, List<FlSpot>>>(
        future: Future.wait([
          sensorData.getBatchTemperatureData(batch.id),
          sensorData.getBatchHumidityData(batch.id),
        ]).then((List<List<double>> results) {
          final List<FlSpot> temperatureSpots = results[0]
              .asMap()
              .entries
              .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
              .toList();

          final List<FlSpot> humiditySpots = results[1]
              .asMap()
              .entries
              .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
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
            return Center(child: Text('Error loading data'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          }

          final List<FlSpot> temperatureSpots = snapshot.data!['temperature']!;
          final List<FlSpot> humiditySpots = snapshot.data!['humidity']!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Batch: ${batch.name}', style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                Text('Amount: ${batch.amount}', style: TextStyle(fontSize: 20)),
                SizedBox(height: 10),
                Text('Days since creation: ${DateTime.now().difference(batch.creationDate).inDays}', style: TextStyle(fontSize: 18)),
                SizedBox(height: 20),

                // Temperature Chart with historical data
                Text('Temperature Data:', style: TextStyle(fontSize: 18)),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: true),
                      titlesData: FlTitlesData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: temperatureSpots, // Plot all historical temperature data
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Humidity Chart with historical data
                Text('Humidity Data:', style: TextStyle(fontSize: 18)),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: true),
                      titlesData: FlTitlesData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: humiditySpots, // Plot all historical humidity data
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.blue.withOpacity(0.3),
                          ),
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
