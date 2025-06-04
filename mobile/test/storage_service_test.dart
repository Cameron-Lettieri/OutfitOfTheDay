import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/storage_service.dart';
import 'package:mobile/outfit_record.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save and load record', () async {
    final record = OutfitRecord(
      date: DateTime.parse('2024-01-01T00:00:00Z'),
      temp: 70,
      uvIndex: 5,
      precipitationMm: 0,
      precipitationProb: 10,
      items: ['hat', 'shirt'],
    );

    await StorageService.saveRecord(record);
    final history = await StorageService.loadHistory();

    expect(history.length, 1);
    expect(history.first.temp, 70);
    expect(history.first.items, ['hat', 'shirt']);
  });
}
