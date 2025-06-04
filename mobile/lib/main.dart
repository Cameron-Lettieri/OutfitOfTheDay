import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'wardrobe_page.dart';
import 'package:weather_icons/weather_icons.dart';
import 'recommendation_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(WeatherStyleApp());
}

class WeatherStyleApp extends StatelessWidget {
  const WeatherStyleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Outfit of the Day',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: WeatherPage(),
    );
  }
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  String? city;
  String? weather;
  double? actualTemperature;
  double? feelsLikeTemperature;
  double? highTemp;
  double? lowTemp;
  double? humidity;
  double? cloudCover;
  double? windSpeed;
  double? precipitation;
  int? rainChance;
  int? uvIndex;
  List<dynamic>? outfitMorning;
  List<dynamic>? outfitAfternoon;
  List<dynamic>? outfitNight;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRecommendation();
  }

  Future<void> showNotification(String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'weather_channel_id',
      'Weather Alerts',
      channelDescription: 'Daily outfit suggestions',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(
      0,
      '🌤️ Today’s Outfit Recommendation',
      message,
      platformDetails,
    );
  }

  Future<void> fetchRecommendation() async {
    setState(() => loading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final response = await http.get(Uri.parse(
        'http://127.0.0.1:5000/recommend?lat=${position.latitude}&lon=${position.longitude}&units=imperial'
      ));
      if (response.statusCode != 200) {
        throw Exception('Failed to load weather data (${response.statusCode})');
      }
      final data = jsonDecode(response.body);

      // 1️⃣ Update base weather & outfit from backend
      setState(() {
        city = data['location'] as String?;
        weather = data['weather'] as String?;
        actualTemperature = (data['actual_temperature'] as num?)?.toDouble();
        feelsLikeTemperature = (data['feels_like_temperature'] as num?)?.toDouble();
        highTemp = (data['high_temp'] as num?)?.toDouble();
        lowTemp = (data['low_temp'] as num?)?.toDouble();
        humidity = (data['humidity'] as num?)?.toDouble();
        cloudCover = (data['cloud_cover'] as num?)?.toDouble();
        windSpeed = (data['wind_speed'] as num?)?.toDouble();
        precipitation = (data['precipitation'] as num?)?.toDouble();
        rainChance = (data['rain_chance'] as num?)?.toInt();
        uvIndex = (data['uv_index'] as num?)?.toInt();
        
        // base outfit suggestions
        List<dynamic> baseOutfit = List<dynamic>.from(data['outfit'] ?? []);
        outfitMorning = data['outfit_morning'] != null
            ? List<dynamic>.from(data['outfit_morning'])
            : baseOutfit;
        outfitAfternoon = data['outfit_afternoon'] != null
            ? List<dynamic>.from(data['outfit_afternoon'])
            : baseOutfit;
        outfitNight = data['outfit_night'] != null
            ? List<dynamic>.from(data['outfit_night'])
            : baseOutfit;

        loading = false;
      });

      // 2️⃣ Personalized history override
      final recs = await RecommendationService.recommend(
        temp: feelsLikeTemperature ?? actualTemperature ?? 0.0,
        uvIndex: uvIndex ?? 0,
        precipitationMm: precipitation ?? 0.0,
        precipitationProb: rainChance ?? 0,
        topN: 5,
      );
      if (recs.isNotEmpty) {
        setState(() {
          outfitMorning = recs;
          outfitAfternoon = recs;
          outfitNight = recs;
        });
      }

      // 3️⃣ Notification
      String outfitList = (outfitMorning ?? []).join(', ');
      await showNotification(
        "Feels like ${feelsLikeTemperature?.ceil()}°F in $city. Outfit: $outfitList",
      );
    } catch (e) {
      print('Error in fetchRecommendation: $e');
      setState(() => loading = false);
    }
  }

  String getDailySummary() {
    if (feelsLikeTemperature == null || cloudCover == null || windSpeed == null) return "";
    String summary = "It will feel like ${feelsLikeTemperature!.ceil()}°F. ";
    if (cloudCover! > 70) {
      summary += "Expect overcast skies. ";
    } else if (cloudCover! > 30) summary += "Partly cloudy throughout the day. ";
    else summary += "Plenty of sunshine today. ";
    if (windSpeed! > 15) summary += "It may be windy, so plan accordingly. ";
    if (precipitation! > 1) summary += "Carry an umbrella just in case.";
    return summary;
  }

  Widget buildOutfitSection(String label, List<dynamic>? outfit, Color color) {
    return Card(
      color: Colors.black.withOpacity(0.4),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            SizedBox(height: 6),
            ...?outfit?.map((item) => Text("- $item", style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  String getBackgroundImage() {
    String timezone = DateTime.now().timeZoneName.toLowerCase();
    if (timezone.contains('central')) return 'assets/images/chicago.jpg';
    if (timezone.contains('eastern')) return 'assets/images/new_york.jpg';
    if (timezone.contains('pacific')) return 'assets/images/los_angeles.jpg';
    if (timezone.contains('gmt') || timezone.contains('british')) return 'assets/images/london.jpg';
    if (timezone.contains('paris') || timezone.contains('cet')) return 'assets/images/paris.jpg';
    if (timezone.contains('tokyo') || timezone.contains('japan')) return 'assets/images/tokyo.jpg';
    return 'assets/images/default.jpg';
  }

  IconData getWeatherIcon() {
    if (precipitation != null && precipitation! > 2) return WeatherIcons.rain;
    if (cloudCover != null && cloudCover! > 80) return WeatherIcons.cloudy;
    if (cloudCover != null && cloudCover! > 40) return WeatherIcons.day_cloudy;
    if (windSpeed != null && windSpeed! > 20) return WeatherIcons.strong_wind;
    return WeatherIcons.day_sunny;
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor;
    if (feelsLikeTemperature != null) {
      if (feelsLikeTemperature! < 40) {
        themeColor = Colors.blue.shade800;
      } else if (feelsLikeTemperature! < 60) themeColor = Colors.cyan.shade700;
      else if (feelsLikeTemperature! < 75) themeColor = Colors.green.shade600;
      else if (feelsLikeTemperature! < 90) themeColor = Colors.orange.shade700;
      else themeColor = Colors.red.shade700;
    } else {
      themeColor = Colors.grey;
    }

    return Scaffold(
      backgroundColor: themeColor.withOpacity(0.1),
      appBar: AppBar(
        title: Text('Outfit of the Day'),
        backgroundColor: themeColor,
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            getBackgroundImage(),
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.3),
            colorBlendMode: BlendMode.darken,
          ),
          loading
              ? Center(child: SpinKitFadingCircle(color: themeColor, size: 50.0))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Card(
                        color: Colors.black.withOpacity(0.4),
                        margin: EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              TweenAnimationBuilder(
                                tween: Tween<double>(begin: 0.8, end: 1.0),
                                duration: Duration(seconds: 2),
                                curve: Curves.elasticOut,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: Icon(getWeatherIcon(), size: 48, color: themeColor),
                                  );
                                },
                              ),
                              SizedBox(height: 10),
                              Text('📍 $city',
                                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: themeColor)),
                              Text('High: ${highTemp?.ceil()}°F / Low: ${lowTemp?.ceil()}°F',
                                  style: TextStyle(fontSize: 16, color: Colors.white)),
                              Text('Temperature: ${actualTemperature?.ceil()} °F',
                                  style: TextStyle(fontSize: 16, color: Colors.white)),
                              Text('Feels Like: ${feelsLikeTemperature?.ceil()} °F',
                                  style: TextStyle(fontSize: 16, color: Colors.white)),
                              SizedBox(height: 10),
                              Text(getDailySummary(),
                                  style: TextStyle(fontSize: 14, color: Colors.white), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        color: Colors.black.withOpacity(0.4),
                        margin: EdgeInsets.symmetric(vertical: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('🌦 Weather Details',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              SizedBox(height: 10),
                              Text('💧 Humidity: ${humidity?.toStringAsFixed(0)}%', style: TextStyle(color: Colors.white)),
                              Text('☁️ Cloud Cover: ${cloudCover?.toStringAsFixed(0)}%', style: TextStyle(color: Colors.white)),
                              Text('🌬 Wind: ${windSpeed?.toStringAsFixed(1)} mph', style: TextStyle(color: Colors.white)),
                              Text('🌧 Precipitation: ${precipitation?.toStringAsFixed(1)} mm (${rainChance ?? 0}%)', style: TextStyle(color: Colors.white)),
                              Text('☀️ UV Index: ${uvIndex ?? 0}', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        color: Colors.black.withOpacity(0.4),
                        margin: EdgeInsets.symmetric(vertical: 10),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              buildOutfitSection('👕 Morning', outfitMorning, Colors.amberAccent),
                              SizedBox(width: 12),
                              buildOutfitSection('☀️ Afternoon', outfitAfternoon, Colors.cyanAccent),
                              SizedBox(width: 12),
                              buildOutfitSection('🌙 Night', outfitNight, Colors.deepPurpleAccent),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: fetchRecommendation,
                        icon: Icon(Icons.refresh),
                        label: Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => WardrobePage(
                              actualTemp: actualTemperature ?? 0.0,
                              uvIndex: uvIndex ?? 0,
                              precipitationMm: precipitation ?? 0.0,
                              precipitationProb: rainChance ?? 0,
                              outfitMorning: outfitMorning?.cast<String>() ?? [],
                              outfitAfternoon: outfitAfternoon?.cast<String>() ?? [],
                              outfitNight: outfitNight?.cast<String>() ?? [],
                            ),
                          ),
                        ),
                        icon: Icon(Icons.edit),
                        label: Text('My Wardrobe'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}
