import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification.dart';
import '../../services/auth_service.dart';

class NotificationService {
  static const String baseUrl = "http://192.168.1.70:8080/api";

  static Future<String?> _getJwtToken() async {
    return await AuthService.getToken();
  }

  static Future<List<NotificationModel>> getNotificationsByOuvrier(
    String ouvrierId,
  ) async {
    try {
      final token = await _getJwtToken();
      if (token == null) throw Exception("Utilisateur non connecté");
      final headers = {'Authorization': 'Bearer $token'};
      final uri = Uri.parse('$baseUrl/notifications/ouvrier/$ouvrierId');
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Erreur lors de la récupération des notifications: $e');
      return [];
    }
  }
}
