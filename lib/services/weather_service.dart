import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  final String apiKey = '5a49615a69e833f71e209fbcf68bc340';

  // Método para obter a localização atual
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
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao carregar os dados do clima');
    }
  }

  // Método para buscar clima com base no nome da cidade
  Future<Map<String, dynamic>> getWeatherByCity(String cityName) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$apiKey&units=metric';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao carregar os dados do clima para $cityName');
    }
  }
}
