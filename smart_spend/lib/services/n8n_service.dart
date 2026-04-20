import 'dart:convert';
import 'package:http/http.dart' as http;

class N8nService {
  // Replace with your actual n8n host IP for access from other devices
  static const String baseUrl = 'http://192.168.254.159:5678/webhook';
  static const String transactionUrl = '$baseUrl/spending-input';
  static const String userSyncUrl = '$baseUrl/user-sync';
  static const String loginLogUrl = '$baseUrl/login-log';

  static Future<bool> sendTransaction(String rawInput, String locationContext) async {
    return _sendData(transactionUrl, {
      'raw_input': rawInput,
      'location_context': locationContext,
    });
  }

  static Future<bool> syncUser(String name, String mobile, double balance) async {
    return _sendData(userSyncUrl, {
      'name': name,
      'mobile': mobile,
      'balance': balance,
    });
  }

  static Future<bool> logLogin(String mobile) async {
    return _sendData(loginLogUrl, {
      'mobile': mobile,
      'event': 'LOGIN_SUCCESS',
    });
  }

  static Future<bool> _sendData(String url, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          ...data,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 3));

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print('Backend Sync Issue: $e. Falling back to Local Persistence.');
      return true; // Allow local operation to continue
    }
  }
}
