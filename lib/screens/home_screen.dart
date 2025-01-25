import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_de_clima/services/weather_service.dart';
import 'package:app_de_clima/services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WeatherService _weatherService = WeatherService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _currentIndex = 0;
  bool isDarkMode = false;

  String city = "";
  String country = "";
  String weatherDescription = "";
  String forecast = "";
  double temperature = 0;
  String lastUpdateTime = "";

  @override
  void initState() {
    super.initState();
    _getWeatherData();
    _notificationService.init();
  }

  Future<void> _getWeatherData() async {
    try {
      Position position = await _weatherService.getCurrentLocation();
      var weatherData = await _weatherService.getWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      setState(() {
        city = weatherData['name'] ?? 'N/A';
        country = weatherData['sys']['country'] ?? 'N/A';
        weatherDescription = weatherData['weather'][0]['description'] ?? 'N/A';
        forecast = weatherData['weather'][0]['main'] ?? 'N/A';
        temperature = (weatherData['main']['temp'] as num?)?.toDouble() ?? 0.0;
        lastUpdateTime = DateFormat('HH:mm').format(DateTime.now());
      });

      _notificationService.showNotification(city, temperature, forecast);
    } catch (e) {
      print('Erro ao obter dados do clima: $e');
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _scheduleWeatherNotifications() async {
    const duration = Duration(minutes: 5);
    await _notificationService.scheduleNotification(
      city,
      temperature,
      forecast,
      duration,
    );
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  Widget _buildTestNotificationButton() {
    return ElevatedButton(
      onPressed: () {
        _notificationService.showNotification(
          city,
          temperature,
          forecast,
        );
      },
      child: const Text('Testar Notificação'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Localização: $city, $country',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Temperatura: ${temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Clima: $weatherDescription',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Previsão: $forecast',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Última atualização: $lastUpdateTime',
                    style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Theme.of(context).primaryColor,
                    size: 30,
                  ),
                  onPressed: () async {
                    await _getWeatherData();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      const SavedCitiesScreen(),
      const SearchScreen(),
      Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Modo Escuro'),
              trailing: Switch(
                value: isDarkMode,
                onChanged: (value) => _toggleDarkMode(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => _logout(),
            ),
          ],
        ),
      ),
    ];

    return MaterialApp(
      theme: isDarkMode
          ? ThemeData.dark().copyWith(
        primaryColor: Colors.teal,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.teal,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.black,
        ),
      )
          : ThemeData.light().copyWith(
        primaryColor: Colors.blue,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('App de Clima'),
        ),
        body: screens[_currentIndex],
        floatingActionButton: _buildTestNotificationButton(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Início',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: 'Salvo',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Pesquisa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Configurações',
            ),
          ],
        ),
      ),
    );
  }
}

class SavedCitiesScreen extends StatefulWidget {
  const SavedCitiesScreen({Key? key}) : super(key: key);

  @override
  State<SavedCitiesScreen> createState() => _SavedCitiesScreenState();
}

class _SavedCitiesScreenState extends State<SavedCitiesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _savedCities = [];

  @override
  void initState() {
    super.initState();
    _loadSavedCities();
  }

  Future<void> _loadSavedCities() async {
    try {
      QuerySnapshot snapshot =
      await _firestore.collection('saved_cities').get();
      List<Map<String, dynamic>> cities = [];
      for (var doc in snapshot.docs) {
        cities.add({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        });
      }
      setState(() {
        _savedCities = cities;
      });
    } catch (e) {
      print('Erro ao carregar cidades salvas: $e');
    }
  }

  Future<void> _deleteCity(String documentId) async {
    if (documentId.isEmpty) return;

    try {
      await _firestore.collection('saved_cities').doc(documentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cidade removida com sucesso!')),
      );
      await _loadSavedCities();
    } catch (e) {
      print('Erro ao excluir cidade: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cidades Salvas')),
      body: ListView.builder(
        itemCount: _savedCities.length,
        itemBuilder: (context, index) {
          final city = _savedCities[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text('${city['city'] ?? 'Cidade desconhecida'}, ${city['country'] ?? 'País desconhecido'}'),
              subtitle: Text('${(city['temperature'] as num?)?.toStringAsFixed(1) ?? '0.0'}°C - ${city['description'] ?? 'Descrição indisponível'}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteCity(city['id']?.toString() ?? ''),
              ),
            ),
          );
        },
      ),
    );
  }
}

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
  double temperature = 0.0;

  final WeatherService _weatherService = WeatherService();

  Future<void> _getWeatherByCity(String cityName) async {
    if (cityName.isEmpty) return;

    try {
      var weatherData = await _weatherService.getWeatherByCity(cityName);
      setState(() {
        city = weatherData['name'] ?? 'N/A';
        country = weatherData['sys']['country'] ?? 'N/A';
        weatherDescription = weatherData['weather'][0]['description'] ?? 'N/A';
        temperature = (weatherData['main']['temp'] as num?)?.toDouble() ?? 0.0;
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
      appBar: AppBar(title: const Text('Pesquisar Clima')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Pesquisar cidade',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _getWeatherByCity(value);
              },
            ),
            const SizedBox(height: 20),
            if (city.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cidade: $city',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Temperatura: ${temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Clima: $weatherDescription',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  IconButton(
                    icon: Icon(Icons.save,
                      size: 40,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: _saveCity,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}