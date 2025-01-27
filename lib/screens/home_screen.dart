import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_de_clima/services/weather_service.dart';
import 'package:app_de_clima/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'search_screen.dart'; // Importando a tela de pesquisa
import 'saved_cities_screen.dart'; // Importando a tela de cidades salvas

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final WeatherService _weatherService = WeatherService();
  final NotificationService _notificationService = NotificationService();

  int _currentIndex = 0;
  bool isDarkMode = false;
  bool _isDayTime = true;

  String city = "";
  String country = "";
  String weatherDescription = "";
  String forecast = "";
  int temperature = 0;
  String lastUpdateTime = "";

  // Função para atualizar as cidades salvas
  VoidCallback? _onRefreshSavedCities;

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

      final now = DateTime.now();
      final hour = now.hour;
      setState(() {
        _isDayTime = hour >= 5 && hour < 18;
      });

      setState(() {
        city = weatherData['name'] ?? 'N/A';
        country = weatherData['sys']['country'] ?? 'N/A';
        weatherDescription = weatherData['weather'][0]['description'] ?? 'N/A';
        forecast = weatherData['weather'][0]['main'] ?? 'N/A';
        temperature = (weatherData['main']['temp'] as num).round();
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

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  Widget _buildTestNotificationButton() {
    return FloatingActionButton(
      onPressed: () {
        _notificationService.showNotification(
          city,
          temperature,
          forecast,
        );
      },
      child: const Icon(Icons.notifications),
      backgroundColor: Theme.of(context).colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeScreen(),
      SavedCitiesScreen(
        onRefresh: _onRefreshSavedCities, // Passando o callback
      ),
      const SearchScreen(),
      _buildSettingsScreen(),
    ];

    return MaterialApp(
      theme: _buildAppTheme(),
      home: Scaffold(
        appBar: AppBar(
          leading: Icon(
            _isDayTime ? Icons.wb_sunny : Icons.nightlight_round,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          title: Text(
            'App de Clima',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () async {
                await _getWeatherData(); // Atualiza os dados da tela inicial
                if (_onRefreshSavedCities != null) {
                  _onRefreshSavedCities!(); // Notifica o SavedCitiesScreen
                }
              },
            ),
          ],
        ),
        body: screens[_currentIndex],
        floatingActionButton: _buildTestNotificationButton(),
        bottomNavigationBar: _buildFloatingNavBar(),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getWeatherIcon(forecast),
                    size: 120,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 30),
                  Text(
                    '$city, $country',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$temperature°C',
                    style: TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w300,
                      fontFamily: 'Poppins',
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    weatherDescription.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      letterSpacing: 1.5,
                      fontFamily: 'Montserrat',
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Última atualização: $lastUpdateTime',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                fontFamily: 'Montserrat',
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.dark_mode,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Modo Escuro',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) => _toggleDarkMode(),
            ),
          ),
          ListTile(
            leading: Icon(Icons.logout,
                color: Theme.of(context).colorScheme.onSurface),
            title: Text(
              'Sair',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            onTap: () => _logout(),
          ),
        ],
      ),
    );
  }

  ThemeData _buildAppTheme() {
    return isDarkMode
        ? ThemeData.dark().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blueGrey,
        brightness: Brightness.dark,
        surface: const Color(0xFF121212),
        onSurface: Colors.white,
        primary: Colors.blueGrey[300],
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Poppins'),
        bodyLarge: TextStyle(fontFamily: 'Montserrat'),
      ),
    )
        : ThemeData.light().copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
        surface: Colors.white,
        onSurface: Colors.black87,
        primary: Colors.blue[700],
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontFamily: 'Poppins'),
        bodyLarge: TextStyle(fontFamily: 'Montserrat'),
      ),
    );
  }

  Widget _buildFloatingNavBar() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withAlpha(
              (Theme.of(context).colorScheme.surface.a * 0.8).round(),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Início',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                activeIcon: Icon(Icons.favorite),
                label: 'Salvo',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search_outlined),
                activeIcon: Icon(Icons.search),
                label: 'Pesquisa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Configurações',
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String forecast) {
    switch (forecast.toUpperCase()) {
      case 'CLEAR':
        return Icons.wb_sunny;
      case 'CLOUDS':
        return Icons.cloud;
      case 'RAIN':
        return Icons.beach_access;
      case 'SNOW':
        return Icons.ac_unit;
      case 'THUNDERSTORM':
        return Icons.flash_on;
      case 'DRIZZLE':
        return Icons.grain;
      case 'DUST':
        return Icons.blur_on;
      case 'TORNADO':
        return Icons.storm;
      default:
        return Icons.wb_cloudy;
    }
  }
}