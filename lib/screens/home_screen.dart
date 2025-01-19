import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_de_clima/services/weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WeatherService _weatherService = WeatherService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String locationMessage = "Obtendo localização...";
  String city = "";
  String country = "";
  String weatherDescription = "";
  double temperature = 0.0;
  String lastUpdateTime = "";

  List<Map<String, dynamic>> savedCities = [];

  @override
  void initState() {
    super.initState();
    _getWeatherData();
    _loadSavedCities();
  }

  // Função para obter dados de clima
  Future<void> _getWeatherData() async {
    try {
      // Obter localização do dispositivo
      Position position = await _weatherService.getCurrentLocation();

      // Obter dados de clima com base na localização
      var weatherData = await _weatherService.getWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      setState(() {
        locationMessage =
        "Latitude: ${position.latitude}, Longitude: ${position.longitude}";
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
        locationMessage = "Erro ao obter dados do clima.";
      });
    }
  }

  // Função para carregar cidades salvas do Firestore
  Future<void> _loadSavedCities() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('cidades salvas')
          .doc(user.uid)
          .get();

      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null && data['cidades'] != null) {
          setState(() {
            savedCities = List<Map<String, dynamic>>.from(data['cidades']);
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar cidades: $e');
    }
  }

  // Função para salvar uma cidade
  Future<void> _saveCity() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (savedCities.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você só pode salvar no máximo 2 cidades.')),
      );
      return;
    }

    try {
      final newCity = {
        'name': city,
        'weather': weatherDescription,
      };

      savedCities.add(newCity);

      await _firestore
          .collection('cidades salvas')
          .doc(user.uid)
          .set({'cidades': savedCities});

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cidade $city salva com sucesso!')),
      );
    } catch (e) {
      print('Erro ao salvar cidade: $e');
    }
  }

  // Função para deslogar o usuário
  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Exibe o email do usuário logado
              Text(
                'Bem-vindo, ${user?.email ?? 'Usuário'}!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Exibe as informações de clima
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

              // Botões para atualizar e salvar cidade
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _getWeatherData,
                    child: const Text('Atualizar Clima'),
                  ),
                  ElevatedButton(
                    onPressed: _saveCity,
                    child: const Text('Salvar Cidade'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Exibe as cidades salvas
              const Text(
                'Cidades Salvas:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: savedCities.length,
                  itemBuilder: (context, index) {
                    final savedCity = savedCities[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cidade: ${savedCity['name']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Clima: ${savedCity['weather']}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
