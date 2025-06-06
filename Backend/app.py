
from flask import Flask, request, jsonify
import requests
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

def reverse_geocode(lat, lon):
    try:
        url = f"https://nominatim.openstreetmap.org/reverse"
        params = {
            "lat": lat,
            "lon": lon,
            "format": "json"
        }
        headers = {
            "User-Agent": "WeatherStyleApp/1.0"
        }
        response = requests.get(url, params=params, headers=headers)
        data = response.json()
        address = data.get("address", {})
        return (
            address.get("city")
            or address.get("town")
            or address.get("village")
            or address.get("county")
            or data.get("display_name", "Your Location").split(",")[0]
        )
    except Exception:
        return "Your Location"

def get_weather(lat, lon, units='imperial'):
    url = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude": lat,
        "longitude": lon,
        "current": (
            "temperature_2m,apparent_temperature,precipitation,cloudcover,"
            "wind_speed_10m,relative_humidity_2m,uv_index,dew_point_2m,"
            "weather_code"
        ),
        "hourly": (
            "temperature_2m,cloudcover,precipitation_probability,wind_speed_10m,"
            "wind_gusts_10m"
        ),
        "daily": (
            "temperature_2m_max,temperature_2m_min,precipitation_probability_max,"
            "sunrise,sunset"
        ),
        "timezone": "auto",
        "windspeed_unit": "ms",
        "precipitation_unit": "inch" if units == "imperial" else "mm",
    }

    response = requests.get(url, params=params)
    data = response.json()

    current = data["current"]
    hourly = data["hourly"]
    daily = data["daily"]

    def convert_c_to_unit(val):
        return (val * 9/5) + 32 if units == "imperial" else val

    feels_like_c = current["apparent_temperature"]
    temp_c = current["temperature_2m"]
    wind_mps = current["wind_speed_10m"]
    cloud = current["cloudcover"]
    humidity = current["relative_humidity_2m"]
    dew_point_c = current.get("dew_point_2m")
    uv_index = current.get("uv_index", 0)
    weather_code = current.get("weather_code")
    today_max = daily["temperature_2m_max"][0]
    today_min = daily["temperature_2m_min"][0]
    precip_chance = daily.get("precipitation_probability_max", [0])[0]
    rain_chance = max(data['hourly']['precipitation_probability'])  # in %
    precip_amount = data['current']['precipitation']

    time_index = {t: i for i, t in enumerate(hourly["time"])}

    def get_hour(hour):
        from datetime import datetime
        today_str = datetime.now().strftime("%Y-%m-%d")
        return time_index.get(f"{today_str}T{hour:02d}:00")

    def get_hour_data(hour):
        idx = get_hour(hour)
        if idx is None:
            return None
        return {
            "temp": convert_c_to_unit(hourly["temperature_2m"][idx]),
            "wind": round(
                hourly["wind_speed_10m"][idx] * (2.23694 if units == "imperial" else 1)
            ),
            "gust": round(
                hourly.get("wind_gusts_10m", [0])[idx]
                * (2.23694 if units == "imperial" else 1)
            ),
            "cloud": hourly["cloudcover"][idx],
            "rain": hourly["precipitation_probability"][idx],
        }

    city = reverse_geocode(lat, lon)

    wind_speed_val = wind_mps * (2.23694 if units == "imperial" else 1)

    return {
        "city": city,
        "actual_temperature": round(convert_c_to_unit(temp_c), 1),
        "feels_like_temperature": round(convert_c_to_unit(feels_like_c), 1),
        "wind_speed": round(wind_speed_val),
        "precipitation": round(precip_amount, 2),
        "precipitation_probability": round(precip_chance),
        "rain_chance": round(rain_chance),
        "cloud_cover": round(cloud, 1),
        "humidity": round(humidity, 1),
        "dew_point": round(convert_c_to_unit(dew_point_c), 1) if dew_point_c is not None else None,
        "uv_index": round(uv_index),
        "weather_code": weather_code,
        "high_temp": round(convert_c_to_unit(today_max), 1),
        "low_temp": round(convert_c_to_unit(today_min), 1),
        "sunrise": daily.get("sunrise", [None])[0],
        "sunset": daily.get("sunset", [None])[0],
        "hourly_forecast": {
            "morning": get_hour_data(8),
            "afternoon": get_hour_data(14),
            "night": get_hour_data(20)
        }
    }

def suggest_outfit(temp, units, wind, rain, humidity, cloud, time_of_day):
    outfit = []
    accessories = []
    outerwear = []

    # Select one top
    if temp < 32:
        top = "Thermal base layer"
        outerwear.append("Heavy sweater")
    elif temp < 50:
        top = "Long sleeve shirt"
        outerwear.append("Sweater")
    elif temp < 65:
        top = "Long sleeve shirt"
    elif temp < 75:
        top = "Short sleeve T-shirt"
    else:
        top = "T-shirt"
    outfit.append(top)

    # Select one bottom
    if temp < 35:
        bottom = "Wool pants"
        outerwear.append("Thermal leggings")
    elif temp < 55:
        bottom = "Chinos or jeans"
    elif temp < 75:
        bottom = "Light pants"
    else:
        bottom = "Shorts"
    outfit.append(bottom)

    # Outerwear items
    if temp < 30:
        outerwear.append("Heavy winter coat")
    elif temp < 50:
        outerwear.append("Insulated jacket")
    elif temp < 65:
        outerwear.append("Light jacket")
    elif wind > 20:
        outerwear.append("Windbreaker")
    if rain > 50:
        outerwear.append("Raincoat")
        accessories.append("Umbrella")

    # One pair of shoes
    if temp < 32:
        shoes = "Insulated boots"
    elif rain > 50:
        shoes = "Waterproof boots"
    else:
        shoes = "Sneakers"
    outfit.append(shoes)

    outfit.extend(outerwear)

    if cloud < 20 and time_of_day != "night":
        accessories.append("Sunglasses")
    if temp < 32:
        accessories += ["Scarf", "Gloves", "Beanie"]
    elif time_of_day == "night" and temp < 50:
        accessories.append("Scarf or hoodie")

    outfit += accessories
    return outfit

@app.route("/recommend", methods=["GET"])
def recommend():
    lat = float(request.args.get("lat"))
    lon = float(request.args.get("lon"))
    units = request.args.get("units", "imperial")

    weather = get_weather(lat, lon, units)
    hf = weather["hourly_forecast"]

    morning_outfit = suggest_outfit(hf["morning"]["temp"], units, hf["morning"]["wind"], hf["morning"]["rain"], weather["humidity"], hf["morning"]["cloud"], "morning")
    afternoon_outfit = suggest_outfit(hf["afternoon"]["temp"], units, hf["afternoon"]["wind"], hf["afternoon"]["rain"], weather["humidity"], hf["afternoon"]["cloud"], "afternoon")
    night_outfit = suggest_outfit(hf["night"]["temp"], units, hf["night"]["wind"], hf["night"]["rain"], weather["humidity"], hf["night"]["cloud"], "night")

    return jsonify({
        "location": weather["city"],
        "weather": "Current weather from Open-Meteo",
        "actual_temperature": weather["actual_temperature"],
        "feels_like_temperature": weather["feels_like_temperature"],
        "units": "°F" if units == "imperial" else "°C",
        "humidity": weather["humidity"],
        "cloud_cover": weather["cloud_cover"],
        "wind_speed": weather["wind_speed"],
        "precipitation": weather["precipitation"],
        "precipitation_probability": weather["precipitation_probability"],
        "rain_chance": weather["rain_chance"],
        "uv_index": weather["uv_index"],
        "high_temp": weather["high_temp"],
        "low_temp": weather["low_temp"],
        "outfit_morning": morning_outfit,
        "outfit_afternoon": afternoon_outfit,
        "outfit_night": night_outfit
    })

if __name__ == "__main__":
    app.run(debug=True)
