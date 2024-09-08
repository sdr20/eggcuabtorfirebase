import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'sensor_data_provider.dart';
import 'humidity_log_screen.dart';
import 'temperature_log_screen.dart';

class SensorDataScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<SensorDataProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 0,
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildContainer(
                context,
                'Humidity',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HumidityLogScreen()),
                ),
                _buildDigitalGauge(
                  context,
                  'Humidity',
                  provider.humidity,
                  provider.maxHumidity,
                ),
              ),
              SizedBox(height: 16),
              _buildContainer(
                context,
                'Temperature',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TemperatureLogScreen()),
                ),
                _buildDigitalGauge(
                  context,
                  'Temperature',
                  provider.temperature,
                  50.0,
                  dangerThreshold: 39.0,
                ),
              ),
              SizedBox(height: 16),
              _buildContainer(
                context,
                'Swing Time',
                null,
                _buildSlider(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContainer(BuildContext context, String title, VoidCallback? onTap, Widget child) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDigitalGauge(BuildContext context, String label, double value, double max, {double? dangerThreshold}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 160,
          height: 160,
          child: SfRadialGauge(
            axes: <RadialAxis>[
              RadialAxis(
                minimum: 0,
                maximum: max,
                interval: max / 5,
                pointers: <GaugePointer>[
                  NeedlePointer(
                    value: value,
                    needleColor: Colors.blue,
                    knobStyle: KnobStyle(color: Colors.blue),
                  ),
                ],
                ranges: <GaugeRange>[
                  if (dangerThreshold != null)
                    GaugeRange(
                      startValue: dangerThreshold,
                      endValue: max,
                      color: Colors.red.withOpacity(0.3),
                      startWidth: 15,
                      endWidth: 15,
                    ),
                ],
                annotations: <GaugeAnnotation>[
                  GaugeAnnotation(
                    widget: Container(
                      child: Text(
                        '${value.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    angle: 90,
                    positionFactor: 0.5,
                  ),
                ],
                axisLineStyle: AxisLineStyle(
                  thickness: 12,
                  color: Colors.blueGrey[200],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(BuildContext context, SensorDataProvider provider) {
    return Column(
      children: [
        Text(
          '${provider.motorOperationTime.toStringAsFixed(1)} hours',
          style: TextStyle(fontSize: 14),
        ),
        Slider(
          value: provider.motorOperationTime,
          min: 0,
          max: 12,
          divisions: 12,
          label: '${provider.motorOperationTime.toStringAsFixed(1)} hours',
          onChanged: (val) {
            provider.updateMotorOperationTime(val);
          },
        ),
      ],
    );
  }
}
