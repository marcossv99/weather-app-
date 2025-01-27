import 'package:flutter/material.dart';
import 'package:app_de_clima/services/weather_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String city = '';
  String country = '';
  String weatherDescription = '';
  int temperature = 0;

  final WeatherService _weatherService = WeatherService();

  Future<void> _getWeatherByCity(String cityName) async {
    if (cityName.isEmpty) return;

    try {
      var weatherData = await _weatherService.getWeatherByCity(cityName);
      setState(() {
        city = weatherData['name'] ?? 'N/A';
        country = weatherData['sys']['country'] ?? 'N/A';
        weatherDescription = weatherData['weather'][0]['description'] ?? 'N/A';
        temperature = (weatherData['main']['temp'] as num).round();
      });
    } catch (e) {
      print('Erro ao buscar clima: $e');
    }
  }

  Future<void> _saveCity() async {
    if (city.isEmpty) return;

    try {
      await FirebaseFirestore.instance.collection('saved_cities').add({
        'city': city,
        'country': country,
        'temperature': temperature,
        'description': weatherDescription,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cidade salva com sucesso!')),
      );
    } catch (e) {
      print('Erro ao salvar cidade: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar a cidade')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pesquisa',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Pesquisar cidade',
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                suffixIcon: const Icon(Icons.search),
              ),
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onChanged: (value) => _getWeatherByCity(value),
            ),
            const SizedBox(height: 30),
            if (city.isNotEmpty)
              Column(
                children: [
                  Text(
                    '$city, $country',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    '$temperature°C',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'Poppins',
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    weatherDescription.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'Montserrat',
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    icon: Icon(
                      Icons.save,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    label: Text(
                      'Salvar Cidade',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    onPressed: _saveCity,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}