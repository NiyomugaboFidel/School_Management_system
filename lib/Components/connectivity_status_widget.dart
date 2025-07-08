import 'package:flutter/material.dart';
import 'package:sqlite_crud_app/services/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityStatusWidget extends StatefulWidget {
  const ConnectivityStatusWidget({Key? key}) : super(key: key);

  @override
  State<ConnectivityStatusWidget> createState() =>
      _ConnectivityStatusWidgetState();
}

class _ConnectivityStatusWidgetState extends State<ConnectivityStatusWidget> {
  ConnectivityResult _connectivityStatus = ConnectivityResult.none;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _loadConnectivityStatus();
  }

  Future<void> _loadConnectivityStatus() async {
    try {
      final status = await ConnectivityService().getConnectivityStatus();
      if (mounted) {
        setState(() {
          _connectivityStatus = status.isNotEmpty ? status.first : ConnectivityResult.none;
          _isOnline = status.isNotEmpty && status.first != ConnectivityResult.none;
        });
      }
    } catch (e) {
      print('Error loading connectivity status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            _isOnline
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              _isOnline
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isOnline ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            _isOnline ? Icons.wifi : Icons.wifi_off,
            color: _isOnline ? Colors.green : Colors.red,
            size: 16,
          ),
        ],
      ),
    );
  }
}
