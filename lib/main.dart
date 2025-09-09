import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'models/user.dart';
import 'ouvrier/home_ouvrier.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Communauté',
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {'/login': (_) => const LoginPage()},
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();

      if (isLoggedIn) {
        // Vérifier la validité du token
        final isTokenValid = await AuthService.isTokenValid();

        if (isTokenValid) {
          // Récupérer les informations utilisateur
          final userData = await AuthService.getUserData();
          if (userData != null) {
            setState(() {
              _isAuthenticated = true;
              _currentUser = User.fromJson(userData);
              _isLoading = false;
            });
            return;
          }
        } else {
          // Token invalide, nettoyer les données
          await AuthService.clearAllAuthData();
        }
      }

      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur lors de la vérification d\'authentification: $e');
      // En cas d'erreur, nettoyer les données et rediriger vers la connexion
      await AuthService.clearAllAuthData();
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthenticated || _currentUser == null) {
      return const LoginPage();
    }

    // Rediriger vers l'écran approprié selon le rôle
    if (_currentUser!.role == 'CITOYEN') {
      return HomeScreen(user: _currentUser!);
    } else if (_currentUser!.role == 'OUVRIER') {
      return HomeOuvrierScreen(user: _currentUser!);
    } else {
      // Rôle non reconnu, retourner à la page de connexion
      return const LoginPage();
    }
  }
}
