import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  bool _isLoading = false;
  bool _enrollBiometrics = true;
  String? _profilePath;
  final ImagePicker _picker = ImagePicker();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mpinController = TextEditingController();

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (image != null) {
        setState(() { _profilePath = image.path; });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gallery unavailable.')));
    }
  }

  void _register() async {
    if (_mpinController.text.length < 4 || _mobileController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fill all fields.'), backgroundColor: Colors.redAccent));
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); 
    
    bool success = await AuthService().register(
      _nameController.text.trim(), _mobileController.text.trim(), _emailController.text.trim(), _mpinController.text.trim(),
      profilePic: _profilePath, enrollBiometrics: _enrollBiometrics,
    );
    
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('MISO IDENTITY SECURED. PLEASE LOGIN.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            backgroundColor: AppTheme.accentAmber,
            behavior: SnackBarBehavior.floating,
          )
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101838),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // BRANDING HEADER
              Center(
                child: Column(
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/MisoCash.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Miso Member Enrollment',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                    ),
                    Text(
                      'START YOUR FINANCIAL JOURNEY',
                      style: TextStyle(fontSize: 10, color: AppTheme.accentAmber.withOpacity(0.6), fontWeight: FontWeight.w900, letterSpacing: 2.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // Avatar
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50, backgroundColor: Colors.white10,
                  backgroundImage: _profilePath != null ? FileImage(File(_profilePath!)) : null,
                  child: _profilePath == null ? const Icon(Icons.add_a_photo_rounded, color: AppTheme.accentAmber, size: 30) : null,
                ),
              ),
              const SizedBox(height: 48),

              _buildCleanUniformInput('FULL NAME', Icons.person_outline_rounded, 'Enter Name', _nameController),
              const SizedBox(height: 24),
              _buildCleanUniformInput('MOBILE NUMBER', Icons.phone_iphone_rounded, '09XX XXX XXXX', _mobileController, type: TextInputType.phone),
              const SizedBox(height: 24),
              _buildCleanUniformInput('EMAIL ADDRESS', Icons.email_outlined, 'name@example.com', _emailController, type: TextInputType.emailAddress),
              
              const SizedBox(height: 32),

              // PIN SECTION
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Padding(
                    padding: EdgeInsets.only(left: 12, bottom: 8),
                    child: Text('SET SECURE MPIN', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      children: [
                        TextField(
                          controller: _mpinController,
                          obscureText: true, textAlign: TextAlign.center, maxLength: 4,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly], // STRICT NUMBERS ONLY
                          style: const TextStyle(fontSize: 32, letterSpacing: 15, color: AppTheme.accentAmber, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(border: InputBorder.none, counterText: '', hintText: '••••'),
                        ),
                        const Divider(),
                        Row(
                          children: [
                            const Icon(Icons.face_unlock_rounded, color: Colors.black26),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('Enroll Biometrics', style: TextStyle(color: Colors.black54, fontSize: 13))),
                            Switch(value: _enrollBiometrics, activeColor: AppTheme.accentAmber, onChanged: (v) => setState(() => _enrollBiometrics = v)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

               const SizedBox(height: 40),
              
              if (_isLoading)
                Column(
                  children: [
                    const LinearProgressIndicator(
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentAmber),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'SECURING MISO IDENTITY...',
                      style: TextStyle(color: AppTheme.accentAmber.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),

              SizedBox(
                width: double.infinity, height: 64,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentAmber, foregroundColor: const Color(0xFF101838), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                  onPressed: _isLoading ? null : _register,
                  child: Text(_isLoading ? 'PROCESS VERIFICATION...' : 'COMPLETE ENROLLMENT', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                ),
              ),
              
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ALREADY A MEMBER? LOG IN', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCleanUniformInput(String label, IconData icon, String hint, TextEditingController controller, {TextInputType type = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: TextField(
            controller: controller, keyboardType: type,
            style: const TextStyle(color: AppTheme.accentAmber, fontSize: 16, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              hintText: hint, hintStyle: const TextStyle(color: Colors.black12),
              prefixIcon: Icon(icon, color: AppTheme.accentAmber, size: 20),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}
