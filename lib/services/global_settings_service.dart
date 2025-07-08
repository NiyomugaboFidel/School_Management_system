import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalSettingsService {
  final FirebaseFirestore firestore;
  static const String _settingsCollection = 'settings';
  static const String _settingsDoc = 'global';

  GlobalSettingsService({required this.firestore});

  // Fetch settings from Firestore and cache locally
  Future<Map<String, dynamic>> fetchSettings() async {
    final doc =
        await firestore.collection(_settingsCollection).doc(_settingsDoc).get();
    final data = doc.data() ?? {};
    final prefs = await SharedPreferences.getInstance();
    data.forEach((key, value) => prefs.setString(key, value.toString()));
    return data;
  }

  // Get a setting (from cache if available)
  Future<String?> getSetting(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Set a setting (updates Firestore and cache)
  Future<void> setSetting(String key, String value) async {
    await firestore.collection(_settingsCollection).doc(_settingsDoc).set({
      key: value,
    }, SetOptions(merge: true));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // Listen for changes in Firestore and update cache
  void listenForChanges() {
    firestore
        .collection(_settingsCollection)
        .doc(_settingsDoc)
        .snapshots()
        .listen((doc) async {
          final data = doc.data() ?? {};
          final prefs = await SharedPreferences.getInstance();
          data.forEach((key, value) => prefs.setString(key, value.toString()));
        });
  }
}
