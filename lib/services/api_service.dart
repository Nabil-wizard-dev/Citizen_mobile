import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = "http://10.0.201.34:8080/api";

  // Méthode pour obtenir le token JWT
  static Future<String?> _getJwtToken() async {
    return await AuthService.getToken();
  }

  // Méthode générique pour faire des requêtes authentifiées
  static Future<http.Response> _authenticatedRequest({
    required String endpoint,
    required String method,
    Map<String, dynamic>? body,
    Map<String, String>? additionalHeaders,
  }) async {
    final token = await _getJwtToken();
    if (token == null) {
      throw Exception("Utilisateur non connecté");
    }

    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
      ...?additionalHeaders,
    };

    final uri = Uri.parse('$baseUrl$endpoint');

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        return await http.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PUT':
        return await http.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'DELETE':
        return await http.delete(uri, headers: headers);
      default:
        throw Exception("Méthode HTTP non supportée: $method");
    }
  }

  // Méthode pour l'inscription (sans authentification)
  static Future<http.Response> register({
    required String nom,
    required String prenom,
    required String cni,
    required String dateNaissance,
    required String email,
    required String motDePasse,
    required int numero,
    required String adresse,
    required String role,
  }) async {
    return await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        "nom": nom,
        "prenom": prenom,
        "cni": cni,
        "dateNaissance": dateNaissance,
        "email": email,
        "motDePasse": motDePasse,
        "numero": numero,
        "adresse": adresse,
        "role": role,
      }),
    );
  }

  // Méthode pour la connexion (sans authentification)
  static Future<http.Response> login({
    required String email,
    required String motDePasse,
  }) async {
    return await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email, 'motDePasse': motDePasse}),
    );
  }

  // Exemple de méthode authentifiée pour récupérer les signalements
  static Future<http.Response> getSignalements() async {
    return await _authenticatedRequest(
      endpoint: '/signalements',
      method: 'GET',
    );
  }

  // Exemple de méthode authentifiée pour créer un signalement
  static Future<http.Response> createSignalement(
    Map<String, dynamic> signalementData,
  ) async {
    return await _authenticatedRequest(
      endpoint: '/signalements',
      method: 'POST',
      body: signalementData,
    );
  }

  // Exemple de méthode authentifiée pour récupérer le profil utilisateur
  static Future<http.Response> getUserProfile() async {
    return await _authenticatedRequest(
      endpoint: '/user/profile',
      method: 'GET',
    );
  }

  // Exemple de méthode authentifiée pour mettre à jour le profil utilisateur
  static Future<http.Response> updateUserProfile(
    Map<String, dynamic> profileData,
  ) async {
    return await _authenticatedRequest(
      endpoint: '/user/profile',
      method: 'PUT',
      body: profileData,
    );
  }
}
