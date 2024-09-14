import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'egg_batches_screen.dart';
import 'sensor_data_provider.dart';

class BatchAnalyticsScreen extends StatelessWidget {
  final EggBatch batch;

  BatchAnalyticsScreen({required this.batch});

  @override
  Widget build(BuildContext context) {
    final sensorData = Provider.of<SensorDataProvider>(context);

    // Example data for testing
    List<double> exampleTemperatureData = List.generate(25, (index) => (index + 1).toDouble());
    List<double> exampleHumidityData = List.generate(25, (index) => (25 - index).toDouble());

    return Scaffold(
      appBar: AppBar(title: Text('Analytics for ${batch.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Batch: ${batch.name}', style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            Text('Amount: ${batch.amount}', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),

            // Temperature Chart
            Text('Temperature Data:', style: TextStyle(fontSize: 18)),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  titlesData: FlTitlesData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(25, (index) {
                        // Replace this with real data from sensorData if necessary
                        double avgTemp = exampleTemperatureData[index];
                        return FlSpot(index.toDouble(), avgTemp);
                      }),
                      isCurved: true,
                      color: Colors.red, // Use a single color
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

            // Humidity Chart
            Text('Humidity Data:', style: TextStyle(fontSize: 18)),
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  titlesData: FlTitlesData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(25, (index) {
                        // Replace this with real data from sensorData if necessary
                        double avgHumid = exampleHumidityData[index];
                        return FlSpot(index.toDouble(), avgHumid);
                      }),
                      isCurved: true,
                      color: Colors.blue, // Use a single color
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
      ),
    );
  }
}
