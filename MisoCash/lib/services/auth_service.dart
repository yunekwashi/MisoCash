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

  static final Map<String, UserAccount> _accounts = {};

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
    
    // Check Local & Database persistence for existing identity
    bool existsLocally = _accounts.containsKey(cleanMobile);
    bool existsRemote = await N8nService.checkUserExists(cleanMobile);

    if (existsLocally || existsRemote) {
      return false; 
    }
    
    final newAccount = UserAccount(
      fullName: fullName.isEmpty ? 'MisoCash User' : fullName,
      mobileNumber: cleanMobile,
      email: email,
      mpin: mpin,
      balance: 0.0,
      transactions: [],
      linkedAccounts: [],
      profilePicture: profilePic,
    );
    
    _accounts[cleanMobile] = newAccount;
    
    final prefs = await SharedPreferences.getInstance();
    if (profilePic != null) {
      await prefs.setString('profile_pic_$cleanMobile', profilePic);
    }

    // Biometric Enrollment (Asked One Time during Registration)
    bool bioSuccess = false;
    if (enrollBiometrics) {
      bioSuccess = await BiometricService.registerMobile(cleanMobile);
    }
    
    newAccount.biometricEnabled = bioSuccess;
    
    // Automatic Backend Sync
    await N8nService.syncUser(
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
    String cleanMobile = mobile.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Check local session first
    if (_accounts.containsKey(cleanMobile) && _accounts[cleanMobile]!.mpin == mpin) {
      _currentUser = _accounts[cleanMobile];
      await loadPersistentData();
      N8nService.logLogin(cleanMobile);
      return true;
    }

    // Attempt Backend Hydration if local fails (e.g., after app restart)
    final remoteUser = await N8nService.fetchUserProfile(cleanMobile);
    if (remoteUser != null && remoteUser['mpin'].toString() == mpin) {
       final account = UserAccount(
        fullName: remoteUser['name'],
        mobileNumber: remoteUser['mobile'],
        email: remoteUser['email'],
        mpin: remoteUser['mpin'].toString(),
        balance: double.tryParse(remoteUser['balance'].toString()) ?? 0.0,
        transactions: [],
        linkedAccounts: [],
        biometricEnabled: remoteUser['biometric_enabled'] == 1,
      );
      _accounts[cleanMobile] = account; // Cache locally
      _currentUser = account;
      await loadPersistentData();
      N8nService.logLogin(cleanMobile);
      return true;
    }
    
    return false;
  }
  
  Future<bool> biometricLogin(String mobile) async {
    String cleanMobile = mobile.replaceAll(RegExp(r'[^0-9+]'), '');
    
    if (_accounts.containsKey(cleanMobile)) {
      _currentUser = _accounts[cleanMobile];
      await loadPersistentData();
      N8nService.logLogin(cleanMobile);
      return true;
    }

    // Attempt Backend Hydration for Biometrics
    final remoteUser = await N8nService.fetchUserProfile(cleanMobile);
    if (remoteUser != null && remoteUser['biometric_enabled'] == 1) {
       final account = UserAccount(
        fullName: remoteUser['name'],
        mobileNumber: remoteUser['mobile'],
        email: remoteUser['email'],
        mpin: remoteUser['mpin'].toString(),
        balance: double.tryParse(remoteUser['balance'].toString()) ?? 0.0,
        transactions: [],
        linkedAccounts: [],
        biometricEnabled: true,
      );
      _accounts[cleanMobile] = account;
      _currentUser = account;
      await loadPersistentData();
      N8nService.logLogin(cleanMobile);
      return true;
    }
    
    return false;
  }

  void logout() {
    _currentUser = null;
  }
}
