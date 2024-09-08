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
  bool _isLightOn = false; // Track the light state

  late VlcPlayerController _vlcController;

  @override
  void initState() {
    super.initState();

    _vlcController = VlcPlayerController.network(
      'http://192.168.1.11:81/stream',
      autoPlay: true,
    );

    // Listen to changes in the light's state in Firebase
    databaseReference.child('light').onValue.listen((event) {
      final lightState = event.snapshot.value as bool? ?? false;
      setState(() {
        _isLightOn = lightState;
      });
    });

    // Listen to changes in the pan value in Firebase
    databaseReference.child('servos/pan').onValue.listen((event) {
      final panValue = event.snapshot.value as int? ?? 90;
      setState(() {
        _panValue = panValue.toDouble();
      });
    });

    // Listen to changes in the tilt value in Firebase
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
          Expanded(
            child: Container(
              color: Colors.black,
              child: VlcPlayer(
                controller: _vlcController,
                aspectRatio: 16 / 9,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: <Widget>[
                Text('Pan Control'),
                Slider(
                  min: 0,
                  max: 180,
                  divisions: 180,
                  value: _panValue,
                  label: _panValue.toInt().toString(),
                  onChanged: (value) {
                    setState(() {
                      _panValue = value;
                      updateServoPosition('pan', value.toInt());
                    });
                  },
                ),
                Text('Pan Angle: ${_panValue.toInt()}'),
                Text('Tilt Control'),
                Slider(
                  min: 0,
                  max: 180,
                  divisions: 180,
                  value: _tiltValue,
                  label: _tiltValue.toInt().toString(),
                  onChanged: (value) {
                    setState(() {
                      _tiltValue = value;
                      updateServoPosition('tilt', value.toInt());
                    });
                  },
                ),
                Text('Tilt Angle: ${_tiltValue.toInt()}'),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: toggleLight,
                  child: Text(_isLightOn ? 'Turn Light Off' : 'Turn Light On'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
