import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class N8nService {
  // Replace with your actual n8n host IP for access from other devices
  static const String baseUrl = 'http://192.168.254.159:5678/webhook';
  static const String transactionUrl = '$baseUrl/spending-input';
  static const String userSyncUrl = '$baseUrl/user-sync';
  static const String loginLogUrl = '$baseUrl/login-log';
  static const String insightsUrl = '$baseUrl/financial-insights';
  static const String historyUrl = '$baseUrl/history';

  static Future<List<Map<String, dynamic>>> fetchTransactions(String mobile) async {
    try {
      final response = await http.post(
        Uri.parse(historyUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((t) {
          DateTime? dt;
          if (t['date'] != null) {
            try {
              dt = DateTime.parse(t['date'].toString());
            } catch (e) {}
          }
          String formattedDate = dt != null ? DateFormat('MMM dd, hh:mm a').format(dt) : DateFormat('MMM dd, hh:mm a').format(DateTime.now());

          return {
            'title': t['description'] ?? t['category'] ?? 'Transaction',
            'date': formattedDate,
            'amount': (t['type'] == 'expense' ? -1 : 1) * double.parse(t['amount'].toString()),
            'icon': (t['type'] == 'expense') ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            'color': (t['type'] == 'expense') ? Colors.orange : Colors.green,
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('History Fetch Error: $e');
      return [];
    }
  }

  static Future<String?> getPredictiveInsights(String mobile) async {
    try {
      final response = await http.post(
        Uri.parse(insightsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['insight'] as String?;
      }
      return null;
    } catch (e) {
      return "AI Insight currently unavailable.";
    }
  }

  static Future<bool> sendTransaction(String mobile, String rawInput, String locationContext) async {
    return _sendData(transactionUrl, {
      'mobile': mobile,
      'raw_input': rawInput,
      'location_context': locationContext,
    });
  }

  static Future<bool> syncTransaction(String mobile, double amount, String description, String category) async {
    return _sendData(transactionUrl, {
      'mobile': mobile,
      'amount': amount,
      'description': description,
      'category': category,
    });
  }

  static Future<bool> syncUser(String name, String mobile, String email, double balance, String mpin, bool biometricEnabled) async {
    return _sendData(userSyncUrl, {
      'name': name,
      'mobile': mobile,
      'email': email,
      'balance': balance,
      'mpin': mpin,
      'biometric_enabled': biometricEnabled,
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
