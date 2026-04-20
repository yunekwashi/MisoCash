import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const String _registeredMobileKey = 'registered_mobile';

  static Future<bool> canCheckBiometrics() async {
    try {
      final bool canCheck = await _auth.canCheckBiometrics;
      final bool isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (e) {
      print('Biometric Check Error: $e');
      return false;
    }
  }

  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      print('Error getting biometrics: $e');
      return [];
    }
  }

  static Future<String?> getRegisteredMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_registeredMobileKey);
  }

  static Future<bool> registerMobile(String mobile) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'ANCHOR MISO IDENTITY TO DEVICE HARDWARE',
      );
      
      if (didAuthenticate) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_registeredMobileKey, mobile);
        return true;
      }
      return false;
    } catch (e) {
      print('Anchor Error: $e');
      return false;
    }
  }

  static Future<void> clearRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_registeredMobileKey);
  }

  static Future<bool> authenticate() async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate to log in to MisoCash',
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
