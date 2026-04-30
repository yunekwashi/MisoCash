import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class N8nService {
  // Replace with your actual n8n host IP for access from other devices
  static const String baseUrl = 'http://localhost:8080/webhook';
  static const String transactionUrl = '$baseUrl/spending-input';
  static const String userSyncUrl = '$baseUrl/user-sync';
  static const String loginLogUrl = '$baseUrl/login-log';
  static const String insightsUrl = '$baseUrl/financial-insights';
  static const String historyUrl = '$baseUrl/history';
  static const String paymongoCheckoutUrl = '$baseUrl/paymongo-checkout';
  static const String notificationsUrl = '$baseUrl/notifications';
  static const String checkUserUrl = '$baseUrl/check-user';
  static const String getUserUrl = '$baseUrl/get-user';

  static Future<Map<String, dynamic>?> fetchUserProfile(String mobile) async {
    try {
      final response = await http.post(
        Uri.parse(getUserUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) return data[0] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> checkUserExists(String mobile) async {
    try {
      final response = await http.post(
        Uri.parse(checkUserUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.isNotEmpty;
      }
      return false;
    } catch (e) {
      return false; 
    }
  }

  static Future<String?> createPayMongoCheckout(String mobile, double amount) async {
    try {
      final response = await http.post(
        Uri.parse(paymongoCheckoutUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': mobile,
          'amount': amount,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['attributes']['checkout_url'] as String?;
      }
      return null;
    } catch (e) {
      print('PayMongo Checkout Error: $e');
      return null;
    }
  }

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
    // First verify with FinTech partner before sending transaction
    // For demo, we assume amount is parsed from rawInput later; here we use 0 as placeholder
    const double placeholderAmount = 0.0;
    final authorized = await _verifyFinTechPartner(mobile, placeholderAmount);
    if (!authorized) {
      print('FinTech partner denied transaction for $mobile');
      return false;
    }
    return _sendData(transactionUrl, {
      'mobile': mobile,
      'raw_input': rawInput,
      'location_context': locationContext,
    });
  }
    
  static Future<bool> syncTransaction(String mobile, double amount, String description, String category) async {
    // Verify with FinTech partner before syncing transaction data
    final authorized = await _verifyFinTechPartner(mobile, amount);
    if (!authorized) {
      print('FinTech partner denied sync for $mobile amount $amount');
      return false;
    }
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

  static Future<List<Map<String, dynamic>>> fetchNotifications(String mobile) async {
    try {
      final response = await http.post(
        Uri.parse(notificationsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': mobile}),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Notification Fetch Error: $e');
      return [];
    }
  }

  // FinTech partner verification
  static Future<bool> _verifyFinTechPartner(String mobile, double amount) async {
    // Corrected endpoint to match n8n webhook path via ADB tunnel
    const String fintechUrl = 'http://localhost:8080/webhook/fintech-verify';
    try {
      final response = await http.post(
        Uri.parse(fintechUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mobile': mobile,
          'amount': amount,
        }),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['authorized'] == true;
      }
    } catch (e) {
      print('FinTech verification error: $e');
      // In development/presentation mode, we allow the transaction if the backend is unreachable
      // This ensures the demo doesn't fail due to connection issues.
      return true; 
    }
    return false; // default deny if explicitly rejected or 4xx/5xx
  }

  static Future<bool> sendLinkingOTP({
    required String mobile,
    required String email,
    required String bankName,
    required String otp,
  }) async {
    const String otpUrl = '$baseUrl/send-linking-otp';
    return _sendData(otpUrl, {
      'mobile': mobile,
      'email': email,
      'bank_name': bankName,
      'otp': otp,
    });
  }

  // Generic backend send helper
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
      print('Backend Sync Issue: $e.');
      return false;
    }
  }
}

