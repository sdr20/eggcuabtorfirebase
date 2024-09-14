import 'package:flutter/material.dart';
import 'sensor_data_screen.dart';
import 'camera_control_screen.dart';
import 'egg_batches_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Handles taps on bottom navigation bar items
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      print("Selected index: $index");  // Debugging output
    });
  }

  @override
  Widget build(BuildContext context) {
    // List of screens for each navigation item
    List<Widget> _widgetOptions = <Widget>[
      SensorDataScreen(),
      EggBatchesScreen(), // The Egg Batches Screen
      CameraControlScreen(), // Camera Control Screen
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'IT_Log',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: _widgetOptions.elementAt(_selectedIndex), // Display selected screen
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.thermostat),
            label: 'Sensors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.egg),
            label: 'Egg', // Renamed from Gallery to Egg
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camera Control',
          ),
        ],
        currentIndex: _selectedIndex, // The currently selected index
        selectedItemColor: Colors.blueAccent,
        onTap: _onItemTapped, // Handle taps
      ),
    );
  }
}
