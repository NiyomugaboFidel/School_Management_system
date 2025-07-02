import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;

/// Enum for NFC operation types
enum NFCOperationType { read, write, both }

/// Enum for NFC session states
enum NFCSessionState { idle, polling, connected, error }

/// Data class for NFC scan results
class NFCScanResult {
  final String id;
  final String data;
  final NFCTag tag;
  final DateTime timestamp;
  final Map<String, dynamic>? parsedData;

  NFCScanResult({
    required this.id,
    required this.data,
    required this.tag,
    required this.timestamp,
    this.parsedData,
  });

  factory NFCScanResult.fromTag(NFCTag tag, String data) {
    Map<String, dynamic>? parsed;
    try {
      parsed = jsonDecode(data);
    } catch (_) {
      // Not JSON data, keep as null
    }

    return NFCScanResult(
      id: tag.id,
      data: data,
      tag: tag,
      timestamp: DateTime.now(),
      parsedData: parsed,
    );
  }
}

/// Callback types for NFC operations
typedef NFCReadCallback = void Function(NFCScanResult result);
typedef NFCErrorCallback = void Function(String error);
typedef NFCStateCallback = void Function(NFCSessionState state);

/// NFCService: Enhanced singleton for reusable NFC operations with Reader Mode
class NFCService {
  NFCService._privateConstructor();
  static final NFCService instance = NFCService._privateConstructor();

  // Session state management
  NFCSessionState _currentState = NFCSessionState.idle;
  StreamController<NFCSessionState>? _stateController;
  StreamController<NFCScanResult>? _scanController;
  StreamController<String>? _errorController;

  // Polling control
  Timer? _pollingTimer;
  bool _isPolling = false;
  bool _isReaderModeActive = false;

  /// Stream for session state changes
  Stream<NFCSessionState> get stateStream {
    _stateController ??= StreamController<NFCSessionState>.broadcast();
    return _stateController!.stream;
  }

  /// Stream for scan results
  Stream<NFCScanResult> get scanStream {
    _scanController ??= StreamController<NFCScanResult>.broadcast();
    return _scanController!.stream;
  }

  /// Stream for errors
  Stream<String> get errorStream {
    _errorController ??= StreamController<String>.broadcast();
    return _errorController!.stream;
  }

  /// Current session state
  NFCSessionState get currentState => _currentState;

  /// Check if NFC is available on the device
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      return availability == NFCAvailability.available;
    } catch (e) {
      _emitError('NFC availability check failed: $e');
      return false;
    }
  }

  /// Start NFC Reader Mode (Foreground Dispatch Mode)
  /// This keeps NFC active and listening for tags continuously
  Future<bool> startReaderMode({
    Duration pollingInterval = const Duration(milliseconds: 500),
    Duration sessionTimeout = const Duration(seconds: 30),
    NFCOperationType operationType = NFCOperationType.read,
  }) async {
    if (_isReaderModeActive) {
      return true; // Already active
    }

    if (!await isAvailable()) {
      _emitError('NFC is not available on this device');
      return false;
    }

    try {
      _isReaderModeActive = true;
      _updateState(NFCSessionState.polling);
      
      // Start continuous polling with timeout
      _startPolling(pollingInterval, sessionTimeout);
      
      return true;
    } catch (e) {
      _emitError('Failed to start NFC Reader Mode: $e');
      _isReaderModeActive = false;
      _updateState(NFCSessionState.error);
      return false;
    }
  }

  /// Stop NFC Reader Mode
  Future<void> stopReaderMode() async {
    if (!_isReaderModeActive) return;

    _isReaderModeActive = false;
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;

    try {
      await FlutterNfcKit.finish();
    } catch (e) {
      debugPrint('Error finishing NFC session: $e');
    }

    _updateState(NFCSessionState.idle);
  }

  /// Start continuous polling for NFC tags
  void _startPolling(Duration interval, Duration timeout) {
    if (_isPolling) return;

    _isPolling = true;
    final startTime = DateTime.now();

    _pollingTimer = Timer.periodic(interval, (timer) async {
      if (!_isReaderModeActive || !_isPolling) {
        timer.cancel();
        return;
      }

      // Check timeout
      if (DateTime.now().difference(startTime) > timeout) {
        timer.cancel();
        await stopReaderMode();
        _emitError('NFC session timeout');
        return;
      }

      await _pollForTag();
    });
  }

  /// Poll for a single NFC tag
  Future<void> _pollForTag() async {
    if (!_isReaderModeActive) return;

    try {
      _updateState(NFCSessionState.polling);
      
      // Poll with short timeout to avoid blocking
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(milliseconds: 1000),
        iosMultipleTagMessage: "Multiple NFC tags detected",
        iosAlertMessage: "NFC tag detected",
      );

      if (tag != null) {
        _updateState(NFCSessionState.connected);
        await _handleTagDetected(tag);
      }
    } catch (e) {
      // Polling timeout is expected, don't treat as error
      if (!e.toString().contains('timeout') && 
          !e.toString().contains('cancelled')) {
        _emitError('NFC polling error: $e');
      }
    }
  }

  /// Handle detected NFC tag
  Future<void> _handleTagDetected(NFCTag tag) async {
    try {
      // Read NDEF data from the tag
      final ndefRecords = await FlutterNfcKit.readNDEFRecords();
      String data = '';

      if (ndefRecords.isNotEmpty) {
        // Process NDEF records
        for (var record in ndefRecords) {
          if (record is ndef.TextRecord) {
            data += record.text ?? '';
          } else if (record is ndef.UriRecord) {
            data += record.uri?.toString() ?? '';
          } else {
            // Handle other record types
            data += record.payload?.toString() ?? '';
          }
        }
      } else {
        // No NDEF data, use tag ID
        data = tag.id;
      }

      // Create scan result
      final result = NFCScanResult.fromTag(tag, data);
      _emitScanResult(result);

      // Finish the current tag session but keep reader mode active
      await FlutterNfcKit.finish(
        iosAlertMessage: "NFC tag read successfully!",
      );

    } catch (e) {
      _emitError('Error reading NFC tag: $e');
      try {
        await FlutterNfcKit.finish(
          iosErrorMessage: "Error reading NFC tag",
        );
      } catch (_) {}
    }
  }

  /// Single shot NFC read (legacy method for compatibility)
  Future<NFCScanResult?> readSingle({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!await isAvailable()) {
      _emitError('NFC is not available');
      return null;
    }

    try {
      _updateState(NFCSessionState.polling);
      
      final tag = await FlutterNfcKit.poll(
        timeout: timeout,
        iosAlertMessage: "Hold your device near an NFC tag",
      );

      if (tag != null) {
        _updateState(NFCSessionState.connected);
        
        final ndefRecords = await FlutterNfcKit.readNDEFRecords();
        String data = '';

        if (ndefRecords.isNotEmpty) {
          for (var record in ndefRecords) {
            if (record is ndef.TextRecord) {
              data += record.text ?? '';
            } else if (record is ndef.UriRecord) {
              data += record.uri?.toString() ?? '';
            } else {
              data += record.payload?.toString() ?? '';
            }
          }
        } else {
          data = tag.id;
        }

        await FlutterNfcKit.finish(
          iosAlertMessage: "NFC read completed!",
        );

        _updateState(NFCSessionState.idle);
        return NFCScanResult.fromTag(tag, data);
      }
    } catch (e) {
      _emitError('NFC read failed: $e');
      try {
        await FlutterNfcKit.finish(iosErrorMessage: e.toString());
      } catch (_) {}
    }

    _updateState(NFCSessionState.idle);
    return null;
  }

  /// Write JSON data to NFC tag
  Future<bool> writeJsonToTag(
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!await isAvailable()) {
      _emitError('NFC is not available');
      return false;
    }

    try {
      _updateState(NFCSessionState.polling);
      
      final tag = await FlutterNfcKit.poll(
        timeout: timeout,
        iosAlertMessage: "Hold your device near an NFC tag to write",
      );

      if (tag != null) {
        _updateState(NFCSessionState.connected);
        
        final ndefRecord = ndef.TextRecord(
          text: jsonEncode(data),
          language: 'en',
        );

        await FlutterNfcKit.writeNDEFRecords([ndefRecord]);
        
        await FlutterNfcKit.finish(
          iosAlertMessage: "Data written successfully!",
        );

        _updateState(NFCSessionState.idle);
        return true;
      }
    } catch (e) {
      _emitError('NFC write failed: $e');
      try {
        await FlutterNfcKit.finish(iosErrorMessage: e.toString());
      } catch (_) {}
    }

    _updateState(NFCSessionState.idle);
    return false;
  }

  /// Write plain text to NFC tag
  Future<bool> writeTextToTag(
    String text, {
    Duration timeout = const Duration(seconds: 10),
    String language = 'en',
  }) async {
    if (!await isAvailable()) {
      _emitError('NFC is not available');
      return false;
    }

    try {
      _updateState(NFCSessionState.polling);
      
      final tag = await FlutterNfcKit.poll(
        timeout: timeout,
        iosAlertMessage: "Hold your device near an NFC tag to write",
      );

      if (tag != null) {
        _updateState(NFCSessionState.connected);
        
        final ndefRecord = ndef.TextRecord(
          text: text,
          language: language,
        );

        await FlutterNfcKit.writeNDEFRecords([ndefRecord]);
        
        await FlutterNfcKit.finish(
          iosAlertMessage: "Text written successfully!",
        );

        _updateState(NFCSessionState.idle);
        return true;
      }
    } catch (e) {
      _emitError('NFC write failed: $e');
      try {
        await FlutterNfcKit.finish(iosErrorMessage: e.toString());
      } catch (_) {}
    }

    _updateState(NFCSessionState.idle);
    return false;
  }

  /// Emit state change
  void _updateState(NFCSessionState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController?.add(newState);
    }
  }

  /// Emit scan result
  void _emitScanResult(NFCScanResult result) {
    _scanController?.add(result);
  }

  /// Emit error
  void _emitError(String error) {
    debugPrint('NFCService Error: $error');
    _errorController?.add(error);
  }

  /// Cleanup resources
  void dispose() {
    stopReaderMode();
    _stateController?.close();
    _scanController?.close();
    _errorController?.close();
    _stateController = null;
    _scanController = null;
    _errorController = null;
  }

  /// Legacy method for compatibility
  Future<void> finish({
    String? iosAlertMessage,
    String? iosErrorMessage,
  }) async {
    try {
      await FlutterNfcKit.finish(
        iosAlertMessage: iosAlertMessage,
        iosErrorMessage: iosErrorMessage,
      );
    } catch (e) {
      debugPrint('Error finishing NFC session: $e');
    }
  }
}