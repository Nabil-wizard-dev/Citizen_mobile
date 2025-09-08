import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../services/auth_service.dart';
import '../models/tache.dart';

class TacheService {
  static const String baseUrl = "http://192.168.1.70:8080/api";

  // Méthode pour obtenir le token JWT
  static Future<String?> _getJwtToken() async {
    return await AuthService.getToken();
  }

  // Récupérer toutes les tâches affectées à l'ouvrier
  static Future<List<Tache>> fetchTachesOuvrier(String ouvrierId) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      final headers = {'Authorization': 'Bearer $token'};
      final uri = Uri.parse('$baseUrl/taches/all');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        List<dynamic> tachesData;

        if (responseData is Map<String, dynamic> &&
            responseData['success'] != null) {
          tachesData = responseData['data'] ?? [];
        } else if (responseData is List) {
          tachesData = responseData;
        } else {
          return [];
        }

        // Filtrer les tâches assignées à l'ouvrier
        final filtered =
            tachesData.where((json) {
              // On suppose que le champ ouvrierId ou ouvrier['id'] existe dans la tâche
              if (json['ouvrierId'] != null) {
                return json['ouvrierId'].toString() == ouvrierId.toString();
              } else if (json['ouvrier'] != null &&
                  json['ouvrier']['trackingId'] != null) {
                return json['ouvrier']['trackingId'].toString() ==
                    ouvrierId.toString();
              }
              return false;
            }).toList();

        return filtered.map((json) => Tache.fromJson(json)).toList();
      } else {
        print(
          'Erreur lors de la récupération des tâches: ${response.statusCode}',
        );
        return [];
      }
    } catch (e) {
      print('Erreur: $e');
      return [];
    }
  }

  // Mettre à jour l'état d'une tâche
  static Future<bool> updateEtatTache(
    int tacheId,
    String nouvelEtat, {
    String? commentaire,
    List<File>? photos,
  }) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      final uri = Uri.parse('$baseUrl/taches/update/$tacheId');
      var request = http.MultipartRequest('PUT', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Ajouter les données de mise à jour
      final updateData = {
        'isResolu': nouvelEtat == 'RESOLU',
        if (commentaire != null) 'commentaire': commentaire,
      };

      request.fields['request'] = jsonEncode(updateData);

      // Ajouter les photos s'il y en a
      if (photos != null && photos.isNotEmpty) {
        for (int i = 0; i < photos.length; i++) {
          final bytes = await photos[i].readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'photos',
              bytes,
              filename: 'photo_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la mise à jour de la tâche: $e');
      return false;
    }
  }

  // Récupérer une tâche par ID
  static Future<Tache?> getTacheById(int tacheId) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      final headers = {'Authorization': 'Bearer $token'};
      final uri = Uri.parse('$baseUrl/taches/$tacheId');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic> &&
            responseData['success'] != null) {
          return Tache.fromJson(responseData['data']);
        } else if (responseData is Map<String, dynamic>) {
          return Tache.fromJson(responseData);
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de la récupération de la tâche: $e');
      return null;
    }
  }

  // Créer un document de traitement pour un signalement
  static Future<bool> createTraitementDocument({
    required String signalementId,
    required String titre,
    required String description,
    required String commentaire,
    required String cout,
    required String duree,
    required String statut,
    List<File>? photos,
  }) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      final uri = Uri.parse('$baseUrl/taches/add');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Créer la requête de tâche
      final tacheData = {
        'dateDebut': DateTime.now().toIso8601String(),
        'dateFin': null,
        'isActiver': true,
        'isResolu': statut == 'TRAITE',
        'signalementId': signalementId,
        'commentaire': commentaire,
        'cout': cout,
        'duree': duree,
        'statut': statut,
      };

      request.fields['request'] = jsonEncode(tacheData);

      // Ajouter les photos s'il y en a
      if (photos != null && photos.isNotEmpty) {
        for (int i = 0; i < photos.length; i++) {
          final bytes = await photos[i].readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'fichierDevis',
              bytes,
              filename:
                  'traitement_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
            ),
          );
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic>) {
          if (responseData['success'] != null) {
            return responseData['success'] == true;
          } else if (responseData['error'] != null) {
            return responseData['error'] == false;
          }
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Erreur lors de la création du document de traitement: $e');
      return false;
    }
  }

  // Mettre à jour le statut d'un signalement
  static Future<bool> updateSignalementStatus({
    required String signalementId,
    required String newStatus,
    String? commentaire,
  }) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final uri = Uri.parse(
        '$baseUrl/signalements/${signalementId}/statut?statut=$newStatus',
      );
      final response = await http.patch(uri, headers: headers);

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
      return false;
    }
  }

  // Mettre à jour une tâche en envoyant uniquement le JSON (pas de fichier)
  static Future<bool> updateTacheSansFichier({
    required String tacheId,
    required Map<String, dynamic> tacheRequest,
  }) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }
      final uri = Uri.parse('$baseUrl/taches/update-json/$tacheId');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(tacheRequest),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la mise à jour de la tâche (JSON): $e');
      return false;
    }
  }

  // Envoi du PDF de traitement au backend
  static Future<Tache?> sendTraitementPdf({
    required String tacheId,
    required File pdfFile,
    String? commentaire,
    void Function(http.Response response)? onResponse,
  }) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      // Utiliser le bon endpoint pour l'envoi du rapport
      final uri = Uri.parse('$baseUrl/signalements/rapport/$tacheId');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      // Ajouter le fichier PDF
      request.files.add(
        await http.MultipartFile.fromPath(
          'pdf',
          pdfFile.path,
          filename: 'rapport_${DateTime.now().millisecondsSinceEpoch}.pdf',
        ),
      );

      // Ajouter le commentaire si fourni
      if (commentaire != null && commentaire.isNotEmpty) {
        request.fields['commentaire'] = commentaire;
      }

      print('📤 Envoi du rapport à : $uri');
      print('📦 Données : ${request.fields}');
      print('📎 Fichier : ${pdfFile.path}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (onResponse != null) onResponse(response);

      print('📡 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['data'] != null) {
          return Tache.fromJson(responseData['data']);
        }
      }
      return null;
    } catch (e) {
      print('Erreur lors de l\'envoi du rapport: $e');
      return null;
    }
  }

  static Future<List<Tache>> getTachesByOuvrier(String ouvrierId) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }
      final headers = {'Authorization': 'Bearer $token'};
      final uri = Uri.parse('$baseUrl/taches/ouvrier/$ouvrierId');
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((json) => Tache.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des tâches de l\'ouvrier: $e');
      return [];
    }
  }

  static Future<Tache?> getTacheBySignalement(String signalementId) async {
    final token = await _getJwtToken();
    if (token == null) throw Exception("Utilisateur non connecté");
    final uri = Uri.parse('$baseUrl/taches/bysignalement/$signalementId');
    final headers = {'Authorization': 'Bearer $token'};
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData['data'] != null) {
        return Tache.fromJson(responseData['data']);
      }
    }
    return null;
  }

  // Activer un signalement par trackingId (UUID)
  static Future<bool> activerSignalement(String trackingId) async {
    try {
      final token = await _getJwtToken();
      if (token == null) throw Exception("Utilisateur non connecté");
      final uri = Uri.parse('$baseUrl/signalements/activer/$trackingId');
      final headers = {'Authorization': 'Bearer $token'};
      final response = await http.post(uri, headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de l\'activation du signalement: $e');
      return false;
    }
  }

  // Rejeter un signalement par trackingId (UUID)
  static Future<bool> rejeterSignalement(String trackingId) async {
    try {
      final token = await _getJwtToken();
      if (token == null) throw Exception("Utilisateur non connecté");
      final uri = Uri.parse('$baseUrl/signalements/rejeter/$trackingId');
      final headers = {'Authorization': 'Bearer $token'};
      final response = await http.post(uri, headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors du rejet du signalement: $e');
      return false;
    }
  }

  static Future<bool> finaliserSignalement(String trackingId) async {
    try {
      final token = await _getJwtToken();
      if (token == null) throw Exception("Utilisateur non connecté");
      final uri = Uri.parse('$baseUrl/signalements/finaliser/$trackingId');
      final headers = {'Authorization': 'Bearer $token'};
      final response = await http.post(uri, headers: headers);
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la finalisation du signalement: $e');
      return false;
    }
  }
}
