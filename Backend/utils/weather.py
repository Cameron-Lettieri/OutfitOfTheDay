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

# Smart outfit recommendation

def suggest_outfit(temp, units='metric', wind=0, rain=0, humidity=0, cloud=100, uv_index=0):
    # convert to Fahrenheit for unified thresholds
    temp_f = (temp * 9/5) + 32 if units == 'metric' else temp

    # prepare categories
    top = []
    bottom = []
    outerwear = []
    shoes = []
    accessories = []

    # TOP selection
    if temp_f < 35:
        top.append("Heavy thermal sweater")
    elif temp_f < 50:
        top.append("Long sleeve shirt")
    elif temp_f < 70:
        top.append("Light long sleeve")
    elif temp_f < 85:
        top.append("Short sleeve shirt")
    else:
        top.append("Breathable tank top")

    # BOTTOM selection
    if temp_f < 45:
        bottom.append("Insulated pants or jeans")
    elif temp_f < 70:
        bottom.append("Chinos or joggers")
    elif temp_f < 85:
        bottom.append("Lightweight pants or capris")
    else:
        bottom.append("Shorts")

    # SHOES selection
    if rain > 1:
        shoes.append("Waterproof boots")
    elif temp_f < 40:
        shoes.append("Insulated boots")
    elif temp_f < 70:
        shoes.append("Casual sneakers")
    else:
        shoes.append("Breathable sneakers or sandals")

    # OUTERWEAR selection
    if rain > 0.5:
        outerwear.append("Rain jacket")
    elif temp_f < 32:
        outerwear.append("Heavy winter coat")
    elif temp_f < 55:
        outerwear.append("Hoodie or light jacket")
    elif wind > 20:
        outerwear.append("Windbreaker")

    # ACCESSORY selection
    if rain > 0.2:
        accessories.append("Umbrella")
    if humidity > 80 and temp_f > 75:
        accessories.append("Moisture-wicking hat")
    if cloud < 20:
        accessories.append("Sunglasses")
    if uv_index >= 6:
        accessories.append("Sunscreen")
    if temp_f < 40:
        accessories.append("Gloves and scarf")

    # flatten list: ensure exactly 1 top, bottom, and shoes
    outfit = []
    outfit.extend(top)
    outfit.extend(bottom)
    outfit.extend(shoes)
    outfit.extend(outerwear)
    outfit.extend(accessories)

    return outfit
