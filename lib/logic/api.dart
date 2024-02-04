// weather_api.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../logic/config.dart';

class WeatherApi {
  Future<Map<String, String>> fetchDataFromAPI(String city) async {
    const apiKey = Config.apiKey1;
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cityName = data['name'] as String?;
        final temp = data['main']['temp'] as double?;
        final weatherDesc = data['weather'][0]['description'] as String?;

        if (cityName != null && temp != null && weatherDesc != null) {
          return {
            'location': cityName,
            'temperature': '$temp°C',
            'weatherCondition': weatherDesc,
          };
        } else {
          return {
            'location': 'Unknown',
            'temperature': 'Unknown',
            'weatherCondition': 'Unknown',
          };
        }
      } else {
        return {
          'location': 'Error',
          'temperature': 'N/A',
          'weatherCondition': 'N/A',
        };
      }
    } catch (e) {
      return {
        'location': 'Error',
        'temperature': 'N/A',
        'weatherCondition': 'N/A',
      };
    }
  }

  Future<List<Map<String, String>>> fetchWeatherForecastsFromAPI(String city) async {
    const apiKey = Config.apiKey1;
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> forecasts = data['list'];
        List<Map<String, String>> weatherForecasts = [];

        for (int i = 0; i < 5; i++) {
          final forecastData = forecasts[i * 8];
          final temperature = forecastData['main']['temp'].toString();
          final weatherCondition = forecastData['weather'][0]['description']
              .toString()
              .toLowerCase();
          final windSpeed = forecastData['wind']['speed'] as double?;
          final precipitation = (forecastData['pop'] as num?)?.toInt();

          weatherForecasts.add({
            'temperature': temperature,
            'weatherCondition': weatherCondition,
            'windSpeed': windSpeed?.toString() ?? '0.0',
            'precipitation': precipitation?.toString() ?? '0',
          });
        }

        return weatherForecasts;
      } else {
        print('Failed to fetch weather forecasts');
        return [];
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }
}
