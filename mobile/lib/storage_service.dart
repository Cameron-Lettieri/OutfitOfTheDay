import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'outfit_record.dart';

class StorageService {
  static const _key = 'outfit_history';
  static const _wardrobeKey = 'wardrobe_catalog';

  /// Save a new record to local history
  static Future<void> saveRecord(OutfitRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    raw.add(jsonEncode(record.toJson()));
    await prefs.setStringList(_key, raw);
  }

  /// Load all saved records
  static Future<List<OutfitRecord>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((str) => OutfitRecord.fromJson(jsonDecode(str)))
        .toList();
  }

  /// Load wardrobe catalog grouped by category
  static Future<Map<String, List<String>>> loadWardrobe() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_wardrobeKey);
    if (raw == null) {
      return {
        'tops': [],
        'bottoms': [],
        'shoes': [],
        'outerwear': [],
        'accessories': [],
      };
    }
    final Map<String, dynamic> data = jsonDecode(raw);
    return data.map((k, v) => MapEntry(k, List<String>.from(v)));
  }

  /// Persist wardrobe catalog locally
  static Future<void> saveWardrobe(Map<String, List<String>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_wardrobeKey, jsonEncode(data));
  }
}