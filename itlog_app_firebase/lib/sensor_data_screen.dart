import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'sensor_data_provider.dart';

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
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
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
                      _buildDigitalGauge(
                        context,
                        'Humidity',
                        provider.humidity,
                        provider.maxHumidity,
                      ),
                      SizedBox(height: 16),
                      _buildDigitalGauge(
                        context,
                        'Temperature',
                        provider.temperature,
                        50.0,
                        dangerThreshold: 39.0,
                      ),
                      SizedBox(height: 16),
                      _buildSlider(context, provider),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDigitalGauge(BuildContext context, String label, double value, double max, {double? dangerThreshold}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
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
                majorTickStyle: MajorTickStyle(
                  color: Colors.transparent,
                ),
                minorTickStyle: MinorTickStyle(
                  color: Colors.transparent,
                ),
                labelsPosition: ElementsPosition.outside,
                showTicks: false,
                showLabels: false,
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
          'Swing Time (per hour)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
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
            print('Slider value changed: $val');
            provider.updateMotorOperationTime(val);
          },
        ),
      ],
    );
  }
}
