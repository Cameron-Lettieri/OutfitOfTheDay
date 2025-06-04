import 'storage_service.dart';

class RecommendationService {
  /// Return top N items historically worn in similar weather
  static Future<List<String>> recommend({
    required double temp,
    required int uvIndex,
    required double precipitationMm,
    required int precipitationProb,
    int topN = 5,
  }) async {
    final history = await StorageService.loadHistory();

    // Filter by "close enough" weather: within ±5°F, same rain class, etc.
    final filtered = history.where((r) {
      return (r.temp - temp).abs() <= 5
          && (r.precipitationProb == precipitationProb)
          && (r.uvIndex - uvIndex).abs() <= 2;
    }).toList();

    final freq = <String, int>{};
    for (var rec in filtered) {
      for (var item in rec.items) {
        freq[item] = (freq[item] ?? 0) + 1;
      }
    }

    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(topN).map((e) => e.key).toList();
  }
}