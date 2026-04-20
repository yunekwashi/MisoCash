import 'package:flutter/material.dart';
import 'n8n_service.dart';

class UserAccount {
  final String fullName;
  final String mobileNumber;
  final String email;
  final String mpin;
  double balance;
  List<Map<String, dynamic>> transactions;

  UserAccount({
    required this.fullName,
    required this.mobileNumber,
    required this.email,
    required this.mpin,
    this.balance = 0.0,
    List<Map<String, dynamic>>? transactions,
  }) : transactions = transactions ?? [];
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final Map<String, UserAccount> _accounts = {
    '09123456789': UserAccount(
      fullName: 'Mike Developer',
      mobileNumber: '09123456789',
      email: 'mike@novapay.com',
      mpin: '1234',
      balance: 12450.00,
      transactions: [
        {'title': 'Starbucks Coffee', 'date': 'Today, 8:45 AM', 'amount': -180.00, 'icon': Icons.coffee_rounded, 'color': Colors.brown},
        {'title': 'Salary Deposit', 'date': 'Yesterday, 10:00 AM', 'amount': 25000.00, 'icon': Icons.work_rounded, 'color': Colors.green},
        {'title': 'Netflix Subscription', 'date': 'Apr 17, 2026', 'amount': -549.00, 'icon': Icons.movie_rounded, 'color': Colors.red},
      ]
    )
  };

  UserAccount? _currentUser;
  UserAccount? get currentUser => _currentUser;

  bool register(String fullName, String mobile, String email, String mpin) {
    String cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (_accounts.containsKey(cleanMobile)) return false; 
    
    final newAccount = UserAccount(
      fullName: fullName.isEmpty ? 'NovaPay User' : fullName,
      mobileNumber: cleanMobile,
      email: email,
      mpin: mpin,
      balance: 5000.00,
    );
    _accounts[cleanMobile] = newAccount;
    
    // Automatic Backend Sync
    N8nService.syncUser(newAccount.fullName, newAccount.mobileNumber, newAccount.balance);
    
    return true;
  }

  bool login(String mobile, String mpin) {
    String cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (_accounts.containsKey(cleanMobile) && _accounts[cleanMobile]!.mpin == mpin) {
      _currentUser = _accounts[cleanMobile];
      
      // Automatic Backend Login Event Recording
      N8nService.logLogin(cleanMobile);
      
      return true;
    }
    return false;
  }
  
  bool biometricLogin(String mobile) {
    String cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (_accounts.containsKey(cleanMobile)) {
      _currentUser = _accounts[cleanMobile];
      
      // Automatic Backend Login Event Recording
      N8nService.logLogin(cleanMobile);
      
      return true;
    }
    return false;
  }

  void logout() {
    _currentUser = null;
  }
}
