import 'package:app_de_clima/services/weather_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String locationMessage = "Obtendo localização...";
  String city = "";
  String country = "";
  String weatherDescription = "";
  double temperature = 0.0;
  String lastUpdateTime = "";
  final WeatherService _weatherService = WeatherService();
  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkPermissionAndGetLocation();
  }

  // Função para buscar clima com base no nome da cidade
  Future<void> _getWeatherByCity(String cityName) async {
    try {
      var weatherData = await _weatherService.getWeatherByCity(cityName);

      setState(() {
        city = weatherData['name'];
        country = weatherData['sys']['country'];
        weatherDescription = weatherData['weather'][0]['description'];
        temperature = weatherData['main']['temp'];

        // Formatar hora da última atualização
        DateTime now = DateTime.now();
        lastUpdateTime = DateFormat('HH:mm:ss').format(now);
      });
    } catch (e) {
      setState(() {
        locationMessage = "Erro ao obter dados da cidade.";
      });
    }
  }

  // Função para verificar permissão e obter localização
  Future<void> _checkPermissionAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar se o serviço de localização está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationMessage = "Serviço de localização desativado.";
      });
      return;
    }

    // Verificar permissões de localização
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          locationMessage = "Permissão de localização negada.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationMessage = "Permissão de localização negada permanentemente.";
      });
      return;
    }

    // Obter a localização
    Position position = await _weatherService.getCurrentLocation();

    // Obter o clima e as informações da cidade
    var weatherData = await _weatherService.getWeatherByLocation(position.latitude, position.longitude);

    // Atualizar o estado com as novas informações
    setState(() {
      locationMessage = "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
      city = weatherData['name'];
      country = weatherData['sys']['country'];
      weatherDescription = weatherData['weather'][0]['description'];
      temperature = weatherData['main']['temp'];

      // Formatar hora da última atualização
      DateTime now = DateTime.now();
      lastUpdateTime = DateFormat('HH:mm:ss').format(now);
    });
  }

  // Função para atualizar o clima
  Future<void> _refreshWeather() async {
    if (_cityController.text.isNotEmpty) {
      await _getWeatherByCity(_cityController.text);
    } else {
      await _checkPermissionAndGetLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather App'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Barra de pesquisa
              TextField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Pesquisar cidade',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.search),
                ),
                onSubmitted: (cityName) {
                  if (cityName.isNotEmpty) {
                    _getWeatherByCity(cityName);
                  }
                },
              ),
              const SizedBox(height: 20),
              // Exibir informações
              Text(
                'Localização: $city, $country',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 10),
              Text(
                'Temperatura: $temperature°C',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'Clima: $weatherDescription',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              // Hora da última atualização
              Text(
                'Última atualização: $lastUpdateTime',
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),
              // Botão de atualizar clima
              ElevatedButton(
                onPressed: _refreshWeather,
                child: const Text('Atualizar Clima'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
