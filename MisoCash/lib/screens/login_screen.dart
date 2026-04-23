import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'dashboard_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController(); // Empty by default for user privacy
  final TextEditingController _mpinController = TextEditingController();
  bool _isLoading = false;
  bool _hasAttemptedBiometrics = false;

  @override
  void initState() {
    super.initState();
    _loadRegisteredMobile();
    _mpinController.addListener(() {
      if (_mpinController.text.length == 4) {
        _performLogin();
      }
    });
  }

  Future<void> _loadRegisteredMobile() async {
    final registered = await BiometricService.getRegisteredMobile();
    if (registered != null && mounted) {
      String clean = registered.replaceAll('+63', '');
      setState(() { _mobileController.text = clean; });
      if (!_hasAttemptedBiometrics) {
         Future.delayed(const Duration(milliseconds: 1000), () {
          _triggerBiometrics();
        });
      }
    }
  }

  Future<void> _triggerBiometrics() async {
    if (_mobileController.text.isEmpty) return;
    setState(() => _hasAttemptedBiometrics = true);
    final authenticated = await BiometricService.authenticate();
    if (authenticated) {
      final fullMobile = '+63${_mobileController.text.trim()}';
      final success = await AuthService().biometricLogin(fullMobile);
      if (success) {
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
      }
    }
  }

  Future<void> _performLogin() async {
    if (_mobileController.text.isEmpty || _mpinController.text.length < 4) return;
    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 1000));
    final fullMobile = '+63${_mobileController.text.trim()}';
    final success = await AuthService().login(fullMobile, _mpinController.text.trim());
    if (mounted) setState(() => _isLoading = false);
    if (success) {
      BiometricService.registerMobile(fullMobile);
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
    } else {
      if (mounted) {
        _mpinController.clear();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Details.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          width: double.infinity, height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF101838), Color(0xFF0A0F1A)]),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  children: [
                    // FLAWLESS ROUND LOGO
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: AppTheme.accentAmber.withOpacity(0.2), blurRadius: 20)],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Image.asset('assets/MisoCash.png', fit: BoxFit.contain),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('MisoCash', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                    const Text('PREMIUM ACCESS TERMINAL', style: TextStyle(fontSize: 10, color: AppTheme.accentAmber, fontWeight: FontWeight.w800, letterSpacing: 2.5)),
                    
                    const SizedBox(height: 56),

                    _buildCleanUniformInput('MOBILE NUMBER', Icons.phone_iphone_rounded, '9XX XXX XXXX', _mobileController, type: TextInputType.phone, isMobile: true),
                    const SizedBox(height: 32),
                    
                    // MPIN SECTION WITH CLEAN EXTERNAL LABEL
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 12, bottom: 8),
                          child: Text('SECURE MPIN', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15)]),
                          child: TextField(
                            controller: _mpinController,
                            obscureText: true, obscuringCharacter: '●', textAlign: TextAlign.center, maxLength: 4,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly], // STRICT NUMBERS ONLY
                            style: const TextStyle(fontSize: 32, letterSpacing: 15, color: AppTheme.accentAmber, fontWeight: FontWeight.bold),
                            decoration: const InputDecoration(border: InputBorder.none, counterText: '', hintText: '••••', hintStyle: TextStyle(color: Colors.black12)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),
                    if (_isLoading)
                      const CircularProgressIndicator(color: AppTheme.accentAmber)
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            flex: 4,
                            child: SizedBox(
                              height: 64,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentAmber, foregroundColor: const Color(0xFF101838), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
                                onPressed: _performLogin,
                                child: const Text('LOG IN ACCOUNT', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 64,
                              child: IconButton(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white10,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  padding: const EdgeInsets.all(16),
                                ),
                                icon: const Icon(Icons.fingerprint_rounded, color: AppTheme.accentAmber, size: 32),
                                onPressed: _triggerBiometrics,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationScreen())),
                        child: const Text('New Member? Register Identity', style: TextStyle(color: Colors.white70, fontSize: 13, decoration: TextDecoration.underline)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCleanUniformInput(String label, IconData icon, String hint, TextEditingController controller, {TextInputType type = TextInputType.text, bool isMobile = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15)]),
          child: TextField(
            controller: controller, 
            keyboardType: type,
            inputFormatters: isMobile ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)] : null,
            onChanged: isMobile ? (value) {
              if (value.startsWith('0')) {
                controller.text = value.substring(1);
                controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
              }
            } : null,
            style: const TextStyle(color: AppTheme.accentAmber, fontSize: 18, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              hintText: hint, 
              hintStyle: const TextStyle(color: Colors.black12),
              prefixIcon: Padding(padding: const EdgeInsets.only(left: 20, right: 15), child: Icon(icon, color: AppTheme.accentAmber, size: 22)),
              prefixText: isMobile ? '+63 ' : null,
              prefixStyle: const TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.bold, fontSize: 18),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
