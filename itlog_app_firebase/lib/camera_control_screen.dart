// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter_vlc_player/flutter_vlc_player.dart';
// import 'package:http/http.dart' as http; // For local network requests

// class CameraControlScreen extends StatefulWidget {
//   @override
//   _CameraControlScreenState createState() => _CameraControlScreenState();
// }

// class _CameraControlScreenState extends State<CameraControlScreen> {
//   final DatabaseReference databaseReference = FirebaseDatabase.instance.ref();

//   double _panValue = 90;
//   double _tiltValue = 90;
//   bool _isLightOn = false;

//   late VlcPlayerController _vlcController;
//   bool _isStreaming = false;

//   late StreamSubscription<DatabaseEvent> _lightSubscription;

//   @override
//   void initState() {
//     super.initState();

//     // Initialize the VLC Player Controller with the camera stream URL
//     _vlcController = VlcPlayerController.network(
//       'http://192.168.254.111:81/stream', // ESP32-CAM stream URL
//       hwAcc: HwAcc.full,
//       autoPlay: false,
//     );

//     // Listen for Firebase updates on the light status
//     _lightSubscription = databaseReference.child('light').onValue.listen((event) {
//       if (mounted) {
//         final lightState = event.snapshot.value as bool? ?? false;
//         setState(() {
//           _isLightOn = lightState;
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _vlcController.dispose();
//     _lightSubscription.cancel();
//     super.dispose();
//   }

//   // Start or stop the camera stream
//   void toggleStream() {
//     setState(() {
//       if (_isStreaming) {
//         _vlcController.stop();
//       } else {
//         _vlcController.play();
//       }
//       _isStreaming = !_isStreaming;
//     });
//   }

//   // Function to send servo position update to ESP32 (Local Network)
//   Future<void> updateServoPosition(String servo, double angle) async {
//     final url = Uri.parse('http://192.168.1.11/servo?${servo}=${angle.toInt()}');
//     try {
//       final response = await http.get(url);
//       if (response.statusCode != 200) {
//         print("Failed to update servo: ${response.statusCode}");
//       }
//     } catch (e) {
//       print("Error sending request to ESP32: $e");
//     }
//   }

//   // Toggle the light (controlled via Firebase)
//   void toggleLight() {
//     setState(() {
//       _isLightOn = !_isLightOn;
//     });
//     databaseReference.child('light').set(_isLightOn);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Camera Control'),
//         backgroundColor: Colors.blue,
//       ),
//       body: Column(
//         children: <Widget>[
//           // Live Feed
//           Expanded(
//             flex: 3,
//             child: Container(
//               color: Colors.black,
//               child: VlcPlayer(
//                 controller: _vlcController,
//                 aspectRatio: 16 / 9,
//                 placeholder: Center(child: CircularProgressIndicator()),
//               ),
//             ),
//           ),
//           // Control Panel
//           Expanded(
//             flex: 2,
//             child: SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   children: <Widget>[
//                     // Stream Toggle Button
//                     ElevatedButton.icon(
//                       onPressed: toggleStream,
//                       icon: Icon(_isStreaming ? Icons.stop : Icons.play_arrow),
//                       label: Text(_isStreaming ? 'Stop Streaming' : 'Start Streaming'),
//                       style: ElevatedButton.styleFrom(
//                         padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                         textStyle: TextStyle(fontSize: 18),
//                       ),
//                     ),
//                     SizedBox(height: 20),

//                     // Pan Control (Local Network via ESP32)
//                     _buildControlCard(
//                       title: 'Pan Control',
//                       value: _panValue,
//                       onChanged: (value) {
//                         setState(() {
//                           _panValue = value;
//                           updateServoPosition('pan', _panValue);
//                         });
//                       },
//                       valueLabel: _panValue.toInt().toString(),
//                     ),

//                     SizedBox(height: 20),

//                     // Tilt Control (Local Network via ESP32)
//                     _buildControlCard(
//                       title: 'Tilt Control',
//                       value: _tiltValue,
//                       onChanged: (value) {
//                         setState(() {
//                           _tiltValue = value;
//                           updateServoPosition('tilt', _tiltValue);
//                         });
//                       },
//                       valueLabel: _tiltValue.toInt().toString(),
//                     ),

//                     SizedBox(height: 20),

//                     // Light Toggle (Firebase)
//                     ElevatedButton.icon(
//                       onPressed: toggleLight,
//                       icon: Icon(_isLightOn ? Icons.lightbulb : Icons.lightbulb_outline),
//                       label: Text(_isLightOn ? 'Turn Light Off' : 'Turn Light On'),
//                       style: ElevatedButton.styleFrom(
//                         padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
//                         textStyle: TextStyle(fontSize: 18),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Widget for control sliders
//   Widget _buildControlCard({
//     required String title,
//     required double value,
//     required ValueChanged<double> onChanged,
//     required String valueLabel,
//   }) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//             Slider(
//               min: 0,
//               max: 180,
//               divisions: 180,
//               value: value,
//               label: valueLabel,
//               onChanged: onChanged,
//             ),
//             Text('Value: $valueLabel', style: TextStyle(fontSize: 14)),
//           ],
//         ),
//       ),
//     );
//   }
// }



import 'dart:async'; // Import for StreamSubscription

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

  // Declare StreamSubscription variables
  late StreamSubscription<DatabaseEvent> _lightSubscription;
  late StreamSubscription<DatabaseEvent> _panSubscription;
  late StreamSubscription<DatabaseEvent> _tiltSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize the VLC Player Controller with the camera stream URL
    _vlcController = VlcPlayerController.network(
      'http://192.168.254.111:81/stream',  // Change this to your ESP32-CAM stream URL
      hwAcc: HwAcc.full,
      autoPlay: false,
    );

    // Listen to Firebase database for updates to light, pan, and tilt controls
    _lightSubscription = databaseReference.child('light').onValue.listen((event) {
      if (mounted) {
        final lightState = event.snapshot.value as bool? ?? false;
        setState(() {
          _isLightOn = lightState;
        });
      }
    });

    _panSubscription = databaseReference.child('servos/pan').onValue.listen((event) {
      if (mounted) {
        final panValue = event.snapshot.value as int? ?? 90;
        setState(() {
          _panValue = panValue.toDouble();
        });
      }
    });

    _tiltSubscription = databaseReference.child('servos/tilt').onValue.listen((event) {
      if (mounted) {
        final tiltValue = event.snapshot.value as int? ?? 90;
        setState(() {
          _tiltValue = tiltValue.toDouble();
        });
      }
    });
  }

  @override
  void dispose() {
    _vlcController.dispose();
    _lightSubscription.cancel();
    _panSubscription.cancel();
    _tiltSubscription.cancel();
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