import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../models/ouvrier.dart';

class OuvrierService {
  static const String baseUrl = "http://192.168.1.70:8080/api";

  // Méthode pour obtenir le token JWT
  static Future<String?> _getJwtToken() async {
    return await AuthService.getToken();
  }

  // Récupérer un ouvrier par ID
  static Future<Ouvrier?> getOuvrierById(String ouvrierId) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      final headers = {'Authorization': 'Bearer $token'};
      final uri = Uri.parse('$baseUrl/ouvriers/$ouvrierId');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('📊 Réponse ouvrier: $responseData');

        // Gérer la structure ApiResponse du backend
        if (responseData is Map<String, dynamic>) {
          if (responseData['error'] != null) {
            // Le backend retourne "error": true/false
            final isSuccess = responseData['error'] == false;
            if (isSuccess && responseData['data'] != null) {
              return Ouvrier.fromJson(responseData['data']);
            }
          } else if (responseData['success'] != null) {
            // Structure ApiResponse avec success
            if (responseData['success'] == true &&
                responseData['data'] != null) {
              return Ouvrier.fromJson(responseData['data']);
            }
          } else {
            // Structure directe
            return Ouvrier.fromJson(responseData);
          }
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de l\'ouvrier: $e');
      return null;
    }
  }

  // Récupérer tous les ouvriers
  static Future<List<Ouvrier>> getAllOuvriers() async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      final headers = {'Authorization': 'Bearer $token'};
      final uri = Uri.parse('$baseUrl/ouvriers/all');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('📊 Réponse tous les ouvriers: $responseData');

        List<dynamic> ouvriersData;

        // Gérer la structure ApiResponse du backend
        if (responseData is Map<String, dynamic>) {
          if (responseData['error'] != null) {
            // Le backend retourne "error": true/false
            final isSuccess = responseData['error'] == false;
            if (isSuccess && responseData['data'] != null) {
              ouvriersData = responseData['data'] as List<dynamic>;
            } else {
              return [];
            }
          } else if (responseData['success'] != null) {
            // Structure ApiResponse avec success
            if (responseData['success'] == true &&
                responseData['data'] != null) {
              ouvriersData = responseData['data'] as List<dynamic>;
            } else {
              return [];
            }
          } else {
            // Structure directe
            ouvriersData = responseData as List<dynamic>;
          }
        } else {
          return [];
        }

        return ouvriersData.map((json) => Ouvrier.fromJson(json)).toList();
      } else {
        print(
          'Erreur lors de la récupération des ouvriers: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('Erreur: $e');
      return [];
    }
  }
}
