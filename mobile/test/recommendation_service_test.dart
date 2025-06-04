import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/recommendation_service.dart';
import 'package:mobile/storage_service.dart';
import 'package:mobile/outfit_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('recommend picks frequent items from similar weather', () async {
    final r1 = OutfitRecord(
      date: DateTime.parse('2024-01-01T00:00:00Z'),
      temp: 70,
      uvIndex: 5,
      precipitationMm: 0,
      precipitationProb: 20,
      items: ['hat', 'shirt'],
    );
    final r2 = OutfitRecord(
      date: DateTime.parse('2024-01-02T00:00:00Z'),
      temp: 72,
      uvIndex: 4,
      precipitationMm: 0,
      precipitationProb: 20,
      items: ['hat', 'pants'],
    );
    final r3 = OutfitRecord(
      date: DateTime.parse('2024-01-03T00:00:00Z'),
      temp: 85,
      uvIndex: 8,
      precipitationMm: 0,
      precipitationProb: 0,
      items: ['sunglasses'],
    );

    await StorageService.saveRecord(r1);
    await StorageService.saveRecord(r2);
    await StorageService.saveRecord(r3);

    final recs = await RecommendationService.recommend(
      temp: 71,
      uvIndex: 5,
      precipitationMm: 0,
      precipitationProb: 20,
      topN: 2,
    );

    expect(recs.contains('hat'), true);
    expect(recs.length, 2);
  });
}
