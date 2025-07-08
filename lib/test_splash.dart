import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestSplashScreen extends StatefulWidget {
  const TestSplashScreen({Key? key}) : super(key: key);

  @override
  State<TestSplashScreen> createState() => _TestSplashScreenState();
}

class _TestSplashScreenState extends State<TestSplashScreen> {
  String _status = 'Testing app startup...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _testStartup();
  }

  Future<void> _testStartup() async {
    try {
      setState(() => _status = 'Testing SharedPreferences...');
      await SharedPreferences.getInstance();
      
      setState(() => _status = 'Testing navigation...');
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.check,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            
            const Text(
              'TEST MODE',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 20),
            
            Text(
              _status,
              style: TextStyle(
                fontSize: 16,
                color: _hasError ? Colors.red : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            if (_hasError)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasError = false;
                    _status = 'Retrying...';
                  });
                  _testStartup();
                },
                child: const Text('Retry'),
              ),
          ],
        ),
      ),
    );
  }
} 