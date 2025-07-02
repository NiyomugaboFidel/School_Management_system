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

class _NfcScannerWidgetState extends State<NfcScannerWidget> with WidgetsBindingObserver {
  bool _isScanning = false;
  bool _isAvailable = false;
  NFCTag? _currentTag;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkNfcAvailability();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isScanning) {
      FlutterNfcKit.finish();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Keep NFC session active when app is in foreground
    if (state == AppLifecycleState.resumed && _isAvailable && !_isScanning) {
      // Automatically start scanning when app comes to foreground
      _startNfcScan();
    } else if (state == AppLifecycleState.paused && _isScanning) {
      // Keep session active in background to maintain priority
      // Don't stop the session to maintain app priority
    }
  }

  Future<void> _checkNfcAvailability() async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      setState(() {
        _isAvailable = availability == NFCAvailability.available;
      });
      
      // Auto-start scanning if NFC is available
      if (_isAvailable) {
        _startNfcScan();
      }
    } catch (e) {
      setState(() {
        _isAvailable = false;
      });
      print('Error checking NFC availability: $e');
    }
  }

  String _determineNfcType(NFCTag tag) {
    switch (tag.type) {
      case NFCTagType.iso7816:
        return 'ISO 7816 (Smart Card)';
      case NFCTagType.iso15693:
        return 'NFC-V (ISO 15693)';
      case NFCTagType.mifare_classic:
        return 'MIFARE Classic';
      case NFCTagType.mifare_ultralight:
        return 'MIFARE Ultralight';
      case NFCTagType.mifare_desfire:
        return 'MIFARE DESFire';
      // case NFCTagType.felica:
      //   return 'NFC-F (FeliCa)';
      case NFCTagType.webusb:
        return 'WebUSB';
      default:
        // Check for additional type information
        if (tag.standard == "ISO 14443 Type A") {
          return 'NFC-A (ISO 14443 Type A)';
        } else if (tag.standard == "ISO 14443 Type B") {
          return 'NFC-B (ISO 14443 Type B)';
        }
        return 'Unknown NFC Type (${tag.type})';
    }
  }

  Future<String> _extractNdefData(NFCTag tag) async {
    String data = '';
    
    try {
      if (tag.ndefAvailable == true) {
        // Read decoded NDEF records
        final records = await FlutterNfcKit.readNDEFRecords(cached: false);
        
        for (var record in records) {
          if (record is ndef.TextRecord) {
            data += 'Text: ${record.text}\n';
          } else if (record is ndef.UriRecord) {
            data += 'URI: ${record.uri}\n';
          } else if (record is ndef.MimeRecord) {
            data += 'MIME: ${record.type}\n';
            // Try to decode payload as string if it's text-like
            try {
              if (record.payload != null) {
                final payloadStr = String.fromCharCodes(record.payload!);
                if (payloadStr.isNotEmpty && _isPrintableString(payloadStr)) {
                  data += 'Content: $payloadStr\n';
                }
              }
            } catch (e) {
              data += 'Binary content bytes)\n';
            }
          // } else if (record is ndef.WifiSimpleRecord) {
          //   data += 'WiFi: ${record.ssid}\n';
          } else {
            // Generic record
            data += 'Record Type: ${record.decodedType}\n';
            if (record.payload != null && record.payload!.isNotEmpty) {
              try {
                final payloadStr = String.fromCharCodes(record.payload!);
                if (_isPrintableString(payloadStr)) {
                  data += 'Content: $payloadStr\n';
                } else {
                  data += 'Binary data (${record.payload!.length} bytes)\n';
                }
              } catch (e) {
                data += 'Binary data (${record.payload!.length} bytes)\n';
              }
            }
          }
        }
        
        // If no decoded records, try raw records
        if (data.isEmpty) {
          final rawRecords = await FlutterNfcKit.readNDEFRawRecords(cached: false);
          for (var rawRecord in rawRecords) {
            if (rawRecord.payload.isNotEmpty) {
              try {
                // Convert hex string to bytes then to string
                final bytes = _hexStringToBytes(rawRecord.payload);
                final payloadStr = String.fromCharCodes(bytes);
                if (_isPrintableString(payloadStr)) {
                  data += 'Raw Text: $payloadStr\n';
                } else {
                  data += 'Raw Binary: ${rawRecord.payload}\n';
                }
              } catch (e) {
                data += 'Raw Hex: ${rawRecord.payload}\n';
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error reading NDEF data: $e');
      data = 'Error reading NDEF: $e';
    }
    
    return data.trim().isNotEmpty ? data.trim() : 'No NDEF data available';
  }

  List<int> _hexStringToBytes(String hex) {
    List<int> bytes = [];
    for (int i = 0; i < hex.length; i += 2) {
      String hexByte = hex.substring(i, i + 2);
      bytes.add(int.parse(hexByte, radix: 16));
    }
    return bytes;
  }

  bool _isPrintableString(String str) {
    // Check if string contains mostly printable characters
    final printableCount = str.runes.where((rune) => 
      (rune >= 32 && rune <= 126) || // ASCII printable
      rune == 10 || rune == 13 || rune == 9 // newline, carriage return, tab
    ).length;
    
    return printableCount > (str.length * 0.8); // At least 80% printable
  }

  Future<String> _readAdditionalData(NFCTag tag) async {
    String additionalData = '';
    
    try {
      // Read specific tag type data
      if (tag.type == NFCTagType.mifare_classic) {
        try {
          // Try to authenticate and read sector 0
          await FlutterNfcKit.authenticateSector(0, keyA: "FFFFFFFFFFFF");
          final sectorData = await FlutterNfcKit.readSector(0);
          additionalData += 'Sector 0 Data: ${sectorData.join(' ')}\n';
        } catch (e) {
          additionalData += 'MIFARE Classic read failed: $e\n';
        }
      } else if (tag.type == NFCTagType.iso15693) {
        try {
          // Read block 0 from ISO15693 tag
          final blockData = await FlutterNfcKit.readBlock(0);
          additionalData += 'Block 0 Data: ${blockData.join(' ')}\n';
        } catch (e) {
          additionalData += 'ISO15693 read failed: $e\n';
        }
      } else if (tag.type == NFCTagType.iso7816) {
        try {
          // Send APDU command to read basic info
          final result = await FlutterNfcKit.transceive("00B0950000", timeout: const Duration(seconds: 5));
          additionalData += 'APDU Response: $result\n';
        } catch (e) {
          additionalData += 'ISO7816 APDU failed: $e\n';
        }
      }
    } catch (e) {
      additionalData += 'Additional data read error: $e\n';
    }
    
    return additionalData;
  }

  Future<void> _startNfcScan() async {
    if (!_isAvailable || _isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      // Poll for NFC tag with timeout and custom messages
      final tag = await FlutterNfcKit.poll(
        timeout: const Duration(seconds: 60), // Long timeout for continuous scanning
        iosMultipleTagMessage: "Multiple NFC tags detected! Please present only one tag.",
        iosAlertMessage: "NFC Scanner is ready. Hold your device near an NFC tag.",
      );

      if (mounted) {
        _currentTag = tag;
        await _processTag(tag);
      }
    } catch (e) {
      if (mounted) {
        print('NFC scan error: $e');
        
        // Don't show error for timeout or user cancellation
        if (!e.toString().contains('timeout') && 
            !e.toString().contains('cancelled') &&
            !e.toString().contains('Session timeout')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('NFC Error: $e'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        
        // Restart scanning automatically after error
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted && _isAvailable) {
          _startNfcScan();
        }
      }
    }
  }

  Future<void> _processTag(NFCTag tag) async {
    try {
      // Set iOS alert message for processing
      await FlutterNfcKit.setIosAlertMessage("Processing NFC tag...");
      
      // Extract tag information
      String tagId = tag.id.isNotEmpty ? tag.id.toUpperCase() : 'UNKNOWN_ID';
      String nfcType = _determineNfcType(tag);
      String ndefData = await _extractNdefData(tag);
      String additionalData = await _readAdditionalData(tag);
      
      // Create comprehensive data string
      String fullData = 'Type: $nfcType\n';
      fullData += 'ID: $tagId\n';
      fullData += 'Standard: ${tag.standard}\n';
      if (tag.atqa != null) fullData += 'ATQA: ${tag.atqa}\n';
      if (tag.sak != null) fullData += 'SAK: ${tag.sak}\n';
      fullData += 'NDEF Available: ${tag.ndefAvailable}\n';
      fullData += 'NDEF Writable: ${tag.ndefWritable}\n';
      fullData += 'NDEF Data: $ndefData\n';
      if (additionalData.isNotEmpty) {
        fullData += 'Additional Data:\n$additionalData';
      }

      final result = ScanResult(
        id: tagId,
        data: fullData,
        type: ScanType.nfc,
        timestamp: DateTime.now(),
      );

      // Call the callback
      widget.onScanResult(result);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NFC Tag Read Successfully: $nfcType'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      
      // Finish current session with success message
      await FlutterNfcKit.finish(iosAlertMessage: "NFC tag read successfully!");
      
      // Small delay before restarting
      await Future.delayed(const Duration(milliseconds: 1500));
      
      // Restart scanning automatically to maintain priority
      if (mounted && _isAvailable) {
        _startNfcScan();
      }
      
    } catch (e) {
      print('Error processing NFC tag: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing NFC tag: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        
        // Finish session with error message
        await FlutterNfcKit.finish(iosErrorMessage: "Failed to read NFC tag");
        
        // Restart scanning after error
        await Future.delayed(const Duration(milliseconds: 1000));
        if (_isAvailable) {
          _startNfcScan();
        }
      }
    }
  }

  void _stopNfcScan() async {
    if (!_isScanning) return;
    
    setState(() {
      _isScanning = false;
    });
    
    try {
      await FlutterNfcKit.finish(iosAlertMessage: "NFC scanning stopped");
    } catch (e) {
      print('Error stopping NFC session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAvailable) {
      return Card(
        color: AppColors.cardBackground,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                Icons.nfc_rounded,
                size: 48,
                color: AppColors.textLight,
              ),
              const SizedBox(height: 8),
              Text(
                'NFC Scanner',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'NFC not available on this device',
                style: TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: AppColors.cardBackground,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.nfc_rounded,
              size: 48,
              color: _isScanning ? AppColors.primary : AppColors.textLight,
            ),
            const SizedBox(height: 8),
            Text(
              'NFC Scanner',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            if (_isScanning)
              Column(
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 8),
                  Text(
                    'Ready to scan NFC tags...',
                    style: TextStyle(color: AppColors.textLight),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hold your device near an NFC tag',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_currentTag != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Last tag: ${_determineNfcType(_currentTag!)}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _stopNfcScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Stop Scanning'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: _startNfcScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Start NFC Scan'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to start continuous NFC scanning',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}