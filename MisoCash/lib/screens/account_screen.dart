import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _biometricsEnabled = true;
  List<BiometricType> _availableBiometrics = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final available = await BiometricService.getAvailableBiometrics();
    setState(() {
      _availableBiometrics = available;
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      if (image != null) {
        await AuthService().saveProfilePicture(image.path);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated successfully!')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unable to open gallery. Please restart the app.'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  void _showHelpCenter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How can we help?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            const Text('Search for common topics or contact support.', style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 32),
            _buildFAQItem('Transfer Issues', 'Most transfers arrive instantly. Check your history for status.'),
            _buildFAQItem('Biometric Setup', 'Enable Face ID or Fingerprint in the security settings.'),
            _buildFAQItem('MisoCash Points', 'Earn points by completing daily transactions.'),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
                label: const Text('Contact Support 24/7', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF101838),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String title, String answer) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        children: [Padding(padding: const EdgeInsets.only(left: 16, bottom: 16), child: Text(answer, style: const TextStyle(color: AppTheme.textSecondary)))],
      ),
    );
  }

  void _showAbout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Color(0xFF101838),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/MisoCash.png', width: 80),
            const SizedBox(height: 24),
            const Text('MisoCash Premium', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
            const Text('Version 1.0.0 (Global Architecture)', style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 32),
            const Text('Designed for elite financial freedom. Powered by Miso AI and High-Security Protocols.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 15)),
            const SizedBox(height: 40),
            Text('© 2026 MISO FINTECH INC.', style: TextStyle(color: AppTheme.accentAmber.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
      ),
    );
  }

  void _showChangePIN() {
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_reset_rounded, size: 48, color: AppTheme.accentAmber),
            const SizedBox(height: 24),
            const Text('Change Secure PIN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 12, bottom: 8),
              child: Text('NEW SECURE MPIN', style: TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.black.withOpacity(0.05))),
              child: TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 32, letterSpacing: 10, fontWeight: FontWeight.bold, color: AppTheme.accentAmber),
                decoration: const InputDecoration(border: InputBorder.none, counterText: "", hintText: '••••', hintStyle: TextStyle(color: Colors.black12)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF101838), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Update PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLinkedAccounts() {
    final user = AuthService().currentUser;
    final accounts = user?.linkedAccounts ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
                  const Text('Linked Accounts', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.textPrimary)),
                  const SizedBox(height: 32),
                  if (accounts.isEmpty)
                    const Padding(padding: EdgeInsets.symmetric(vertical: 40.0), child: Text('No accounts linked yet', style: TextStyle(color: Colors.black38)))
                  else
                    ...accounts.map((acc) {
                      return ListTile(
                        leading: CircleAvatar(backgroundColor: AppTheme.primaryBlue.withOpacity(0.1), child: const Icon(Icons.account_balance_rounded, color: AppTheme.primaryBlue)),
                        title: Text(acc, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent), onPressed: () {
                          setState(() => accounts.remove(acc));
                          setModalState(() {});
                        }),
                      );
                    }).toList(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Connect New Source', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
    );
  }

  void _showTransactionLimits() {
    final user = AuthService().currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            backgroundColor: Colors.white,
            title: const Row(
              children: [
                Icon(Icons.speed_rounded, color: AppTheme.accentAmber),
                SizedBox(width: 12),
                Text('Power Limits', style: TextStyle(fontWeight: FontWeight.w900)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DAILY CAPACITY', style: TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text('₱${NumberFormat('#,##0.00').format(user.dailyLimit)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: 0.15, color: AppTheme.accentAmber, backgroundColor: AppTheme.accentAmber.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                const SizedBox(height: 24),
                Text('MONTHLY CAPACITY', style: TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text('₱${NumberFormat('#,##0.00').format(user.monthlyLimit)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppTheme.primaryBlue)),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: 0.05, color: AppTheme.primaryBlue, backgroundColor: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                const SizedBox(height: 32),
                if (user.dailyLimit < 500000)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final auth = await BiometricService.authenticate();
                          if (auth) {
                            await AuthService().saveLimits(user.dailyLimit + 50000, user.monthlyLimit + 100000);
                            setDialogState(() {});
                            setState(() {});
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account Level Up! Limits increased.'), backgroundColor: Colors.green));
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Security check unavailable. Please restart.') , backgroundColor: Colors.redAccent));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF101838), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('Level Up (Increase Limit)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: const Color(0xFF101838),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF101838), Color(0xFF1A237E)], begin: Alignment.topLeft, end: Alignment.bottomRight))),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        Hero(
                          tag: 'profile-pic',
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: CircleAvatar(
                                    radius: 55,
                                    backgroundColor: Colors.white10,
                                    backgroundImage: user?.profilePicture != null ? FileImage(File(user!.profilePicture!)) : null,
                                    child: user?.profilePicture == null ? const Icon(Icons.person_rounded, size: 60, color: Color(0xFF101838)) : null,
                                  ),
                                ),
                                Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: AppTheme.accentAmber, shape: BoxShape.circle), child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white))),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(user?.fullName ?? 'User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text(user?.mobileNumber ?? '+63', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                transform: Matrix4.translationValues(0, -30, 0),
                decoration: const BoxDecoration(color: Color(0xFFF8F9FE), borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40))),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    _buildSection('Security Terminal'),
                    _buildActionTile(Icons.account_balance_rounded, 'Linked Accounts', 'Banks and e-wallets', _showLinkedAccounts),
                    _buildActionTile(Icons.speed_rounded, 'Transaction Limits', 'Check daily capacity', _showTransactionLimits),
                    _buildActionTile(Icons.lock_outline_rounded, 'Change MPIN', 'Update security PIN', _showChangePIN),
                    _buildSwitchTile(Icons.face_unlock_rounded, 'Biometric Login', 'Face/Touch verification'),
                    const SizedBox(height: 32),
                    _buildSection('Support & Info'),
                    _buildActionTile(Icons.help_center_rounded, 'Help Center', 'FAQs and Support', _showHelpCenter),
                    _buildActionTile(Icons.info_outline_rounded, 'About MisoCash', 'Version 1.0.0 (Premium)', _showAbout),
                    const SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: OutlinedButton(
                        onPressed: () {
                          AuthService().logout();
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
                        },
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        child: const Text('Log Out Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(padding: const EdgeInsets.only(left: 4, bottom: 20), child: Align(alignment: Alignment.centerLeft, child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.black26, letterSpacing: 1.5))));
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: AppTheme.primaryBlue)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
      ),
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.accentAmber.withOpacity(0.08), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: AppTheme.accentAmber)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        trailing: Switch.adaptive(value: _biometricsEnabled, activeColor: AppTheme.accentAmber, onChanged: (v) => setState(() => _biometricsEnabled = v)),
      ),
    );
  }
}
