import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _registeredMobileKey = 'registered_mobile';

  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } on PlatformException catch (e) {
      print('Biometric Check Error: $e');
      return false;
    }
  }

  static Future<String?> getRegisteredMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_registeredMobileKey);
  }

  static Future<void> registerMobile(String mobile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_registeredMobileKey, mobile);
  }

  static Future<void> clearRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_registeredMobileKey);
  }

  static Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to log in to NovaPay',
      );
      return didAuthenticate;
    } on PlatformException catch (e) {
      print('Authentication Error: $e');
      return false;
    } catch (e) {
      print('Generic Auth Error: $e');
      return false;
    }
  }
}
