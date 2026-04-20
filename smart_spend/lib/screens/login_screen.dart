import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final TextEditingController _mobileController = TextEditingController(text: '09123456789'); // Default mock account
  final TextEditingController _mpinController = TextEditingController();
  bool _isLoading = false;

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
      setState(() {
        _mobileController.text = registered;
      });
      // Auto-trigger biometrics after a short UI delay
      Future.delayed(const Duration(milliseconds: 500), () => _triggerBiometrics());
    }
  }

  void _triggerBiometrics() async {
    if (_mobileController.text.isEmpty) return;
    
    bool authenticated = await BiometricService.authenticate();
    if (authenticated && mounted) {
      if (AuthService().biometricLogin(_mobileController.text.trim())) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No account found for this number.'), backgroundColor: Colors.redAccent));
      }
    }
  }

  void _performLogin() async {
    if (_mobileController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    await Future.delayed(const Duration(milliseconds: 1000));
    
    if (!mounted) return;
    
    bool valid = AuthService().login(_mobileController.text.trim(), _mpinController.text.trim());
    
    setState(() => _isLoading = false);

    if (valid) {
      // Register this mobile for future biometric login
      BiometricService.registerMobile(_mobileController.text.trim());
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const DashboardScreen()));
    } else {
      _mpinController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Mobile Number or MPIN.'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0055D4), Color(0xFF002255)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Branding Area
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Opacity(opacity: value, child: child);
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
                            ),
                            child: const Icon(Icons.wallet_rounded, size: 64, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'NovaPay',
                            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1.5),
                          ),
                          const Text(
                            'Your intelligent digital wallet.',
                            style: TextStyle(fontSize: 16, color: Colors.white60, fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),

                    // User Identity Area (Fixed Width for Mobile feel)
                    Container(
                      constraints: const BoxConstraints(maxWidth: 320),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 25, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Column(
                        children: [
                          const CircleAvatar(
                            radius: 35,
                            backgroundColor: Color(0xFF0044B2),
                            child: Icon(Icons.person_3_rounded, size: 35, color: Colors.white),
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0044B2), letterSpacing: 1.0),
                            decoration: InputDecoration(
                              hintText: 'Mobile Number',
                              hintStyle: TextStyle(color: Colors.black.withOpacity(0.2), fontSize: 18, fontWeight: FontWeight.normal),
                              border: InputBorder.none,
                              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blue.withOpacity(0.1))),
                              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF0044B2))),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // MPIN Section
                    _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Column(
                            children: [
                              const Text('Confirm MPIN to unlock', style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 16),
                              Container(
                                width: 220,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 15)),
                                  ],
                                ),
                                child: TextField(
                                  controller: _mpinController,
                                  obscureText: true,
                                  obscuringCharacter: '●',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  maxLength: 4,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 32, letterSpacing: 10, color: Color(0xFF003380), fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    counterText: '',
                                    hintText: '••••',
                                    hintStyle: TextStyle(color: Colors.black12, letterSpacing: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                    
                    const SizedBox(height: 32),

                    // Register Link
                    TextButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationScreen()));
                      },
                      child: Text.rich(
                        TextSpan(
                          text: "New here? ",
                          style: const TextStyle(color: Colors.white54, fontSize: 15),
                          children: [
                            TextSpan(
                              text: 'Create Account',
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
