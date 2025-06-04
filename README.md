# 👕 Outfit of the Day

**Outfit of the Day** is a cross-platform mobile application built with Flutter that provides AI-generated clothing recommendations based on real-time weather, personalized wardrobe data, and user preferences. It dynamically adjusts to time of day, weather changes, and local conditions to help you stay comfortable and stylish.

---

## 🌦 Features

- 🌍 **Location-Based Weather**: Automatically fetches your location and gets hyper-local weather data using Open-Meteo.
- 🤖 **AI Outfit Suggestions**:
  - Distinct recommendations for **morning**, **afternoon**, and **night**.
  - Factors in temperature, humidity, cloud cover, wind speed, chance of rain, and UV index.
  - Wind speed is reported in **MPH** when using imperial units or **m/s** for metric users.
- 🧥 **Wardrobe Customization**:
  - Users can build and manage their own wardrobe.
  - Future updates will learn from user preferences to personalize recommendations.
- 🔔 **Daily Notifications**:
  - Sends a morning alert with weather summary and outfit recommendation.
- 🎨 **Smart UI**:
  - Background and color scheme changes based on temperature.
  - Weather icons and animations adjust based on real-time conditions.
  - Professional, mobile-friendly layout with darkened overlays for readability.
- 🕒 **Coming Soon**:
  - Hourly weather forecast integration.
  - In-app learning based on user feedback.
  - Cloud sync and wardrobe analytics.
  - Alarm with sound that matches the weather

---

## 📁 Project Structure

WeatherStyle/
├── Backend/ # Python Flask server with weather + outfit logic
│ └── app.py # Main backend file
├── mobile/ # Flutter frontend app
│ ├── lib/
│ │ ├── main.dart # Flutter UI logic and API calls
│ │ └── wardrobe_page.dart
│ │ └── storage_service.dart
│ │ └── reccomendation_service.dart
│ │ └── outfit_record.dart
│ ├── assets/ # All image assets used by Flutter
│ │ └── images/
│ └── pubspec.yaml

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Python 3.8+](https://www.python.org)
- Flask + CORS
- Open-Meteo API (no key required)

---

### 1. Clone the Repository

git clone https://github.com/YOUR_USERNAME/weather-style.git
cd weather-style

### 2. Run the Backend

cd Backend
pip install -r requirements.txt
python app.py

### 3. Run the Flutter App

cd ../mobile
flutter pub get
flutter run


