import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'splash_decider.dart';

class TestFirebasePage extends StatefulWidget {
  const TestFirebasePage({Key? key}) : super(key: key);

  @override
  State<TestFirebasePage> createState() => _TestFirebasePageState();
}

class _TestFirebasePageState extends State<TestFirebasePage> {
  String _status = 'Ready to test';
  bool _isTesting = false;

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isTesting = true;
      _status = 'Testing Firebase connection...';
    });

    try {
      await FirebaseConnectionTester.testFirebaseConnection();
      setState(() {
        _status = '✅ Firebase test completed! Check console for details.';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Test failed: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testDirectFirestore() async {
    setState(() {
      _isTesting = true;
      _status = 'Testing direct Firestore access...';
    });

    try {
      final now = DateTime.now();
      final testData = {
        'platform': kIsWeb ? 'web' : 'mobile',
        'timestamp': now.toIso8601String(),
        'message': 'Direct Firestore test',
        'test_type': 'direct_firestore_test',
      };

      await FirebaseFirestore.instance
          .collection('test_connection')
          .add(testData);
      setState(() {
        _status = '✅ Direct Firestore test successful!';
      });
      print('📊 Direct test data: $testData');
    } catch (e) {
      setState(() {
        _status = '❌ Direct test failed: $e';
      });
      print('🔍 Direct test error: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Connection Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Platform: ${kIsWeb ? 'Web' : 'Mobile'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: $_status',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            _status.contains('✅')
                                ? Colors.green
                                : _status.contains('❌')
                                ? Colors.red
                                : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isTesting ? null : _testFirebaseConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  _isTesting
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Testing...'),
                        ],
                      )
                      : const Text('Test Firebase Connection'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isTesting ? null : _testDirectFirestore,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Test Direct Firestore'),
            ),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Click "Test Firebase Connection" to test using the helper class',
                    ),
                    Text(
                      '2. Click "Test Direct Firestore" to test direct Firestore access',
                    ),
                    Text('3. Check the console for detailed logs'),
                    Text(
                      '4. Check your Firestore database for new documents in "test_connection" collection',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
