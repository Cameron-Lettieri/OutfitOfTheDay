import requests

# Get temperature from Open-Meteo
# now includes uv_index for accessory logic

def get_weather(lat, lon, units='metric'):
    url = "https://api.open-meteo.com/v1/forecast"
    params = {
        "latitude": lat,
        "longitude": lon,
        # include uv_index in current data
        "current": "temperature_2m,apparent_temperature,precipitation,cloudcover,wind_speed_10m,relative_humidity_2m,uv_index",
        "timezone": "auto"
    }

    response = requests.get(url, params=params)
    data = response.json()["current"]

    temp_c = data["temperature_2m"]
    wind_mps = data["wind_speed_10m"]
    humidity = data["relative_humidity_2m"]
    rain = data["precipitation"]
    cloud = data["cloudcover"]
    uv_index = data.get("uv_index", 0)

    # convert to imperial if needed
    if units == 'imperial':
        temp_f = (temp_c * 9/5) + 32
        wind_mph = wind_mps * 2.23694
        if temp_f <= 50 and wind_mph > 3:
            feels_like_f = (
                35.74 + 0.6215 * temp_f
                - 35.75 * (wind_mph ** 0.16)
                + 0.4275 * temp_f * (wind_mph ** 0.16)
            )
        else:
            feels_like_f = temp_f

        actual_temp = round(temp_f, 1)
        feels_like = round(feels_like_f, 1)
    else:
        actual_temp = round(temp_c, 1)
        feels_like = round(temp_c, 1)
        wind_mph = wind_mps * 2.23694

    city = reverse_geocode(lat, lon)

    return {
        "actual_temperature": actual_temp,
        "feels_like_temperature": feels_like,
        "wind_speed": round(wind_mph, 1),  # MPH
        "precipitation": rain,
        "cloud_cover": cloud,
        "humidity": humidity,
        "uv_index": round(uv_index, 1),
        "description": "Includes wind chill if applicable",
        "city": city
    }

# Reverse geocode using Nominatim

def reverse_geocode(lat, lon):
    try:
        url = f"https://nominatim.openstreetmap.org/reverse?format=json&lat={lat}&lon={lon}"
        headers = {"User-Agent": "WeatherStyleApp/1.0"}
        response = requests.get(url, headers=headers)
        address = response.json().get("address", {})
        return (
            address.get("city")
            or address.get("town")
            or address.get("village")
            or address.get("state")
            or "Unknown Location"
        )
    except Exception as e:
        print(f"Reverse geocoding failed: {e}")
        return "Unknown Location"

