import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/weather_service.dart';

class SavedCitiesScreen extends StatefulWidget {
  final VoidCallback? onRefresh;

  const SavedCitiesScreen({Key? key, this.onRefresh}) : super(key: key);

  @override
  State<SavedCitiesScreen> createState() => _SavedCitiesScreenState();
}

class _SavedCitiesScreenState extends State<SavedCitiesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WeatherService _weatherService = WeatherService();

  List<Map<String, dynamic>> _savedCities = [];

  @override
  void initState() {
    super.initState();
    _loadSavedCities();
  }

  Future<void> _loadSavedCities() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('saved_cities').get();
      List<Map<String, dynamic>> cities = [];
      for (var doc in snapshot.docs) {
        cities.add({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
          'temperature': (doc.data() as Map<String, dynamic>)['temperature']
          is double
              ? ((doc.data() as Map<String, dynamic>)['temperature'] as double)
              .round()
              : (doc.data() as Map<String, dynamic>)['temperature'],
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

  Future<void> _updateSavedCities() async {
    try {
      for (var city in _savedCities) {
        final cityName = city['city'];
        if (cityName != null) {
          final updatedWeather =
          await _weatherService.getWeatherByCity(cityName);
          await _firestore.collection('saved_cities').doc(city['id']).update({
            'temperature': updatedWeather['main']['temp'],
            'description': updatedWeather['weather'][0]['description'],
          });
        }
      }
      await _loadSavedCities();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cidades atualizadas com sucesso!')),
      );
    } catch (e) {
      print('Erro ao atualizar cidades: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cidades Salvas',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateSavedCities, // Chama o método de atualização
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _savedCities.length,
        itemBuilder: (context, index) {
          final city = _savedCities[index];
          return Card(
            margin: const EdgeInsets.all(10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              title: Text(
                '${city['city'] ?? 'Cidade desconhecida'}, ${city['country'] ?? 'País desconhecido'}',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                '${city['temperature']?.toString() ?? '0'}°C - ${city['description'] ?? 'Descrição indisponível'}',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 14,
                  color:
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
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