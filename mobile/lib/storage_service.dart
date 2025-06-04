import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'outfit_record.dart';

class StorageService {
  static const _key = 'outfit_history';

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
}