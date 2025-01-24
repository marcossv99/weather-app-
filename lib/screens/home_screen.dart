import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_de_clima/services/weather_service.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int _currentIndex = 0;
  bool isDarkMode = false;

  String city = "";
  String country = "";
  String weatherDescription = "";
  double temperature = 0.0;
  String lastUpdateTime = "";

  @override
  void initState() {
    super.initState();
    _getWeatherData();
  }

  Future<void> _getWeatherData() async {
    try {
      Position position = await _weatherService.getCurrentLocation();
      var weatherData = await _weatherService.getWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      setState(() {
        city = weatherData['name'];
        country = weatherData['sys']['country'];
        weatherDescription = weatherData['weather'][0]['description'];
        temperature = weatherData['main']['temp'];
        lastUpdateTime = DateFormat('HH:mm').format(DateTime.now());
      });
    } catch (e) {
      print('Erro ao obter dados do clima: $e');
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              Text(
                'Última atualização: $lastUpdateTime',
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
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
        cities.add(doc.data() as Map<String, dynamic>);
      }
      setState(() {
        _savedCities = cities;
      });
    } catch (e) {
      print('Erro ao carregar cidades salvas: $e');
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
              title: Text('${city['city']}, ${city['country']}'),
              subtitle: Text('${city['temperature']}°C - ${city['description']}'),
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
  String weatherDescription = '';
  double temperature = 0.0;

  final WeatherService _weatherService = WeatherService();

  Future<void> _getWeatherByCity(String cityName) async {
    if (cityName.isEmpty) return;

    try {
      var weatherData = await _weatherService.getWeatherByCity(cityName);
      setState(() {
        city = weatherData['name'];
        weatherDescription = weatherData['weather'][0]['description'];
        temperature = weatherData['main']['temp'];
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
        'country': 'Country Name', // Aqui você pode adicionar o código para pegar o país
        'temperature': temperature,
        'description': weatherDescription,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cidade salva com sucesso!')),
      );
    } catch (e) {
      print('Erro ao salvar cidade: $e');
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
                    'Temperatura: $temperature°C',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(
                    'Clima: $weatherDescription',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  IconButton(
                    icon: const Icon(Icons.save),
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
