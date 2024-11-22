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
                Icons.water_drop,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HumidityLogScreen()),
                ),
                provider.humidity,
                provider.maxHumidity,
                dangerThreshold: null,
              ),
              SizedBox(height: 16),
              _buildContainer(
                context,
                'Temperature',
                Icons.thermostat,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TemperatureLogScreen()),
                ),
                provider.temperature,
                provider.maxTemperature,
                dangerThreshold: 39.0,
              ),
              SizedBox(height: 16),
              _buildContainer(
                context,
                'Swing Time',
                Icons.timer,
                null,
                null,
                null,
                isSlider: true,
                provider: provider,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContainer(BuildContext context, String title, IconData icon, VoidCallback? onTap, double? value, double? max, {double? dangerThreshold, bool isSlider = false, SensorDataProvider? provider}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Container(
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.grey[200]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.blue, size: 24),
                  SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (isSlider)
                _buildSlider(context, provider!)
              else
                _buildDigitalGauge(context, value!, max!, dangerThreshold),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitalGauge(BuildContext context, double value, double max, double? dangerThreshold) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
          activeColor: Colors.blue,
          inactiveColor: Colors.grey[300],
        ),
      ],
    );
  }
}