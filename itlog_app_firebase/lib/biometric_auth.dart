import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'home_screen.dart';  // Ensure you import HomeScreen

class BiometricAuth extends StatefulWidget {
  @override
  _BiometricAuthState createState() => _BiometricAuthState();
}

class _BiometricAuthState extends State<BiometricAuth> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isLoading = false;
  String _errorMessage = '';
  int _retryCount = 0;
  static const int _maxRetries = 3;

  Future<void> _authenticate() async {
    // Check for available biometric options
    final availableBiometrics = await auth.getAvailableBiometrics();
    if (availableBiometrics.isEmpty) {
      setState(() {
        _errorMessage = 'No biometric authentication methods available.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access the app',
        options: const AuthenticationOptions(
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (didAuthenticate) {
        // Navigate to HomeScreen on successful authentication
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Authentication failed. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication error: ${e.toString()}';
        _isLoading = false;
        _retryCount++;
      });

      // Retry authentication if the max retry count is not reached
      if (_retryCount < _maxRetries) {
        await Future.delayed(const Duration(seconds: 2)); // Delay before retrying
        _authenticate(); // Retry authentication
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication Required'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _buildAuthPrompt(),
      ),
    );
  }

  Widget _buildAuthPrompt() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fingerprint,
            size: 100,
            color: Colors.blueAccent,
          ),
          const SizedBox(height: 20),
          const Text(
            'Authenticate to continue',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please use your biometric credentials.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          ],
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _isLoading ? null : _authenticate, // Disable button while loading
            child: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}