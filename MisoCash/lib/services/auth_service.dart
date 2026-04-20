import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'n8n_service.dart';
import 'biometric_service.dart';

class UserAccount {
  final String fullName;
  final String mobileNumber;
  final String email;
  final String mpin;
  double balance;
  double dailyLimit;
  double monthlyLimit;
  List<Map<String, dynamic>> transactions;
  final List<String> linkedAccounts;
  String? profilePicture; // Local path to the image
  bool biometricEnabled;

  UserAccount({
    required this.fullName,
    required this.mobileNumber,
    required this.email,
    required this.mpin,
    this.balance = 0.0,
    this.dailyLimit = 100000.0,
    this.monthlyLimit = 500000.0,
    required this.transactions,
    required this.linkedAccounts,
    this.profilePicture,
    this.biometricEnabled = false,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static final Map<String, UserAccount> _accounts = {
    '09123456789': UserAccount(
      fullName: 'Mike Developer',
      mobileNumber: '09123456789',
      email: 'mike@misocash.com',
      mpin: '1234',
      balance: 12450.00,
      dailyLimit: 100000.0,
      monthlyLimit: 500000.0,
      transactions: [
        {'title': 'Starbucks Coffee', 'date': 'Today, 10:45 AM', 'amount': -250.00, 'icon': Icons.coffee_rounded, 'color': Colors.brown},
        {'title': 'Salary Deposit', 'date': 'Yesterday', 'amount': 45000.00, 'icon': Icons.work_rounded, 'color': Colors.green},
      ],
      linkedAccounts: ['BPI (****8822)', 'UnionBank (****1100)', 'GCash (Verified)'],
    ),
  };

  UserAccount? _currentUser;
  UserAccount? get currentUser => _currentUser;

  Future<void> saveProfilePicture(String path) async {
    if (_currentUser == null) return;
    _currentUser!.profilePicture = path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_pic_${_currentUser!.mobileNumber}', path);
  }

  Future<void> saveLimits(double daily, double monthly) async {
    if (_currentUser == null) return;
    _currentUser!.dailyLimit = daily;
    _currentUser!.monthlyLimit = monthly;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('daily_limit_${_currentUser!.mobileNumber}', daily);
    await prefs.setDouble('monthly_limit_${_currentUser!.mobileNumber}', monthly);
  }

  Future<void> loadPersistentData() async {
    if (_currentUser == null) return;
    final prefs = await SharedPreferences.getInstance();
    
    // Load Profile Pic
    final path = prefs.getString('profile_pic_${_currentUser!.mobileNumber}');
    if (path != null) _currentUser!.profilePicture = path;

    // Load Limits
    final daily = prefs.getDouble('daily_limit_${_currentUser!.mobileNumber}');
    final monthly = prefs.getDouble('monthly_limit_${_currentUser!.mobileNumber}');
    if (daily != null) _currentUser!.dailyLimit = daily;
    if (monthly != null) _currentUser!.monthlyLimit = monthly;
  }

  Future<bool> register(String fullName, String mobileNumber, String email, String mpin, {String? profilePic, bool enrollBiometrics = false}) async {
    String cleanMobile = mobileNumber.replaceAll(' ', '').replaceAll('-', '');
    if (_accounts.containsKey(cleanMobile)) return false; 
    
    final newAccount = UserAccount(
      fullName: fullName.isEmpty ? 'MisoCash User' : fullName,
      mobileNumber: cleanMobile,
      email: email,
      mpin: mpin,
      balance: 0.0,
      transactions: [],
      linkedAccounts: ['BPI (****1234)', 'GCash (0917***5678)'],
      profilePicture: profilePic,
    );
    
    _accounts[cleanMobile] = newAccount;
    
    final prefs = await SharedPreferences.getInstance();
    if (profilePic != null) {
      await prefs.setString('profile_pic_$cleanMobile', profilePic);
    }

    // Interactive Hardware Anchoring
    bool bioSuccess = false;
    if (enrollBiometrics) {
      bioSuccess = await BiometricService.registerMobile(cleanMobile);
      if (!bioSuccess) {
         print("Bio-anchor skipped or failed.");
      }
    }
    
    newAccount.biometricEnabled = bioSuccess;
    
    // Automatic Backend Sync
    N8nService.syncUser(
      newAccount.fullName, 
      newAccount.mobileNumber, 
      newAccount.email, 
      newAccount.balance,
      newAccount.mpin,
      newAccount.biometricEnabled
    );
    
    return true;
  }

  Future<bool> login(String mobile, String mpin) async {
    String cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (_accounts.containsKey(cleanMobile) && _accounts[cleanMobile]!.mpin == mpin) {
      _currentUser = _accounts[cleanMobile];
      await loadPersistentData();
      
      // Automatic Backend Login Event Recording
      N8nService.logLogin(cleanMobile);
      
      return true;
    }
    return false;
  }
  
  Future<bool> biometricLogin(String mobile) async {
    String cleanMobile = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (_accounts.containsKey(cleanMobile)) {
      _currentUser = _accounts[cleanMobile];
      await loadPersistentData();
      
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
