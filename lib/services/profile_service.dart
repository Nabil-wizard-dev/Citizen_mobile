import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class ProfileService {
  static const String baseUrl = "http://10.0.201.34:8080/api/profile";

  // Récupérer le token JWT
  static Future<String?> _getJwtToken() async {
    return await AuthService.getToken();
  }

  // Récupérer le profil
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      // Récupérer le trackingId depuis localStorage
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr == null) {
        throw Exception("Données utilisateur non trouvées");
      }

      final userData = json.decode(userDataStr);
      final trackingId = userData['trackingId'];

      final headers = {'Authorization': 'Bearer $token'};
      final response = await http.get(
        Uri.parse('$baseUrl/$trackingId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Vérifier la structure de la réponse (error: false OU success: true)
        final isSuccess =
            responseData['error'] == false || responseData['success'] == true;

        if (isSuccess && responseData['data'] != null) {
          return {
            'success': true,
            'data': responseData['data'],
            'message': responseData['message'] ?? 'Profil récupéré avec succès',
          };
        } else {
          throw Exception('Réponse invalide du serveur');
        }
      } else {
        throw Exception(
          'Erreur lors de la récupération: ${response.statusCode}',
        );
      }
    } catch (e) {
      print(' Erreur lors de la récupération du profil: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Mettre à jour le profil
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      // Récupérer le trackingId depuis localStorage
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr == null) {
        throw Exception("Données utilisateur non trouvées");
      }

      final userData = json.decode(userDataStr);
      final trackingId = userData['trackingId'];

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.put(
        Uri.parse('$baseUrl/$trackingId'),
        headers: headers,
        body: json.encode(profileData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Vérifier la structure de la réponse (error: false OU success: true)
        final isSuccess =
            responseData['error'] == false || responseData['success'] == true;

        if (isSuccess && responseData['data'] != null) {
          // Mettre à jour les données locales
          final updatedUserData = <String, dynamic>{
            ...userData,
            ...responseData['data'],
          };
          await prefs.setString('user_data', json.encode(updatedUserData));
          print(' Profil mis à jour dans localStorage');

          return {
            'success': true,
            'data': responseData['data'],
            'message':
                responseData['message'] ?? 'Profil mis à jour avec succès',
          };
        } else {
          throw Exception('Réponse invalide du serveur');
        }
      } else {
        throw Exception(
          'Erreur lors de la mise à jour: ${response.statusCode}',
        );
      }
    } catch (e) {
      print(' Erreur lors de la mise à jour du profil: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Upload photo de profil
  static Future<Map<String, dynamic>> uploadProfilePhoto(File imageFile) async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      // Récupérer le trackingId depuis localStorage
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr == null) {
        throw Exception("Données utilisateur non trouvées");
      }

      final userData = json.decode(userDataStr);
      final trackingId = userData['trackingId'];

      // Créer la requête multipart
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/$trackingId/photo'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Ajouter le fichier
      request.files.add(
        await http.MultipartFile.fromPath('photo', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(' Status Code: ${response.statusCode}');
      print(' Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print(' Response Data: $responseData');

        // Vérifier la structure de la réponse (error: false OU success: true)
        final isSuccess =
            responseData['error'] == false || responseData['success'] == true;

        if (isSuccess && responseData['data'] != null) {
          final photoPath = responseData['data'];

          // Mettre à jour les données locales avec TOUTES les informations utilisateur
          final updatedUserData = <String, dynamic>{
            ...userData,
            'photoProfil': photoPath,
            // S'assurer que toutes les autres données sont préservées
            'trackingId': userData['trackingId'],
            'nom': userData['nom'],
            'prenom': userData['prenom'],
            'email': userData['email'],
            'role': userData['role'],
            'cni': userData['cni'],
            'numero': userData['numero'],
            'adresse': userData['adresse'],
            'dateNaissance': userData['dateNaissance'],
          };

          await prefs.setString('user_data', json.encode(updatedUserData));
          print('✅ Photo de profil mise à jour dans localStorage: $photoPath');
          print('✅ Données complètes mises à jour: ${updatedUserData.keys}');

          return {
            'success': true,
            'data': photoPath,
            'message': responseData['message'] ?? 'Photo uploadée avec succès',
          };
        } else {
          throw Exception('Réponse invalide du serveur: ${response.body}');
        }
      } else {
        final errorBody = response.body;
        print(' Erreur HTTP: $errorBody');
        throw Exception(
          'Erreur lors de l\'upload: ${response.statusCode} - $errorBody',
        );
      }
    } catch (e) {
      print(' Erreur lors de l\'upload de la photo: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Supprimer photo de profil
  static Future<Map<String, dynamic>> deleteProfilePhoto() async {
    try {
      final token = await _getJwtToken();
      if (token == null) {
        throw Exception("Utilisateur non connecté");
      }

      // Récupérer le trackingId depuis localStorage
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr == null) {
        throw Exception("Données utilisateur non trouvées");
      }

      final userData = json.decode(userDataStr);
      final trackingId = userData['trackingId'];

      final headers = {'Authorization': 'Bearer $token'};
      final response = await http.delete(
        Uri.parse('$baseUrl/$trackingId/photo'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Vérifier la structure de la réponse (error: false OU success: true)
        final isSuccess =
            responseData['error'] == false || responseData['success'] == true;

        if (isSuccess) {
          // Mettre à jour les données locales
          final updatedUserData = <String, dynamic>{
            ...userData,
            'photoProfil': null,
          };
          await prefs.setString('user_data', json.encode(updatedUserData));
          print('✅ Photo de profil supprimée de localStorage');

          return {
            'success': true,
            'message': responseData['message'] ?? 'Photo supprimée avec succès',
          };
        } else {
          throw Exception('Réponse invalide du serveur');
        }
      } else {
        throw Exception(
          'Erreur lors de la suppression: ${response.statusCode}',
        );
      }
    } catch (e) {
      print(' Erreur lors de la suppression de la photo: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Sélectionner une image depuis la galerie
  static Future<File?> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image != null ? File(image.path) : null;
    } catch (e) {
      print('❌ Erreur lors de la sélection d\'image: $e');
      return null;
    }
  }

  // Prendre une photo avec la caméra
  static Future<File?> takePhotoWithCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print(' Erreur lors de la prise de photo: $e');
      return null;
    }
  }
}
