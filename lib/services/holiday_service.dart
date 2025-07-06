import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Holiday {
  final String id;
  final String name;
  final DateTime date;
  final String? description;
  final bool isRecurring;

  Holiday({
    required this.id,
    required this.name,
    required this.date,
    this.description,
    this.isRecurring = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'date': date.toIso8601String(),
      'description': description,
      'isRecurring': isRecurring,
    };
  }

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['id'],
      name: json['name'],
      date: DateTime.parse(json['date']),
      description: json['description'],
      isRecurring: json['isRecurring'] ?? false,
    );
  }
}

class HolidayService {
  static final HolidayService _instance = HolidayService._internal();
  factory HolidayService() => _instance;
  HolidayService._internal();

  static const String _holidaysKey = 'school_holidays';
  static const String _attendanceStartTimeKey = 'attendance_start_time';
  static const String _lateThresholdKey = 'late_threshold';
  static const String _absenceThresholdKey = 'absence_threshold';

  /// Get all holidays
  Future<List<Holiday>> getHolidays() async {
    final prefs = await SharedPreferences.getInstance();
    final holidaysJson = prefs.getStringList(_holidaysKey) ?? [];

    return holidaysJson
        .map((json) => Holiday.fromJson(jsonDecode(json)))
        .toList();
  }

  /// Add a new holiday
  Future<void> addHoliday(Holiday holiday) async {
    final prefs = await SharedPreferences.getInstance();
    final holidays = await getHolidays();

    // Check if holiday already exists for this date
    final existingIndex = holidays.indexWhere(
      (h) =>
          h.date.year == holiday.date.year &&
          h.date.month == holiday.date.month &&
          h.date.day == holiday.date.day,
    );

    if (existingIndex != -1) {
      holidays[existingIndex] = holiday;
    } else {
      holidays.add(holiday);
    }

    final holidaysJson = holidays.map((h) => jsonEncode(h.toJson())).toList();
    await prefs.setStringList(_holidaysKey, holidaysJson);
  }

  /// Remove a holiday
  Future<void> removeHoliday(String holidayId) async {
    final prefs = await SharedPreferences.getInstance();
    final holidays = await getHolidays();

    holidays.removeWhere((h) => h.id == holidayId);

    final holidaysJson = holidays.map((h) => jsonEncode(h.toJson())).toList();
    await prefs.setStringList(_holidaysKey, holidaysJson);
  }

  /// Check if a date is a holiday
  Future<bool> isHoliday(DateTime date) async {
    final holidays = await getHolidays();

    return holidays.any((holiday) {
      if (holiday.isRecurring) {
        // For recurring holidays, check month and day only
        return holiday.date.month == date.month && holiday.date.day == date.day;
      } else {
        // For non-recurring holidays, check exact date
        return holiday.date.year == date.year &&
            holiday.date.month == date.month &&
            holiday.date.day == date.day;
      }
    });
  }

  /// Get holiday name for a specific date
  Future<String?> getHolidayName(DateTime date) async {
    final holidays = await getHolidays();

    for (final holiday in holidays) {
      if (holiday.isRecurring) {
        if (holiday.date.month == date.month && holiday.date.day == date.day) {
          return holiday.name;
        }
      } else {
        if (holiday.date.year == date.year &&
            holiday.date.month == date.month &&
            holiday.date.day == date.day) {
          return holiday.name;
        }
      }
    }

    return null;
  }

  /// Get attendance start time
  Future<TimeOfDay> getAttendanceStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_attendanceStartTimeKey) ?? '08:00';
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  /// Set attendance start time
  Future<void> setAttendanceStartTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    final timeString =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    await prefs.setString(_attendanceStartTimeKey, timeString);
  }

  /// Get late threshold (minutes after start time)
  Future<int> getLateThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lateThresholdKey) ?? 15; // Default 15 minutes
  }

  /// Set late threshold
  Future<void> setLateThreshold(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lateThresholdKey, minutes);
  }

  /// Get absence threshold (minutes after start time)
  Future<int> getAbsenceThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_absenceThresholdKey) ?? 30; // Default 30 minutes
  }

  /// Set absence threshold
  Future<void> setAbsenceThreshold(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_absenceThresholdKey, minutes);
  }

  /// Determine attendance status based on time
  Future<String> getAttendanceStatus(DateTime checkInTime) async {
    final startTime = await getAttendanceStartTime();
    final lateThreshold = await getLateThreshold();
    final absenceThreshold = await getAbsenceThreshold();

    final startDateTime = DateTime(
      checkInTime.year,
      checkInTime.month,
      checkInTime.day,
      startTime.hour,
      startTime.minute,
    );

    final lateDateTime = startDateTime.add(Duration(minutes: lateThreshold));
    final absenceDateTime = startDateTime.add(
      Duration(minutes: absenceThreshold),
    );

    if (checkInTime.isBefore(startDateTime)) {
      return 'present';
    } else if (checkInTime.isBefore(lateDateTime)) {
      return 'late';
    } else if (checkInTime.isBefore(absenceDateTime)) {
      return 'late';
    } else {
      return 'absent';
    }
  }

  /// Get holidays for a specific month
  Future<List<Holiday>> getHolidaysForMonth(DateTime month) async {
    final holidays = await getHolidays();

    return holidays.where((holiday) {
      if (holiday.isRecurring) {
        return holiday.date.month == month.month;
      } else {
        return holiday.date.year == month.year &&
            holiday.date.month == month.month;
      }
    }).toList();
  }

  /// Clear all holidays
  Future<void> clearAllHolidays() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_holidaysKey);
  }

  /// Export holidays to JSON
  Future<String> exportHolidays() async {
    final holidays = await getHolidays();
    return jsonEncode(holidays.map((h) => h.toJson()).toList());
  }

  /// Import holidays from JSON
  Future<void> importHolidays(String jsonString) async {
    final List<dynamic> holidaysJson = jsonDecode(jsonString);
    final holidays =
        holidaysJson.map((json) => Holiday.fromJson(json)).toList();

    final prefs = await SharedPreferences.getInstance();
    final holidaysJsonList =
        holidays.map((h) => jsonEncode(h.toJson())).toList();
    await prefs.setStringList(_holidaysKey, holidaysJsonList);
  }
}

// Using Flutter's TimeOfDay instead of custom implementation
