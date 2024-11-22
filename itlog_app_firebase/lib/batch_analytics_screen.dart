import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'sensor_data_provider.dart';
import 'egg_batch.dart';

// AnalyticsChart widget to display line charts for temperature and humidity
class AnalyticsChart extends StatelessWidget {
  final List<FlSpot> spots;
  final String title;
  final double minY;
  final double maxY;
  final Color color;
  final String unitLabel;
  final double stepSize;
  final DateTime startDate;

  const AnalyticsChart({
    Key? key,
    required this.spots,
    required this.title,
    required this.minY,
    required this.maxY,
    required this.color,
    required this.unitLabel,
    required this.stepSize,
    required this.startDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title:',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 1.2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LineChart(
                  LineChartData(
                    gridData: _buildGridData(),
                    titlesData: _buildTitlesData(),
                    borderData: _buildBorderData(),
                    lineTouchData: _buildTouchData(),
                    lineBarsData: [_buildLineBarData()],
                    minX: 0,
                    maxX: spots.length.toDouble() - 1,
                    minY: minY,
                    maxY: maxY,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  FlGridData _buildGridData() {
    return FlGridData(
      show: true,
      drawVerticalLine: true,
      horizontalInterval: stepSize,
      getDrawingVerticalLine: (value) => FlLine(
        color: Colors.grey.withOpacity(0.1),
        strokeWidth: 1,
      ),
      getDrawingHorizontalLine: (value) => FlLine(
        color: Colors.grey.withOpacity(0.1),
        strokeWidth: 1,
      ),
    );
  }

  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: 1,
          getTitlesWidget: (value, meta) => _buildBottomTitle(value),
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 45,
          interval: stepSize,
          getTitlesWidget: (value, meta) => _buildLeftTitle(value),
        ),
      ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    );
  }

  Widget _buildBottomTitle(double value) {
    if (value.toInt() >= spots.length) return const SizedBox.shrink();
    
    final date = startDate.add(Duration(days: value.toInt()));
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: RotatedBox(
        quarterTurns: 1,
        child: Text(
          '${date.month}/${date.day}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildLeftTitle(double value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Text(
        '${value.toInt()}$unitLabel',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.grey,
        ),
      ),
    );
  }

  FlBorderData _buildBorderData() {
    return FlBorderData(
      show: true,
      border: Border.all(
        color: Colors.grey.withOpacity(0.2),
      ),
    );
  }

  LineTouchData _buildTouchData() {
    return LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        tooltipRoundedRadius: 8,
        getTooltipItems: (touchedSpots) {
          return touchedSpots.map((spot) {
            final date = startDate.add(Duration(days: spot.x.toInt()));
            return LineTooltipItem(
              '${date.month}/${date.day}\n${spot.y.toStringAsFixed(1)}$unitLabel',
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList();
        },
      ),
    );
  }

  LineChartBarData _buildLineBarData() {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
          radius: 4,
          color: color,
          strokeWidth: 2,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.15),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

// BatchAnalyticsScreen widget to display analytics for a specific egg batch
class BatchAnalyticsScreen extends StatefulWidget {
  final EggBatch batch;

  const BatchAnalyticsScreen({Key? key, required this.batch}) : super(key: key);

  @override
  _BatchAnalyticsScreenState createState() => _BatchAnalyticsScreenState();
}

class _BatchAnalyticsScreenState extends State<BatchAnalyticsScreen> {
  late int daysSinceCreation;
  late Timer _timer;
  late Future<Map<String, List<FlSpot>>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _updateDaysSinceCreation();
    _startAutoUpdate();
    _dataFuture = _fetchData();
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
    _timer = Timer.periodic(const Duration(days: 1), (timer) {
      _updateDaysSinceCreation();
    });
  }

  Future<Map<String, List<FlSpot>>> _fetchData() async {
    final sensorData = Provider.of<SensorDataProvider>(context, listen: false);
    final temperatureData = await sensorData.getBatchTemperatureData(widget.batch.id);
    final humidityData = await sensorData.getBatchHumidityData(widget.batch.id);

    final temperatureSpots = temperatureData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    final humiditySpots = humidityData.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();

    return {
      'temperature': temperatureSpots,
      'humidity': humiditySpots,
    };
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sensorData = Provider.of<SensorDataProvider>(context);
    
    // Start recording only once when the widget is created
    if (!sensorData.activeBatches.contains(widget.batch.id)) {
      sensorData.startRecordingForBatch(widget.batch.id);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Trigger a new fetch when refreshing
                _dataFuture = _fetchData();
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, List<FlSpot>>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data available'));
          }

          final List<FlSpot> temperatureSpots = snapshot.data!['temperature'] ?? [];
          final List<FlSpot> humiditySpots = snapshot.data!['humidity'] ?? [];

          if (temperatureSpots.isEmpty || humiditySpots.isEmpty) {
            return const Center(child: Text('No data available for this batch.'));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Batch: ${widget.batch.name}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Amount: ${widget.batch.amount}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Days since creation: $daysSinceCreation',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AnalyticsChart(
                    spots: temperatureSpots,
                    title: 'Temperature Data',
                    minY: 20,
                    maxY: 50,
                    color: const Color.fromARGB(255, 236, 1, 1),
                    unitLabel: '°C',
                    stepSize: 5,
                    startDate: widget.batch.creationDate,
                  ),
                  const SizedBox(height: 20),
                  AnalyticsChart(
                    spots: humiditySpots,
                    title: 'Humidity Data',
                    minY: 40,
                    maxY: 90,
                    color: const Color.fromARGB(255, 1, 122, 236),
                    unitLabel: '%',
                    stepSize: 10,
                    startDate: widget.batch.creationDate,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}