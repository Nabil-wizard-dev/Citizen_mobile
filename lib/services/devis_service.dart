import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'auth_service.dart';
import '../models/user.dart';
import '../models/signalement.dart' as model;

class DevisService {
  static const String baseUrl = "http://10.0.201.34:8080/api";

  // Méthode pour obtenir le token JWT
  static Future<String?> _getJwtToken() async {
    return await AuthService.getToken();
  }

  // Envoyer le PDF du devis
  static Future<Map<String, dynamic>> envoyerDevisPdf({
    required File pdfFile,
    required String titre,
    required model.Signalement signalement,
    required User ouvrier,
  }) async {
    try {
      print('📤 Envoi du PDF du devis...');
      print('📄 Fichier: ${pdfFile.path}');
      print('📊 Taille: ${await pdfFile.length()} bytes');

      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      final uri = Uri.parse('$baseUrl/signalements/uploadDevis');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Ajouter le fichier PDF
      final bytes = await pdfFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'pdf',
          bytes,
          filename: 'devis_${DateTime.now().millisecondsSinceEpoch}.pdf',
          contentType: MediaType('application', 'pdf'),
        ),
      );

      // Ajouter les métadonnées
      request.fields['titre'] = titre;
      request.fields['signalementId'] = signalement.trackingId ?? '';
      request.fields['ouvrierId'] = ouvrier.trackingId ?? '';
      request.fields['dateCreation'] = DateTime.now().toIso8601String();

      print('📤 Envoi de la requête...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic>) {
            if (responseData['error'] != null) {
              final isSuccess = responseData['error'] == false;
              return {
                'success': isSuccess,
                'message':
                    isSuccess
                        ? 'Devis envoyé avec succès !'
                        : (responseData['message'] ?? 'Erreur'),
                'data': responseData['data'],
              };
            } else if (responseData['success'] != null) {
              return responseData;
            }
          }
          return {
            'success': false,
            'message': 'Format de réponse inattendu',
            'raw': response.body,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Erreur de décodage JSON: $e',
            'raw': response.body,
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Erreur lors de l\'envoi du devis (${response.statusCode})',
          'raw': response.body,
        };
      }
    } catch (e) {
      print('❌ Erreur lors de l\'envoi: $e');
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Récupérer les devis d'un signalement
  static Future<Map<String, dynamic>> getDevisBySignalement(
    String signalementId,
  ) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      final headers = {'Authorization': 'Bearer $token'};
      final uri = Uri.parse('$baseUrl/signalements/devis/$signalementId');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return {'success': true, 'data': []};
        }
        try {
          final responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic>) {
            if (responseData['error'] != null) {
              final isSuccess = responseData['error'] == false;
              return {
                'success': isSuccess,
                'message': responseData['message'] ?? '',
                'data': responseData['data'],
              };
            } else if (responseData['success'] != null) {
              return responseData;
            }
          } else if (responseData is List) {
            return {'success': true, 'data': responseData};
          }
          return {
            'success': false,
            'message': 'Format de réponse inattendu',
            'raw': response.body,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Réponse du serveur non valide (JSON attendu)',
            'raw': response.body,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la récupération des devis',
          'raw': response.body,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Télécharger un devis PDF
  static Future<Map<String, dynamic>> telechargerDevisPdf(
    String devisId,
  ) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      final headers = {'Authorization': 'Bearer $token'};
      final uri = Uri.parse('$baseUrl/signalements/devis/$devisId/pdf');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.bodyBytes,
          'message': 'PDF téléchargé avec succès',
        };
      } else {
        return {
          'success': false,
          'message': 'Erreur lors du téléchargement du PDF',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Associer un devis à un signalement
  static Future<Map<String, dynamic>> associerDevis(
    String signalementId,
    String fichierId,
  ) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      final headers = {'Authorization': 'Bearer $token'};
      final uri = Uri.parse(
        '$baseUrl/signalements/associerDevis/$signalementId/$fichierId',
      );

      final response = await http.post(uri, headers: headers);

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic>) {
            if (responseData['error'] != null) {
              final isSuccess = responseData['error'] == false;
              return {
                'success': isSuccess,
                'message':
                    isSuccess
                        ? 'Devis associé avec succès !'
                        : (responseData['message'] ?? 'Erreur'),
                'data': responseData['data'],
              };
            } else if (responseData['success'] != null) {
              return responseData;
            }
          }
          return {
            'success': false,
            'message': 'Format de réponse inattendu',
            'raw': response.body,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Erreur de décodage JSON: $e',
            'raw': response.body,
          };
        }
      } else {
        return {
          'success': false,
          'message':
              'Erreur lors de l\'association du devis (${response.statusCode})',
          'raw': response.body,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }
}
