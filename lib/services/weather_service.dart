import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class WeatherService {
  final String apiKey = '5a49615a69e833f71e209fbcf68bc340';

  Future<Position> getCurrentLocation() async {
    LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
    );
    return await Geolocator.getCurrentPosition(locationSettings: locationSettings);
  }

  // Método para buscar clima com base na latitude e longitude
  Future<Map<String, dynamic>> getWeatherByLocation(double latitude, double longitude) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final weatherData = json.decode(response.body);
        await _saveWeatherData(weatherData);
        return weatherData;
      } else {
        throw Exception('Falha ao carregar os dados do clima');
      }
    } catch (_) {
      return await loadWeatherData();
    }
  }

  Future<Map<String, dynamic>> getWeatherByCity(String cityName) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric&lang=pt_br';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final weatherData = json.decode(response.body);
        // Salvar dados localmente
        await _saveWeatherData(weatherData);
        return weatherData;
      } else {
        throw Exception('Falha ao carregar os dados do clima para $cityName');
      }
    } catch (_) {
      return await loadWeatherData();
    }
  }

  Future<void> _saveWeatherData(Map<String, dynamic> weatherData) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('weatherData', json.encode(weatherData));
  }

  Future<Map<String, dynamic>> loadWeatherData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('weatherData');

    if (data != null) {
      return json.decode(data);
    } else {
      throw Exception('Nenhum dado local encontrado.');
    }
  }
}