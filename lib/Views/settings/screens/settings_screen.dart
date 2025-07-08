import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite_crud_app/constants/app_colors.dart';
import 'package:sqlite_crud_app/utils/theme_provider.dart';
import 'package:sqlite_crud_app/utils/user_session.dart';
import 'package:sqlite_crud_app/SQLite/database_helper.dart';
import 'package:sqlite_crud_app/services/sync_service.dart';
import 'package:sqlite_crud_app/services/backup_service.dart';
import 'package:sqlite_crud_app/Components/app_bar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../../services/holiday_service.dart';
import '../../../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final HolidayService _holidayService = HolidayService();
  final NotificationService _notificationService = NotificationService();
  late SyncService _syncService;
  bool _syncServiceReady = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _isBiometricEnabled = false;
  bool _isAutoSyncEnabled = true;
  bool _isNotificationsEnabled = true;
  bool _isLoading = false;
  bool _showHolidayCalendar = false;

  // Holiday management
  List<Holiday> _holidays = [];
  DateTime _selectedHolidayDate = DateTime.now();
  final TextEditingController _holidayNameController = TextEditingController();
  final TextEditingController _holidayDescriptionController =
      TextEditingController();
  bool _isRecurringHoliday = false;

  // Attendance time settings
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  int _lateThreshold = 15;
  int _absenceThreshold = 30;

  @override
  void initState() {
    super.initState();
    _initSyncService();
    _loadSettings();
    _loadHolidays();
    _loadAttendanceSettings();
  }

  @override
  void dispose() {
    _holidayNameController.dispose();
    _holidayDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _initSyncService() async {
    try {
      await SyncService.instance.initialize();
      setState(() {
        _syncService = SyncService.instance;
        _syncServiceReady = true;
      });
    } catch (e) {
      print('Error initializing sync service: $e');
      setState(() {
        _syncServiceReady = false;
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isBiometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _isAutoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? true;
      _isNotificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _loadHolidays() async {
    try {
      final holidays = await _holidayService.getHolidays();
      setState(() {
        _holidays = holidays;
      });
    } catch (e) {
      print('Error loading holidays: $e');
    }
  }

  Future<void> _loadAttendanceSettings() async {
    final startTime = await _holidayService.getAttendanceStartTime();
    final lateThreshold = await _holidayService.getLateThreshold();
    final absenceThreshold = await _holidayService.getAbsenceThreshold();

    setState(() {
      _startTime = startTime;
      _lateThreshold = lateThreshold;
      _absenceThreshold = absenceThreshold;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', _isBiometricEnabled);
    await prefs.setBool('auto_sync_enabled', _isAutoSyncEnabled);
    await prefs.setBool('notifications_enabled', _isNotificationsEnabled);

    if (mounted) {
      _showSnackBar('Settings saved successfully', AppColors.success);
    }
  }

  Future<void> _toggleBiometric() async {
    final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;

    if (!canAuthenticateWithBiometrics) {
      _showSnackBar('Biometric authentication not available', AppColors.error);
      return;
    }

    setState(() {
      _isBiometricEnabled = !_isBiometricEnabled;
    });
    await _saveSettings();
  }

  Future<void> _performSync() async {
    if (!_syncServiceReady) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final result = await _syncService.syncAllData();
      if (result.isSuccess) {
        _showSnackBar('Sync completed: ${result.message}', AppColors.success);
      } else {
        _showSnackBar(
          'Sync failed: ${result.error ?? result.message}',
          AppColors.error,
        );
      }
    } catch (e) {
      _showSnackBar('Sync error: $e', AppColors.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addHoliday() async {
    if (_holidayNameController.text.trim().isEmpty) {
      _showSnackBar('Please enter a holiday name', AppColors.error);
      return;
    }

    final holiday = Holiday(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _holidayNameController.text.trim(),
      date: _selectedHolidayDate,
      description:
          _holidayDescriptionController.text.trim().isEmpty
              ? null
              : _holidayDescriptionController.text.trim(),
      isRecurring: _isRecurringHoliday,
    );

    await _holidayService.addHoliday(holiday);
    await _loadHolidays();

    _holidayNameController.clear();
    _holidayDescriptionController.clear();
    setState(() {
      _isRecurringHoliday = false;
    });

    _showSnackBar('Holiday added successfully', AppColors.success);
  }

  Future<void> _removeHoliday(String holidayId) async {
    await _holidayService.removeHoliday(holidayId);
    await _loadHolidays();
    _showSnackBar('Holiday removed successfully', AppColors.success);
  }

  Future<void> _saveAttendanceSettings() async {
    await _holidayService.setAttendanceStartTime(_startTime);
    await _holidayService.setLateThreshold(_lateThreshold);
    await _holidayService.setAbsenceThreshold(_absenceThreshold);
    _showSnackBar('Attendance settings saved', AppColors.success);
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(isDarkMode),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionCard(
              title: 'Authentication',
              icon: Icons.security,
              children: [
                _buildSwitchTile(
                  title: 'Biometric Login',
                  subtitle: 'Use fingerprint or face ID',
                  value: _isBiometricEnabled,
                  onChanged: (value) => _toggleBiometric(),
                  icon: Icons.fingerprint,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Attendance Settings',
              icon: Icons.schedule,
              children: [
                _buildTimeTile(
                  title: 'Start Time',
                  subtitle: 'School attendance start time',
                  value: _startTime,
                  onChanged: (time) {
                    setState(() {
                      _startTime = time;
                    });
                    _saveAttendanceSettings();
                  },
                ),
                _buildSliderTile(
                  title: 'Late Threshold',
                  subtitle: 'Minutes after start time',
                  value: _lateThreshold.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  onChanged: (value) {
                    setState(() {
                      _lateThreshold = value.round();
                    });
                    _saveAttendanceSettings();
                  },
                ),
                _buildSliderTile(
                  title: 'Absence Threshold',
                  subtitle: 'Minutes after start time',
                  value: _absenceThreshold.toDouble(),
                  min: 15,
                  max: 120,
                  divisions: 21,
                  onChanged: (value) {
                    setState(() {
                      _absenceThreshold = value.round();
                    });
                    _saveAttendanceSettings();
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Holiday Management',
              icon: Icons.calendar_today,
              children: [
                _buildButtonTile(
                  title: 'Manage Holidays',
                  subtitle: 'Set school holidays and breaks',
                  icon: Icons.event,
                  onTap: () {
                    setState(() {
                      _showHolidayCalendar = !_showHolidayCalendar;
                    });
                  },
                ),
                if (_showHolidayCalendar) ...[
                  const SizedBox(height: 16),
                  _buildHolidayCalendar(),
                ],
              ],
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'System Testing',
              icon: Icons.bug_report,
              children: [
                _buildButtonTile(
                  title: 'Test Sync System',
                  subtitle: 'Test the new offline-first sync system',
                  icon: Icons.sync,
                  onTap: () {
                    Navigator.pushNamed(context, '/test-sync');
                  },
                ),
                _buildButtonTile(
                  title: 'Test Firebase Connection',
                  subtitle: 'Test Firebase connectivity',
                  icon: Icons.cloud,
                  onTap: () {
                    Navigator.pushNamed(context, '/test-firebase');
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Synchronization',
              icon: Icons.sync,
              children: [
                _buildSwitchTile(
                  title: 'Auto Sync',
                  subtitle: 'Automatically sync data when online',
                  value: _isAutoSyncEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isAutoSyncEnabled = value;
                    });
                    _saveSettings();
                  },
                  icon: Icons.sync,
                ),
                _buildButtonTile(
                  title: 'Manual Sync',
                  subtitle: 'Sync data now',
                  icon: Icons.sync_alt,
                  onTap: _isLoading ? () {} : () => _performSync(),
                  trailing:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : null,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Notifications',
              icon: Icons.notifications,
              children: [
                _buildSwitchTile(
                  title: 'Enable Notifications',
                  subtitle: 'Receive attendance and sync notifications',
                  value: _isNotificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _isNotificationsEnabled = value;
                    });
                    _saveSettings();
                  },
                  icon: Icons.notifications_active,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Appearance',
              icon: Icons.palette,
              children: [
                _buildSwitchTile(
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme',
                  value: isDarkMode,
                  onChanged: (value) {
                    themeProvider.toggleTheme();
                  },
                  icon: Icons.dark_mode,
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getCardBackgroundColor(isDarkMode),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getPrimaryTextColor(isDarkMode),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.getSecondaryTextColor(isDarkMode),
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.getPrimaryTextColor(isDarkMode),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.getSecondaryTextColor(isDarkMode)),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildButtonTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.getSecondaryTextColor(isDarkMode),
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.getPrimaryTextColor(isDarkMode),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.getSecondaryTextColor(isDarkMode)),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildTimeTile({
    required String title,
    required String subtitle,
    required TimeOfDay value,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return ListTile(
      leading: Icon(
        Icons.access_time,
        color: AppColors.getSecondaryTextColor(isDarkMode),
        size: 20,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.getPrimaryTextColor(isDarkMode),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: AppColors.getSecondaryTextColor(isDarkMode)),
      ),
      trailing: Text(
        value.format(context),
        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
      onTap: () async {
        final time = await showTimePicker(context: context, initialTime: value);
        if (time != null) {
          onChanged(time);
        }
      },
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(
            Icons.timer,
            color: AppColors.getSecondaryTextColor(isDarkMode),
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.getPrimaryTextColor(isDarkMode),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              color: AppColors.getSecondaryTextColor(isDarkMode),
            ),
          ),
          trailing: Text(
            '${value.round()} min',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.getDividerColor(isDarkMode),
          ),
        ),
      ],
    );
  }

  Widget _buildHolidayCalendar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getInputBackgroundColor(isDarkMode),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.getBorderColor(isDarkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Holiday',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.getPrimaryTextColor(isDarkMode),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _holidayNameController,
            decoration: InputDecoration(
              labelText: 'Holiday Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: AppColors.getSurfaceColor(isDarkMode),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _holidayDescriptionController,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: AppColors.getSurfaceColor(isDarkMode),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _selectedHolidayDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedHolidayDate = date;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_today),
                  label: Text(
                    DateFormat('MMM dd, yyyy').format(_selectedHolidayDate),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  Checkbox(
                    value: _isRecurringHoliday,
                    onChanged: (value) {
                      setState(() {
                        _isRecurringHoliday = value ?? false;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                  const Text('Recurring'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addHoliday,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add Holiday'),
            ),
          ),
          const SizedBox(height: 16),
          if (_holidays.isNotEmpty) ...[
            Text(
              'Current Holidays',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.getPrimaryTextColor(isDarkMode),
              ),
            ),
            const SizedBox(height: 8),
            ...(_holidays
                .map(
                  (holiday) => Card(
                    child: ListTile(
                      title: Text(holiday.name),
                      subtitle: Text(
                        '${DateFormat('MMM dd, yyyy').format(holiday.date)}${holiday.isRecurring ? ' (Recurring)' : ''}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () => _removeHoliday(holiday.id),
                      ),
                    ),
                  ),
                )
                .toList()),
          ],
        ],
      ),
    );
  }
}
