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
      body: FutureBuilder<Map<String, double>>(
        future: Future.wait([
          sensorData.getLatestBatchTemperature(batch.id),
          sensorData.getLatestBatchHumidity(batch.id),
        ]).then((List<double> results) {
          return {
            'temperature': results[0],
            'humidity': results[1],
          };
        }),
        builder: (context, AsyncSnapshot<Map<String, double>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading data'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available'));
          }

          // Safely unpack the latest temperature and humidity data
          final double latestTemperature = snapshot.data!['temperature'] ?? 0.0;
          final double latestHumidity = snapshot.data!['humidity'] ?? 0.0;

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

                // Temperature Chart with Latest Data
                Text('Latest Temperature Data:', style: TextStyle(fontSize: 18)),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: true),
                      titlesData: FlTitlesData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            FlSpot(0, latestTemperature), // Show only the latest temperature
                          ],
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

                // Humidity Chart with Latest Data
                Text('Latest Humidity Data:', style: TextStyle(fontSize: 18)),
                SizedBox(
                  height: 200,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: true),
                      titlesData: FlTitlesData(show: true),
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            FlSpot(0, latestHumidity), // Show only the latest humidity
                          ],
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
