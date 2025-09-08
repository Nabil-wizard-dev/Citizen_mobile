import 'dart:convert';
import 'dart:convert' show utf8, base64Url;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://192.168.1.70:8080/api/auth";
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  // Connexion
  static Future<Map<String, dynamic>> login(
    String email,
    String motDePasse,
  ) async {
    try {
      print(' Tentative de connexion pour: $email');
      print(' URL: $baseUrl/login');

      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email, 'motDePasse': motDePasse}),
      );

      print(' Status Code: ${response.statusCode}');
      print(' Response Body: ${response.body}');
      print(' Response Headers: ${response.headers}');

      if (response.statusCode == 200) {
        // Vérifier si la réponse est vide
        if (response.body.isEmpty) {
          print(' Réponse vide du serveur');
          return {
            'success': false,
            'message':
                'Réponse vide du serveur. Vérifiez la configuration de l\'API.',
          };
        }

        try {
          final jsonResponse = json.decode(response.body);
          print(' JSON décodé avec succès: $jsonResponse');

          // Gérer la structure ApiResponse si elle existe
          Map<String, dynamic> responseData;
          if (jsonResponse['success'] != null) {
            // Structure ApiResponse
            responseData = jsonResponse['data'] ?? jsonResponse;
            print(' Structure ApiResponse détectée');
          } else {
            // Structure directe
            responseData = jsonResponse;
            print(' Structure directe détectée');
          }

          final token = responseData['token'];
          final expiresIn = responseData['expiresIn'];
          final role = responseData['role'];

          if (token != null) {
            print('🔑 Token trouvé: ${token.substring(0, 20)}...');
            print('👤 Rôle détecté: $role');

            // Sauvegarder le token
            await saveToken(token);

            // Récupérer les informations complètes du profil
            Map<String, dynamic> completeUserData = await getCompleteUserData(
              token,
              responseData,
            );

            // Sauvegarder les données utilisateur complètes
            await saveUserData(completeUserData);
            print('👤 Données utilisateur complètes sauvegardées');

            return {
              'success': true,
              'token': token,
              'expiresIn': expiresIn,
              'role': role,
              'data': completeUserData,
            };
          } else {
            print('❌ Token non trouvé dans la réponse');
            return {
              'success': false,
              'message': 'Token non trouvé dans la réponse du serveur',
            };
          }
        } catch (jsonError) {
          print('❌ Erreur de décodage JSON: $jsonError');
          print('📄 Contenu de la réponse: ${response.body}');
          return {
            'success': false,
            'message': 'Réponse du serveur malformée: $jsonError',
          };
        }
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');

        // Essayer de décoder le message d'erreur
        try {
          if (response.body.isNotEmpty) {
            final errorResponse = json.decode(response.body);
            return {
              'success': false,
              'message':
                  errorResponse['message'] ??
                  'Erreur de connexion (${response.statusCode})',
            };
          } else {
            return {
              'success': false,
              'message':
                  'Erreur de connexion (${response.statusCode}) - Réponse vide',
            };
          }
        } catch (e) {
          return {
            'success': false,
            'message':
                'Erreur de connexion (${response.statusCode}) - ${response.body}',
          };
        }
      }
    } catch (e) {
      print('❌ Exception lors de la connexion: $e');
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  // Inscription
  static Future<Map<String, dynamic>> register({
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
    try {
      print('📝 Tentative d\'inscription pour: $email');
      print('🌐 URL: $baseUrl/register');

      final requestBody = {
        'nom': nom,
        'prenom': prenom,
        'cni': cni,
        'dateNaissance': dateNaissance,
        'email': email,
        'motDePasse': motDePasse,
        'numero': numero,
        'adresse': adresse,
        'role': role,
      };

      print('📤 Corps de la requête: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestBody),
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Vérifier si la réponse est vide
        if (response.body.isEmpty) {
          print('❌ Réponse vide du serveur');
          return {
            'success': false,
            'message':
                'Réponse vide du serveur. Vérifiez la configuration de l\'API.',
          };
        }

        try {
          final jsonResponse = json.decode(response.body);
          print('✅ JSON décodé avec succès: $jsonResponse');

          // Gérer la structure ApiResponse si elle existe
          Map<String, dynamic> responseData;
          if (jsonResponse['success'] != null) {
            // Structure ApiResponse
            responseData = jsonResponse['data'] ?? jsonResponse;
            print('📊 Structure ApiResponse détectée');
          } else {
            // Structure directe
            responseData = jsonResponse;
            print('📊 Structure directe détectée');
          }

          return {'success': true, 'data': responseData};
        } catch (jsonError) {
          print('❌ Erreur de décodage JSON: $jsonError');
          print('📄 Contenu de la réponse: ${response.body}');
          return {
            'success': false,
            'message': 'Réponse du serveur malformée: $jsonError',
          };
        }
      } else {
        print('❌ Erreur HTTP: ${response.statusCode}');

        // Essayer de décoder le message d'erreur
        try {
          if (response.body.isNotEmpty) {
            final errorResponse = json.decode(response.body);
            return {
              'success': false,
              'message':
                  errorResponse['message'] ??
                  'Erreur lors de l\'inscription (${response.statusCode})',
            };
          } else {
            return {
              'success': false,
              'message':
                  'Erreur lors de l\'inscription (${response.statusCode}) - Réponse vide',
            };
          }
        } catch (e) {
          return {
            'success': false,
            'message':
                'Erreur lors de l\'inscription (${response.statusCode}) - ${response.body}',
          };
        }
      }
    } catch (e) {
      print('❌ Exception lors de l\'inscription: $e');
      return {'success': false, 'message': 'Erreur lors de l\'inscription: $e'};
    }
  }

  // Sauvegarder le token JWT
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      print('💾 Token sauvegardé avec succès');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde du token: $e');
    }
  }

  // Récupérer le token JWT
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token != null) {
        print('🔑 Token récupéré: ${token.substring(0, 20)}...');
      } else {
        print('🔑 Aucun token trouvé');
      }
      return token;
    } catch (e) {
      print('❌ Erreur lors de la récupération du token: $e');
      return null;
    }
  }

  // Vérifier si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Déconnexion
  static Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      print('🚪 Déconnexion effectuée');
    } catch (e) {
      print('❌ Erreur lors de la déconnexion: $e');
    }
  }

  // Supprimer le token
  static Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      print('🗑️ Token supprimé');
    } catch (e) {
      print('❌ Erreur lors de la suppression du token: $e');
    }
  }

  // Sauvegarder les données utilisateur
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
    print('💾 Données utilisateur sauvegardées: ${userData.keys}');
  }

  // Récupérer les informations complètes du profil depuis le JWT
  static Future<Map<String, dynamic>> getCompleteUserData(
    String token,
    Map<String, dynamic> responseData,
  ) async {
    try {
      // Décoder le JWT pour extraire les informations
      final parts = token.split('.');
      if (parts.length != 3) {
        print('❌ Token JWT invalide');
        return responseData;
      }

      // Décoder le payload (partie 2)
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);

      print('🔍 Payload JWT décodé: $payloadMap');

      // Créer un objet utilisateur complet avec toutes les informations
      Map<String, dynamic> completeUserData = {
        'token': token,
        'expiresIn': responseData['expiresIn'],
        'role': payloadMap['role'] ?? responseData['role'],
        'trackingId': payloadMap['trackingId'],
        'nom': payloadMap['nom'] ?? '',
        'prenom': payloadMap['prenom'] ?? '',
        'email': payloadMap['sub'] ?? '', // Le subject du JWT est l'email
        'cni': payloadMap['cni'] ?? '',
        'numero': payloadMap['numero'] ?? 0,
        'adresse': payloadMap['adresse'] ?? '',
        'dateNaissance': payloadMap['dateNaissance'] ?? '',
        'photoProfil': payloadMap['photoProfil'],
      };

      print(
        '✅ Données utilisateur complètes extraites: ${completeUserData.keys}',
      );
      return completeUserData;
    } catch (e) {
      print('❌ Erreur lors de l\'extraction des données JWT: $e');
      // Retourner les données de base en cas d'erreur
      return {
        'token': token,
        'expiresIn': responseData['expiresIn'],
        'role': responseData['role'],
        'email': responseData['email'] ?? '',
      };
    }
  }

  // Récupérer les données utilisateur
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userKey);
      if (userDataString != null) {
        final userData = jsonDecode(userDataString);
        print('👤 Données utilisateur récupérées');
        return userData;
      }
      print('👤 Aucune donnée utilisateur trouvée');
      return null;
    } catch (e) {
      print('❌ Erreur lors de la récupération des données utilisateur: $e');
      return null;
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // Récupérer les informations complètes de l'utilisateur connecté
  static Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ Aucun token trouvé');
        return null;
      }

      print('🔍 Tentative de récupération des infos utilisateur...');
      print('🌐 URL: $baseUrl/me');

      final response = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          print('❌ Réponse vide du serveur');
          return null;
        }

        try {
          final userData = json.decode(response.body);
          print('👤 Informations utilisateur récupérées: $userData');

          // Mettre à jour les données utilisateur sauvegardées
          await saveUserData(userData);

          return userData;
        } catch (e) {
          print('❌ Erreur de décodage JSON: $e');
          print('📄 Contenu de la réponse: ${response.body}');

          // Essayer de nettoyer la réponse si elle est tronquée
          if (response.body.contains('...')) {
            print(
              '⚠️ Réponse JSON tronquée détectée, utilisation des données de base',
            );
            return await getUserData();
          }

          return null;
        }
      } else {
        print(
          '❌ Erreur lors de la récupération des informations utilisateur: ${response.statusCode}',
        );
        print('📄 Réponse d\'erreur: ${response.body}');
        return null;
      }
    } catch (e) {
      print(
        '❌ Exception lors de la récupération des informations utilisateur: $e',
      );
      return null;
    }
  }

  // Récupérer les infos complètes de l'ouvrier connecté
  static Future<Map<String, dynamic>?> getCurrentOuvrierInfo() async {
    try {
      final token = await getToken();
      if (token == null) {
        print('❌ Aucun token trouvé');
        return null;
      }

      print('🔍 Tentative de récupération des infos ouvrier...');
      print('🌐 URL: $baseUrl/me/ouvrier');

      final response = await http.get(
        Uri.parse('$baseUrl/me/ouvrier'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          print('❌ Réponse vide du serveur');
          return null;
        }

        try {
          final userData = json.decode(response.body);
          print('👷 Infos ouvrier récupérées: $userData');

          // Mettre à jour les données utilisateur sauvegardées
          await saveUserData(userData);

          return userData;
        } catch (e) {
          print('❌ Erreur de décodage JSON: $e');
          print('📄 Contenu de la réponse: ${response.body}');

          // Essayer de nettoyer la réponse si elle est tronquée
          if (response.body.contains('...')) {
            print(
              '⚠️ Réponse JSON tronquée détectée, utilisation des données de base',
            );
            return await getUserData();
          }

          return null;
        }
      } else {
        print(
          '❌ Erreur lors de la récupération des infos ouvrier: ${response.statusCode}',
        );
        print('📄 Réponse d\'erreur: ${response.body}');

        // Essayer l'endpoint /me comme fallback
        print('🔄 Tentative avec l\'endpoint /me comme fallback...');
        return await getCurrentUserInfo();
      }
    } catch (e) {
      print('❌ Exception lors de la récupération des infos ouvrier: $e');
      // Essayer l'endpoint /me comme fallback
      print('🔄 Tentative avec l\'endpoint /me comme fallback...');
      return await getCurrentUserInfo();
    }
  }

  // Nettoyer toutes les données d'authentification
  static Future<void> clearAllAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      print('🗑️ Toutes les données d\'authentification supprimées');
    } catch (e) {
      print(
        '❌ Erreur lors de la suppression des données d\'authentification: $e',
      );
    }
  }

  // Vérifier la validité du token
  static Future<bool> isTokenValid() async {
    try {
      final token = await getToken();
      if (token == null) {
        return false;
      }

      // Tenter de récupérer les informations utilisateur pour vérifier la validité
      final userInfo = await getCurrentUserInfo();
      return userInfo != null;
    } catch (e) {
      print('❌ Token invalide: $e');
      // Nettoyer les données d'authentification en cas d'erreur
      await clearAllAuthData();
      return false;
    }
  }

  // Déconnexion complète avec nettoyage
  static Future<void> forceLogout() async {
    try {
      await clearAllAuthData();
      print('🚪 Déconnexion forcée effectuée');
    } catch (e) {
      print('❌ Erreur lors de la déconnexion forcée: $e');
    }
  }
}
