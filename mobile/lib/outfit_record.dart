
class OutfitRecord {
  final DateTime date;
  final double temp;
  final int uvIndex;
  final double precipitationMm;
  final int precipitationProb;
  final List<String> items;

  OutfitRecord({
    required this.date,
    required this.temp,
    required this.uvIndex,
    required this.precipitationMm,
    required this.precipitationProb,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'temp': temp,
    'uvIndex': uvIndex,
    'precipitationMm': precipitationMm,
    'precipitationProb': precipitationProb,
    'items': items,
  };

  factory OutfitRecord.fromJson(Map<String, dynamic> json) {
    return OutfitRecord(
      date: DateTime.parse(json['date']),
      temp: json['temp'],
      uvIndex: json['uvIndex'],
      precipitationMm: json['precipitationMm'],
      precipitationProb: json['precipitationProb'],
      items: List<String>.from(json['items']),
    );
  }
}