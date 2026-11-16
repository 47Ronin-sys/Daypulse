import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_models.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _geoUrl = 'https://geocoding-api.open-meteo.com/v1/search';

  Future<WeatherData> fetchWeather({
    required String cityName,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?latitude=$latitude&longitude=$longitude'
        '&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation_probability,weather_code,wind_speed_10m'
        '&hourly=temperature_2m,weather_code'
        '&timezone=auto',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromOpenMeteo(cityName: cityName, json: data);
      } else {
        return WeatherData.nairobiDefault();
      }
    } catch (_) {
      // Graceful offline fallback
      return WeatherData.nairobiDefault();
    }
  }

  Future<List<Map<String, dynamic>>> searchCities(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final url = Uri.parse(
        '$_geoUrl?name=${Uri.encodeComponent(query)}&count=5&language=en&format=json',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List<dynamic>? ?? [];
        return results.map((item) {
          return {
            'name': item['name'] ?? '',
            'country': item['country'] ?? '',
            'latitude': (item['latitude'] as num).toDouble(),
            'longitude': (item['longitude'] as num).toDouble(),
          };
        }).toList();
      }
    } catch (_) {}
    return [];
  }
}
