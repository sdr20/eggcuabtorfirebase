import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'sensor_data_provider.dart';
import 'home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          databaseURL: "https://itlog-database-default-rtdb.asia-southeast1.firebasedatabase.app",
          apiKey: "AIzaSyCr9bO9Hxao0VIstBR1nK0UWchlCIQSNhU",
          appId: "1:120718043785:android:76f4bafbf2f4abb83c3458",
          messagingSenderId: "120718043785",
          projectId: "itlog-database",
          storageBucket: "itlog-database.appspot.com",
        ),
      );
      print('Firebase initialized');
    } else {
      print('Firebase already initialized');
    }
  } catch (e) {
    print('Error initializing Firebase: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SensorDataProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'IT_Log',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          textTheme: TextTheme(
            displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
            titleLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
            titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54),
            bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ),
        home: HomeScreen(),
      ),
    );
  }
}
