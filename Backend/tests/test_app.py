import os
import sys
import types
import datetime

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

import app

class MockResponse:
    def __init__(self, data):
        self._data = data
    def json(self):
        return self._data

def test_get_weather_parsing(monkeypatch):
    today = datetime.datetime.now().strftime('%Y-%m-%d')
    sample = {
        "current": {
            "apparent_temperature": 10,
            "temperature_2m": 12,
            "wind_speed_10m": 5,
            "cloudcover": 25,
            "relative_humidity_2m": 40,
            "uv_index": 3,
            "precipitation": 0.1,
            "dew_point_2m": 5,
            "weather_code": 2
        },
        "hourly": {
            "time": [f"{today}T08:00", f"{today}T14:00", f"{today}T20:00"],
            "temperature_2m": [12, 15, 9],
            "wind_speed_10m": [5, 6, 4],
            "wind_gusts_10m": [7, 9, 6],
            "cloudcover": [20, 50, 60],
            "precipitation_probability": [10, 20, 30]
        },
        "daily": {
            "temperature_2m_max": [16],
            "temperature_2m_min": [8],
            "precipitation_probability_max": [40],
            "sunrise": [f"{today}T06:00"],
            "sunset": [f"{today}T18:00"]
        }
    }

    def mock_get(url, params=None, headers=None):
        if 'open-meteo' in url:
            return MockResponse(sample)
        else:
            return MockResponse({"address": {"city": "Testville"}})

    monkeypatch.setattr(app.requests, 'get', mock_get)

    weather = app.get_weather(0, 0, units='imperial')
    assert weather['city'] == 'Testville'
    assert weather['actual_temperature'] == 53.6
    assert weather['feels_like_temperature'] == 50.0
    assert weather['dew_point'] == 41.0
    assert weather['weather_code'] == 2
    assert weather['hourly_forecast']['morning']['temp'] == 53.6
    assert weather['hourly_forecast']['afternoon']['wind'] == 13
    assert weather['hourly_forecast']['afternoon']['gust'] == 20
    assert weather['rain_chance'] == 30


def test_suggest_outfit():
    outfit = app.suggest_outfit(
        temp=40,
        units='imperial',
        wind=10,
        rain=60,
        humidity=30,
        cloud=10,
        time_of_day='morning'
    )
    expected = {
        "Long sleeve shirt",
        "Sweater",
        "Chinos or jeans",
        "Insulated jacket",
        "Raincoat",
        "Waterproof boots",
        "Umbrella",
        "Sunglasses"
    }
    assert set(outfit) == expected
