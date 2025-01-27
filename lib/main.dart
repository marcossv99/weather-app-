import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_de_clima/screens/saved_cities_screen.dart';
import 'package:app_de_clima/screens/search_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final QuickActions _quickActions = QuickActions();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // Variável para armazenar o estado de autenticação
  User? _user;

  @override
  void initState() {
    super.initState();
    _setupPermissions();
    _setupQuickActions();

    // Verificar o estado de autenticação ao iniciar o app
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _user = user;
      });
    });
  }

  // Configurar permissões
  Future<void> _setupPermissions() async {
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }

    if (await Permission.location.isPermanentlyDenied) {
      await openAppSettings(); // Abre as configurações do app para conceder permissões manualmente
    }
  }

  // Configurar atalhos rápidos
  void _setupQuickActions() {
    _quickActions.setShortcutItems([
      ShortcutItem(type: 'action_home', localizedTitle: 'Atualizar', icon: 'refresh'),
      ShortcutItem(type: 'action_saved', localizedTitle: 'Cidades Salvas', icon: 'saved'),
      ShortcutItem(type: 'action_search', localizedTitle: 'Pesquisa', icon: 'search'),
    ]);

    _quickActions.initialize((String shortcutType) {
      if (shortcutType == 'action_home') {
        _navigatorKey.currentState?.pushNamed('/home');
      } else if (shortcutType == 'action_saved') {
        _navigatorKey.currentState?.pushNamed('/saved');
      } else if (shortcutType == 'action_search') {
        _navigatorKey.currentState?.pushNamed('/search');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App de Clima',
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorKey: _navigatorKey,
      // Redirecionar com base no estado de autenticação
      home: _user == null ? const LoginScreen() : const HomeScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/saved': (context) => const SavedCitiesScreen(),
        '/search': (context) => const SearchScreen(),
      },
    );
  }
}