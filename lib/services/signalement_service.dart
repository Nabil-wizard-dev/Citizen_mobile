import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;
import 'auth_service.dart';

class SignalementService {
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
    List<http.MultipartFile>? files,
  }) async {
    final token = await _getJwtToken();
    if (token == null) {
      throw Exception("Utilisateur non connecté");
    }

    final headers = {'Authorization': 'Bearer $token'};

    final uri = Uri.parse('$baseUrl$endpoint');

    switch (method.toUpperCase()) {
      case 'GET':
        return await http.get(uri, headers: headers);
      case 'POST':
        if (files != null) {
          // Requête multipart pour l'upload de fichiers
          var request = http.MultipartRequest('POST', uri);
          request.headers.addAll(headers);

          // Ajouter les champs de données
          if (body != null) {
            body.forEach((key, value) {
              request.fields[key] = value.toString();
            });
          }

          // Ajouter les fichiers
          request.files.addAll(files);

          return await request.send().then((response) async {
            return http.Response(
              await response.stream.bytesToString(),
              response.statusCode,
              headers: response.headers,
            );
          });
        } else {
          // Requête JSON normale
          headers['Content-Type'] = 'application/json; charset=UTF-8';
          return await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
        }
      case 'PUT':
        headers['Content-Type'] = 'application/json; charset=UTF-8';
        return await http.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      case 'PATCH':
        headers['Content-Type'] = 'application/json; charset=UTF-8';
        return await http.patch(
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

  // Récupérer tous les signalements
  static Future<Map<String, dynamic>> getSignalements() async {
    try {
      final response = await _authenticatedRequest(
        endpoint: '/signalements/all',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return {'success': true, 'data': []};
        }
        try {
          final responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic>) {
            // Le backend retourne "error": true/false au lieu de "success"
            if (responseData['error'] != null) {
              final isSuccess = responseData['error'] == false;
              return {
                'success': isSuccess,
                'message':
                    responseData['message'] ??
                    (isSuccess ? 'Opération réussie' : 'Erreur'),
                'data': responseData['data'],
              };
            } else if (responseData['success'] != null) {
              return responseData;
            } else {
              return {
                'success': false,
                'message': 'Format de réponse inattendu',
                'raw': response.body,
              };
            }
          } else if (responseData is List) {
            return {'success': true, 'data': responseData};
          } else {
            return {
              'success': false,
              'message': 'Format de réponse inattendu',
              'raw': response.body,
            };
          }
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
          'message': 'Erreur lors de la récupération des signalements',
          'raw': response.body,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Récupérer les signalements assignés à un ouvrier
  static Future<Map<String, dynamic>> getSignalementsByOuvrier(
    String ouvrierId,
  ) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      final headers = {'Authorization': 'Bearer $token'};
      final uri = Uri.parse('$baseUrl/signalements/allByOuvrier/$ouvrierId');

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return {
            'success': true,
            'data': [],
            'message': 'Aucun signalement trouvé',
          };
        }

        final responseData = json.decode(response.body);

        // Correction : forcer le succès si message == 'succes' et data est une liste
        if (responseData is Map<String, dynamic>) {
          final data = responseData['data'];
          final isApiSuccess =
              (responseData['error'] == false) ||
              (responseData['message'] == 'succes' &&
                  data != null &&
                  data is List);

          return {
            'success': isApiSuccess,
            'data': data ?? [],
            'message': responseData['message'] ?? '',
          };
        }
      }
      return {
        'success': false,
        'data': [],
        'message': 'Erreur lors de la récupération des signalements',
      };
    } catch (e) {
      return {'success': false, 'data': [], 'message': 'Erreur: $e'};
    }
  }

  // Créer un nouveau signalement (fichiers obligatoires)
  static Future<Map<String, dynamic>> createSignalement({
    required String titre,
    required String description,
    required String code,
    required String typeService,
    required double latitude,
    required double longitude,
    required List<File> images, // Fichiers obligatoires
    int? priorite,
    int? serviceId,
  }) async {
    try {
      print('=== DÉBUT CRÉATION SIGNALEMENT AVEC FICHIERS ===');

      // Préparer les données du signalement
      final signalementData = {
        'titre': titre,
        'code': code,
        'description': description,
        'typeService': typeService,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'serviceId': serviceId ?? 1,
        if (priorite != null) 'priorite': priorite,
      };

      print('Données à envoyer: ${jsonEncode(signalementData)}');

      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      // Utiliser le nouvel endpoint addInOne qui gère les fichiers
      final uri = Uri.parse('$baseUrl/signalements/create');
      print('URL de la requête: $uri');

      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      print('Headers de la requête: ${request.headers}');

      // Ajouter les données du signalement comme champ "request" (application/json)
      request.files.add(
        http.MultipartFile.fromString(
          'request',
          jsonEncode(signalementData),
          contentType: MediaType('application', 'json'),
        ),
      );

      // Ajouter les fichiers (obligatoires)
      for (int i = 0; i < images.length; i++) {
        final bytes = await images[i].readAsBytes();
        final originalName = p.basename(images[i].path); // Use path package for cross-platform basename
        final extension = originalName.split('.').last.toLowerCase();

        // Déterminer le type MIME basé sur l'extension
        String mimeSubtype;
        switch (extension) {
          case 'jpg':
          case 'jpeg':
            mimeSubtype = 'jpeg';
            break;
          case 'png':
            mimeSubtype = 'png';
            break;
          case 'gif':
            mimeSubtype = 'gif';
            break;
          default:
            mimeSubtype = 'jpeg'; // Par défaut si extension non reconnue
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'files',
            bytes,
            filename: originalName, // Only the filename, not the full path
            contentType: MediaType('image', mimeSubtype),
          ),
        );
      }

      print('Content-Type final: ${request.headers['content-type']}');
      print('Nombre de fichiers: ${request.files.length}');
      print('Champs: ${request.fields}');
      print(
        'Fichiers: ${request.files.map((f) => '${f.field}: ${f.filename}').toList()}',
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Code de statut: ${response.statusCode}');
      print('Corps de la réponse: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.isEmpty) {
          print('ERREUR: Réponse vide du serveur');
          return {
            'success': false,
            'message': 'Réponse vide du serveur - erreur probable côté backend',
          };
        }

        Map<String, dynamic> result;
        try {
          final responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic>) {
            // Le backend retourne "error": true/false au lieu de "success"
            if (responseData['error'] != null) {
              // Inverser la logique : error: false = succès, error: true = échec
              final isSuccess = responseData['error'] == false;
              result = {
                'success': isSuccess,
                'message':
                    isSuccess
                        ? 'Signalement envoyé avec succès !'
                        : (responseData['message'] ??
                            'Erreur lors de l\'envoi'),
                'data': responseData['data'],
              };
            } else if (responseData['success'] != null) {
              result = responseData;
            } else {
              result = {
                'success': false,
                'message': 'Format de réponse inattendu',
                'raw': response.body,
              };
            }
          } else if (responseData is List) {
            result = {'success': true, 'data': responseData};
          } else {
            result = {
              'success': false,
              'message': 'Format de réponse inattendu',
              'raw': response.body,
            };
          }
        } catch (e) {
          print('ERREUR JSON: $e');
          print('Corps de la réponse qui cause l\'erreur: "${response.body}"');
          return {
            'success': false,
            'message': 'Erreur de décodage JSON: $e',
            'raw': response.body,
          };
        }

        return result;
      } else {
        final errorResponse = json.decode(response.body);
        return {
          'success': false,
          'message':
              errorResponse['message'] ??
              'Erreur lors de la création du signalement',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Récupérer un signalement par ID
  static Future<Map<String, dynamic>> getSignalementById(String id) async {
    try {
      final response = await _authenticatedRequest(
        endpoint: '/signalements/$id',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return {'success': false, 'message': 'Signalement non trouvé'};
        }
        try {
          final responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic>) {
            // Le backend retourne "error": true/false au lieu de "success"
            if (responseData['error'] != null) {
              final isSuccess = responseData['error'] == false;
              return {
                'success': isSuccess,
                'message':
                    isSuccess
                        ? 'Signalement récupéré avec succès'
                        : (responseData['message'] ?? 'Erreur'),
                'data': responseData['data'],
              };
            } else if (responseData['success'] != null) {
              return responseData;
            } else {
              return {
                'success': false,
                'message': 'Format de réponse inattendu',
                'raw': response.body,
              };
            }
          } else if (responseData is List) {
            return {'success': true, 'data': responseData};
          } else {
            return {
              'success': false,
              'message': 'Format de réponse inattendu',
              'raw': response.body,
            };
          }
        } catch (e) {
          return {
            'success': false,
            'message': 'Réponse du serveur non valide (JSON attendu)',
            'raw': response.body,
          };
        }
      } else {
        return {'success': false, 'message': 'Signalement non trouvé'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Mettre à jour un signalement
  static Future<Map<String, dynamic>> updateSignalement({
    required String id,
    String? titre,
    String? description,
    String? code,
    String? typeService,
    String? statut,
    int? priorite,
    int? serviceId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (titre != null) body['titre'] = titre;
      if (description != null) body['description'] = description;
      if (code != null) body['code'] = code;
      if (typeService != null) body['typeService'] = typeService;
      if (priorite != null) body['priorite'] = priorite;
      if (serviceId != null) body['serviceId'] = serviceId;

      final response = await _authenticatedRequest(
        endpoint: '/signalements/update/$id',
        method: 'PUT',
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic> &&
            responseData['success'] != null) {
          return responseData;
        } else if (responseData is List) {
          return {'success': true, 'data': responseData};
        } else {
          return {
            'success': false,
            'message': 'Format de réponse inattendu',
            'raw': response.body,
          };
        }
      } else {
        final errorResponse = json.decode(response.body);
        return {
          'success': false,
          'message':
              errorResponse['message'] ?? 'Erreur lors de la mise à jour',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Supprimer un signalement
  static Future<Map<String, dynamic>> deleteSignalement(String id) async {
    try {
      final response = await _authenticatedRequest(
        endpoint: '/signalements/delete/$id',
        method: 'DELETE',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'message': 'Signalement supprimé avec succès'};
      } else {
        return {'success': false, 'message': 'Erreur lors de la suppression'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Récupérer les signalements par statut
  static Future<Map<String, dynamic>> getSignalementsByStatut(
    String statut,
  ) async {
    try {
      final response = await _authenticatedRequest(
        endpoint: '/signalements/statut/$statut',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          return {'success': true, 'data': []};
        }
        try {
          final responseData = json.decode(response.body);
          if (responseData is Map<String, dynamic>) {
            // Le backend retourne "error": true/false au lieu de "success"
            if (responseData['error'] != null) {
              final isSuccess = responseData['error'] == false;
              return {
                'success': isSuccess,
                'message':
                    isSuccess
                        ? 'Signalements récupérés avec succès'
                        : (responseData['message'] ?? 'Erreur'),
                'data': responseData['data'],
              };
            } else if (responseData['success'] != null) {
              return responseData;
            } else {
              return {
                'success': false,
                'message': 'Format de réponse inattendu',
                'raw': response.body,
              };
            }
          } else if (responseData is List) {
            return {'success': true, 'data': responseData};
          } else {
            return {
              'success': false,
              'message': 'Format de réponse inattendu',
              'raw': response.body,
            };
          }
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
          'message': 'Erreur lors de la récupération des signalements',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Récupérer les signalements par type de service
  static Future<Map<String, dynamic>> getSignalementsByType(String type) async {
    try {
      final response = await _authenticatedRequest(
        endpoint: '/signalements/type/$type',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic> &&
            responseData['success'] != null) {
          return responseData;
        } else if (responseData is List) {
          return {'success': true, 'data': responseData};
        } else {
          return {
            'success': false,
            'message': 'Format de réponse inattendu',
            'raw': response.body,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la récupération des signalements',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Récupérer les signalements par priorité
  static Future<Map<String, dynamic>> getSignalementsByPriorite(
    int priorite,
  ) async {
    try {
      final response = await _authenticatedRequest(
        endpoint: '/signalements/priorite/$priorite',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic> &&
            responseData['success'] != null) {
          return responseData;
        } else if (responseData is List) {
          return {'success': true, 'data': responseData};
        } else {
          return {
            'success': false,
            'message': 'Format de réponse inattendu',
            'raw': response.body,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la récupération des signalements',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Récupérer les signalements par service
  static Future<Map<String, dynamic>> getSignalementsByService(
    int serviceId,
  ) async {
    try {
      final response = await _authenticatedRequest(
        endpoint: '/signalements/service/$serviceId',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is Map<String, dynamic> &&
            responseData['success'] != null) {
          return responseData;
        } else if (responseData is List) {
          return {'success': true, 'data': responseData};
        } else {
          return {
            'success': false,
            'message': 'Format de réponse inattendu',
            'raw': response.body,
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Erreur lors de la récupération des signalements',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Mettre à jour le statut d'un signalement
  static Future<Map<String, dynamic>> updateStatut(
    String id,
    String statut,
  ) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      final headers = {'Authorization': 'Bearer $token'};
      final uri = Uri.parse('$baseUrl/signalements/$id/statut?statut=$statut');

      final response = await http.patch(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        final errorResponse = json.decode(response.body);
        return {
          'success': false,
          'message':
              errorResponse['message'] ??
              'Erreur lors de la mise à jour du statut',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }

  // Ajouter un commentaire à un signalement
  static Future<Map<String, dynamic>> addCommentaire(
    String id,
    String commentaire,
  ) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      final headers = {'Authorization': 'Bearer $token'};
      final uri = Uri.parse(
        '$baseUrl/signalements/$id/commentaire?commentaire=$commentaire',
      );

      final response = await http.patch(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return {'success': true, 'data': responseData};
      } else {
        final errorResponse = json.decode(response.body);
        return {
          'success': false,
          'message':
              errorResponse['message'] ??
              'Erreur lors de l\'ajout du commentaire',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur: $e'};
    }
  }
}
