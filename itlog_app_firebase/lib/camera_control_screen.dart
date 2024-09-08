import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class CameraControlScreen extends StatefulWidget {
  @override
  _CameraControlScreenState createState() => _CameraControlScreenState();
}

class _CameraControlScreenState extends State<CameraControlScreen> {
  final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

  double _panValue = 90;
  double _tiltValue = 90;
  bool _isLightOn = false;

  late VlcPlayerController _vlcController;
  bool _isStreaming = false;

  @override
  void initState() {
    super.initState();

    // Initialize the VLC Player Controller with the camera stream URL
    _vlcController = VlcPlayerController.network(
      'http://192.168.1.11:81/stream',  // Change this to your ESP32-CAM stream URL
      hwAcc: HwAcc.full,
      autoPlay: false,
    );

    // Listen to Firebase database for updates to light, pan, and tilt controls
    databaseReference.child('light').onValue.listen((event) {
      final lightState = event.snapshot.value as bool? ?? false;
      setState(() {
        _isLightOn = lightState;
      });
    });

    databaseReference.child('servos/pan').onValue.listen((event) {
      final panValue = event.snapshot.value as int? ?? 90;
      setState(() {
        _panValue = panValue.toDouble();
      });
    });

    databaseReference.child('servos/tilt').onValue.listen((event) {
      final tiltValue = event.snapshot.value as int? ?? 90;
      setState(() {
        _tiltValue = tiltValue.toDouble();
      });
    });
  }

  @override
  void dispose() {
    _vlcController.dispose();
    super.dispose();
  }

  // Function to start/stop streaming
  void toggleStream() {
    setState(() {
      if (_isStreaming) {
        _vlcController.stop();
      } else {
        _vlcController.play();
      }
      _isStreaming = !_isStreaming;
    });
  }

  // Function to update the servo position
  void updateServoPosition(String servo, int angle) {
    databaseReference.child('servos/$servo').set(angle);
  }

  // Function to toggle the light on or off
  void toggleLight() {
    setState(() {
      _isLightOn = !_isLightOn;
    });
    databaseReference.child('light').set(_isLightOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Control'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: <Widget>[
          // Live Feed stays at the top
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: VlcPlayer(
                controller: _vlcController,
                aspectRatio: 16 / 9,
                placeholder: Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
          // Scrollable Control Panel
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: <Widget>[
                    // Stream Toggle Button
                    ElevatedButton.icon(
                      onPressed: toggleStream,
                      icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
                      label: Text(_isStreaming ? 'Stop Streaming' : 'Start Streaming'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Pan Control
                    _buildControlCard(
                      title: 'Pan Control',
                      value: _panValue,
                      onChanged: (value) {
                        setState(() {
                          _panValue = value;
                          updateServoPosition('pan', value.toInt());
                        });
                      },
                      valueLabel: _panValue.toInt().toString(),
                    ),

                    SizedBox(height: 20),

                    // Tilt Control
                    _buildControlCard(
                      title: 'Tilt Control',
                      value: _tiltValue,
                      onChanged: (value) {
                        setState(() {
                          _tiltValue = value;
                          updateServoPosition('tilt', value.toInt());
                        });
                      },
                      valueLabel: _tiltValue.toInt().toString(),
                    ),

                    SizedBox(height: 20),

                    // Light Toggle Button
                    ElevatedButton.icon(
                      onPressed: toggleLight,
                      icon: Icon(_isLightOn ? Icons.lightbulb : Icons.lightbulb_outline),
                      label: Text(_isLightOn ? 'Turn Light Off' : 'Turn Light On'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        textStyle: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for creating control cards with sliders
  Widget _buildControlCard({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
    required String valueLabel,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Slider(
              min: 0,
              max: 180,
              divisions: 180,
              value: value,
              label: valueLabel,
              onChanged: onChanged,
            ),
            Text('Value: $valueLabel', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
