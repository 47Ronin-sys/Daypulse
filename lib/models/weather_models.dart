import 'package:flutter/material.dart';

class WeatherData {
  final String cityName;
  final double temperatureC;
  final double apparentTemperatureC;
  final int weatherCode;
  final int precipitationProbability;
  final int humidity;
  final double windSpeedKmh;
  final List<HourlyWeatherItem> hourlyForecast;

  WeatherData({
    required this.cityName,
    required this.temperatureC,
    required this.apparentTemperatureC,
    required this.weatherCode,
    required this.precipitationProbability,
    required this.humidity,
    required this.windSpeedKmh,
    required this.hourlyForecast,
  });

  static double toFahrenheit(double celsius) {
    return (celsius * 9 / 5) + 32;
  }

  static String formatTemp(double celsius, bool isFahrenheit) {
    if (isFahrenheit) {
      final f = toFahrenheit(celsius).round();
      return '$f°F';
    } else {
      final c = celsius.round();
      return '$c°C';
    }
  }

  String get conditionText {
    switch (weatherCode) {
      case 0:
        return 'Clear Sky';
      case 1:
        return 'Mainly Clear';
      case 2:
        return 'Partly Cloudy';
      case 3:
        return 'Overcast';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 80:
      case 81:
      case 82:
        return 'Rain Showers';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Fair Weather';
    }
  }

  IconData get conditionIcon {
    switch (weatherCode) {
      case 0:
      case 1:
        return Icons.wb_sunny_rounded;
      case 2:
        return Icons.wb_cloudy_rounded;
      case 3:
        return Icons.cloud_rounded;
      case 45:
      case 48:
        return Icons.blur_on_rounded;
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return Icons.grain_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_rounded;
      default:
        return Icons.wb_sunny_outlined;
    }
  }

  Color get conditionColor {
    switch (weatherCode) {
      case 0:
      case 1:
        return Colors.amber;
      case 2:
      case 3:
        return Colors.blueGrey;
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return Colors.blue;
      case 95:
      case 96:
      case 99:
        return Colors.deepPurple;
      default:
        return Colors.orange;
    }
  }

  factory WeatherData.fromOpenMeteo({
    required String cityName,
    required Map<String, dynamic> json,
  }) {
    final current = json['current'] ?? {};
    final hourly = json['hourly'] ?? {};

    List<HourlyWeatherItem> hourlyList = [];
    if (hourly['time'] != null && hourly['temperature_2m'] != null) {
      final times = List<String>.from(hourly['time']);
      final temps = List<dynamic>.from(hourly['temperature_2m']);
      final codes = List<dynamic>.from(hourly['weather_code'] ?? []);
      final count = times.length > 12 ? 12 : times.length;

      for (int i = 0; i < count; i++) {
        hourlyList.add(
          HourlyWeatherItem(
            time: DateTime.tryParse(times[i]) ?? DateTime.now(),
            temperatureC: (temps[i] as num).toDouble(),
            weatherCode: codes.isNotEmpty ? (codes[i] as num).toInt() : 0,
          ),
        );
      }
    }

    return WeatherData(
      cityName: cityName,
      temperatureC: (current['temperature_2m'] as num?)?.toDouble() ?? 24.0,
      apparentTemperatureC: (current['apparent_temperature'] as num?)?.toDouble() ?? 24.5,
      weatherCode: (current['weather_code'] as num?)?.toInt() ?? 1,
      precipitationProbability: (current['precipitation_probability'] as num?)?.toInt() ?? 10,
      humidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 60,
      windSpeedKmh: (current['wind_speed_10m'] as num?)?.toDouble() ?? 12.0,
      hourlyForecast: hourlyList,
    );
  }

  factory WeatherData.nairobiDefault() {
    final now = DateTime.now();
    return WeatherData(
      cityName: 'Nairobi, Kenya',
      temperatureC: 23.0,
      apparentTemperatureC: 23.5,
      weatherCode: 2,
      precipitationProbability: 15,
      humidity: 62,
      windSpeedKmh: 14.0,
      hourlyForecast: List.generate(
        8,
        (i) => HourlyWeatherItem(
          time: now.add(Duration(hours: i * 2)),
          temperatureC: 22.0 + (i % 4),
          weatherCode: i % 2 == 0 ? 1 : 2,
        ),
      ),
    );
  }
}

class HourlyWeatherItem {
  final DateTime time;
  final double temperatureC;
  final int weatherCode;

  HourlyWeatherItem({
    required this.time,
    required this.temperatureC,
    required this.weatherCode,
  });
}
