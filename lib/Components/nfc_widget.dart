import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:ndef/ndef.dart' as ndef;
import '../models/scan_result.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';

class NfcScannerWidget extends StatefulWidget {
  final Function(ScanResult) onScanResult;

  const NfcScannerWidget({super.key, required this.onScanResult});

  @override
  State<NfcScannerWidget> createState() => _NfcScannerWidgetState();
}

class _NfcScannerWidgetState extends State<NfcScannerWidget>
    with WidgetsBindingObserver {
  bool _isScanning = false;
  bool _isAvailable = false;
  Set<String> _recentlyScanned = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkNfcAvailability();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopNfcScan();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _isAvailable && !_isScanning) {
      _startContinuousNfcScan();
    }
  }

  Future<void> _checkNfcAvailability() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      setState(() {
        _isAvailable = availability == NFCAvailability.available;
      });
      if (_isAvailable) {
        _startContinuousNfcScan();
      }
    } catch (e) {
      setState(() {
        _isAvailable = false;
      });
    }
  }

  Future<void> _startContinuousNfcScan() async {
    if (!_isAvailable || _isScanning) return;
    setState(() => _isScanning = true);

    while (_isScanning) {
      try {
        final tag = await FlutterNfcKit.poll(
          timeout: const Duration(seconds: 20),
          iosMultipleTagMessage:
              "Multiple NFC tags detected! Please present only one tag.",
          iosAlertMessage: "Hold your device near an NFC tag.",
        );
        if (!_isScanning) break;

        String? ndefText = await _extractNdefText(tag);
        if (ndefText == null || ndefText.isEmpty) {
          throw Exception('No valid NDEF text found on NFC tag');
        }

        // Debounce: Ignore if scanned in last 1s
        if (_recentlyScanned.contains(ndefText)) continue;
        _recentlyScanned.add(ndefText);
        Future.delayed(
          const Duration(seconds: 1),
          () => _recentlyScanned.remove(ndefText),
        );

        final result = ScanResult(
          id: ndefText,
          data: ndefText,
          type: ScanType.nfc,
          timestamp: DateTime.now(),
        );
        widget.onScanResult(result);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('NFC Tag Read: $ndefText'),
              backgroundColor: AppColors.primary,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        await FlutterNfcKit.finish(
          iosAlertMessage: "NFC tag read successfully!",
        );
        // No delay, immediately ready for next scan
      } catch (e) {
        if (!_isScanning) break;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        await FlutterNfcKit.finish(iosErrorMessage: "Failed to read NFC tag");
        // No delay, immediately ready for next scan
      }
    }
  }

  Future<String?> _extractNdefText(NFCTag tag) async {
    try {
      if (tag.ndefAvailable == true) {
        final records = await FlutterNfcKit.readNDEFRecords(cached: false);
        for (var record in records) {
          if (record is ndef.TextRecord) {
            return record.text?.trim();
          }
        }
      }
    } catch (e) {
      print('Error extracting NDEF text: $e');
    }
    return null;
  }

  void _stopNfcScan() async {
    if (!_isScanning) return;
    setState(() => _isScanning = false);
    try {
      await FlutterNfcKit.finish(iosAlertMessage: "NFC scanning stopped");
    } catch (e) {
      print('Error stopping NFC session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAvailable) {
      return const SizedBox(
        height: 60,
        child: Center(
          child: Text('NFC not available', style: TextStyle(color: Colors.red)),
        ),
      );
    }

    return SizedBox(
      height: 60,
      child: Center(
        child: ElevatedButton(
          onPressed: _isScanning ? _stopNfcScan : _startContinuousNfcScan,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isScanning ? AppColors.error : AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Text(_isScanning ? 'Stop NFC' : 'Start NFC'),
        ),
      ),
    );
  }
}
