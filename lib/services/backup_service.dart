import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../SQLite/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Create a backup of all data
  Future<bool> createBackup() async {
    try {
      // Get all data from database
      final backupData = await _dbHelper.getDatabaseBackup();

      // Add metadata
      final metadata = {
        'backup_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'data_version': '1.0',
        'tables': backupData.keys.toList(),
        'record_counts': <String, int>{},
      };

      // Count records in each table
      for (String table in backupData.keys) {
        final tableData = backupData[table];
        if (tableData != null) {
          (metadata['record_counts'] as Map<String, int>)[table] =
              tableData.length;
        }
      }

      // Create complete backup
      final completeBackup = {'metadata': metadata, 'data': backupData};

      // Convert to JSON
      final jsonData = jsonEncode(completeBackup);

      // Get backup directory
      final backupDir = await _getBackupDirectory();
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Create backup file
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupFile = File('${backupDir.path}/xtap_backup_$timestamp.json');

      // Write backup to file
      await backupFile.writeAsString(jsonData);

      // Save backup info to preferences
      await _saveBackupInfo(backupFile.path, metadata);

      print('Backup created successfully: ${backupFile.path}');
      return true;
    } catch (e) {
      print('Error creating backup: $e');
      return false;
    }
  }

  /// Restore data from backup
  Future<bool> restoreBackup() async {
    try {
      // Get latest backup file
      final backupFile = await _getLatestBackupFile();
      if (backupFile == null) {
        print('No backup file found');
        return false;
      }

      // Read backup file
      final jsonData = await backupFile.readAsString();
      final backupData = jsonDecode(jsonData) as Map<String, dynamic>;

      // Validate backup structure
      if (!_validateBackupStructure(backupData)) {
        print('Invalid backup structure');
        return false;
      }

      // Clear current data
      await _dbHelper.clearAllData();

      // Restore data
      final data = backupData['data'] as Map<String, dynamic>;
      await _restoreData(data);

      print('Backup restored successfully');
      return true;
    } catch (e) {
      print('Error restoring backup: $e');
      return false;
    }
  }

  /// Get list of available backups
  Future<List<Map<String, dynamic>>> getAvailableBackups() async {
    try {
      final backupDir = await _getBackupDirectory();
      if (!await backupDir.exists()) {
        return [];
      }

      final files = backupDir.listSync();
      final backups = <Map<String, dynamic>>[];

      for (final file in files) {
        if (file is File && file.path.endsWith('.json')) {
          try {
            final jsonData = await file.readAsString();
            final backupData = jsonDecode(jsonData) as Map<String, dynamic>;
            final metadata = backupData['metadata'] as Map<String, dynamic>;

            backups.add({
              'file_path': file.path,
              'file_name': file.path.split('/').last,
              'backup_date': metadata['backup_date'],
              'record_counts': metadata['record_counts'],
              'file_size': await file.length(),
            });
          } catch (e) {
            print('Error reading backup file ${file.path}: $e');
          }
        }
      }

      // Sort by date (newest first)
      backups.sort((a, b) => b['backup_date'].compareTo(a['backup_date']));

      return backups;
    } catch (e) {
      print('Error getting available backups: $e');
      return [];
    }
  }

  /// Delete a specific backup
  Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('Backup deleted: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting backup: $e');
      return false;
    }
  }

  /// Export backup to external storage
  Future<String?> exportBackup(String filePath) async {
    try {
      final sourceFile = File(filePath);
      if (!await sourceFile.exists()) {
        return null;
      }

      // Get external storage directory
      final externalDir = await getExternalStorageDirectory();
      if (externalDir == null) {
        return null;
      }

      final fileName = filePath.split('/').last;
      final exportPath = '${externalDir.path}/$fileName';
      final exportFile = File(exportPath);

      // Copy file
      await sourceFile.copy(exportPath);

      print('Backup exported to: $exportPath');
      return exportPath;
    } catch (e) {
      print('Error exporting backup: $e');
      return null;
    }
  }

  /// Import backup from external storage
  Future<bool> importBackup(String filePath) async {
    try {
      final sourceFile = File(filePath);
      if (!await sourceFile.exists()) {
        return false;
      }

      // Validate backup file
      final jsonData = await sourceFile.readAsString();
      final backupData = jsonDecode(jsonData) as Map<String, dynamic>;

      if (!_validateBackupStructure(backupData)) {
        return false;
      }

      // Copy to backup directory
      final backupDir = await _getBackupDirectory();
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final fileName = filePath.split('/').last;
      final backupPath = '${backupDir.path}/$fileName';
      final backupFile = File(backupPath);

      await sourceFile.copy(backupPath);

      // Save backup info
      final metadata = backupData['metadata'] as Map<String, dynamic>;
      await _saveBackupInfo(backupPath, metadata);

      print('Backup imported: $backupPath');
      return true;
    } catch (e) {
      print('Error importing backup: $e');
      return false;
    }
  }

  /// Get backup directory
  Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/backups');
  }

  /// Get latest backup file
  Future<File?> _getLatestBackupFile() async {
    final backups = await getAvailableBackups();
    if (backups.isEmpty) {
      return null;
    }

    final latestBackup = backups.first;
    return File(latestBackup['file_path']);
  }

  /// Validate backup structure
  bool _validateBackupStructure(Map<String, dynamic> backupData) {
    return backupData.containsKey('metadata') &&
        backupData.containsKey('data') &&
        backupData['metadata'] is Map<String, dynamic> &&
        backupData['data'] is Map<String, dynamic>;
  }

  /// Restore data to database
  Future<void> _restoreData(Map<String, dynamic> data) async {
    final db = await _dbHelper.database;
    final batch = db.batch();

    // Restore in order of dependencies
    final tables = [
      'users',
      'levels',
      'classes',
      'students',
      'attendance_logs',
      'payments',
      'discipline',
      'holidays',
    ];

    for (String table in tables) {
      if (data.containsKey(table)) {
        final tableData = data[table] as List<dynamic>;
        for (final record in tableData) {
          batch.insert(table, record as Map<String, dynamic>);
        }
      }
    }

    await batch.commit(noResult: true);
  }

  /// Save backup info to preferences
  Future<void> _saveBackupInfo(
    String filePath,
    Map<String, dynamic> metadata,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupInfo = {
        'file_path': filePath,
        'backup_date': metadata['backup_date'],
        'record_counts': metadata['record_counts'],
      };

      await prefs.setString('last_backup_info', jsonEncode(backupInfo));
    } catch (e) {
      print('Error saving backup info: $e');
    }
  }

  /// Get last backup info
  Future<Map<String, dynamic>?> getLastBackupInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupInfoString = prefs.getString('last_backup_info');

      if (backupInfoString != null) {
        return jsonDecode(backupInfoString) as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      print('Error getting last backup info: $e');
      return null;
    }
  }

  /// Get backup statistics
  Future<Map<String, dynamic>> getBackupStatistics() async {
    try {
      final backups = await getAvailableBackups();
      final lastBackupInfo = await getLastBackupInfo();

      int totalSize = 0;
      for (final backup in backups) {
        totalSize += backup['file_size'] as int;
      }

      return {
        'total_backups': backups.length,
        'total_size': totalSize,
        'last_backup': lastBackupInfo?['backup_date'],
        'oldest_backup':
            backups.isNotEmpty ? backups.last['backup_date'] : null,
      };
    } catch (e) {
      print('Error getting backup statistics: $e');
      return {};
    }
  }
}
