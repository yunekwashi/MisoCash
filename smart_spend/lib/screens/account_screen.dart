import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _biometricsEnabled = true;

  void _showLinkedAccounts() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text('Linked Accounts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 24),
              _buildLinkedBankItem(Icons.account_balance, 'BPI Savings', '**** 1234', Colors.red[700]!),
              _buildLinkedBankItem(Icons.credit_card, 'UnionBank Visa', '**** 9876', Colors.orange[700]!),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Link New Account'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                  foregroundColor: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLinkedBankItem(IconData icon, String bank, String number, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bank, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary)),
                Text(number, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          PlatformButton(icon: Icons.remove_circle_outline, color: Colors.redAccent, onPressed: () {})
        ],
      ),
    );
  }
  
  // Create a helper widget inside to avoid generic icon buttons looking bad
  Widget PlatformButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return IconButton(icon: Icon(icon, color: color), onPressed: onPressed);
  }

  void _showTransactionLimits() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Transaction Limits', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Wallet Limit', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              const Text('₱ 100,000.00 / ₱ 100,000.00', style: TextStyle(fontSize: 18, color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: 0.12, backgroundColor: Colors.black12, color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(4)),
              const SizedBox(height: 24),
              const Text('Daily Outgoing Limit', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              const Text('₱ 100,000.00', style: TextStyle(fontSize: 18, color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('My Account', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 48,
                    backgroundColor: AppTheme.primaryBlue,
                    child: Icon(Icons.person_rounded, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  Text(AuthService().currentUser?.fullName ?? 'User', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  Text(AuthService().currentUser?.mobileNumber ?? '+63', style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, color: Colors.green, size: 18),
                        SizedBox(width: 6),
                        Text('Fully Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Settings Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('SECURITY & SETTINGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 1.0)),
                  const SizedBox(height: 16),
                  _buildSettingsTile(Icons.account_balance_rounded, 'Linked Accounts', 'Manage cards and banks', onTap: _showLinkedAccounts),
                  _buildSettingsTile(Icons.bar_chart_rounded, 'Transaction Limits', 'View your GCash limits', onTap: _showTransactionLimits),
                  _buildSettingsTile(Icons.lock_rounded, 'Change MPIN', 'Update your security PIN', onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verification code sent to your mobile number.')));
                  }),
                  _buildSettingsTile(Icons.fingerprint_rounded, 'Biometrics Login', 'Enable Face ID / Touch ID', isSwitch: true),
                  
                  const SizedBox(height: 32),
                  const Text('SUPPORT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 1.0)),
                  const SizedBox(height: 16),
                  _buildSettingsTile(Icons.help_outline_rounded, 'Help Center', 'FAQs and Support Tickets', onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Redirecting to secure Help Center...')));
                  }),
                  _buildSettingsTile(Icons.info_outline_rounded, 'About App', 'Version 1.0.0 Final Project', onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'NovaPay',
                      applicationVersion: 'v1.0.0 (Final Project)',
                      applicationIcon: const Icon(Icons.account_balance_wallet_rounded, size: 48, color: AppTheme.primaryBlue),
                      children: [const Text('\nA premium app development final project featuring live QR scanning, automated n8n server webhooks, and modern fintech UI aesthetics.')],
                    );
                  }),
                  
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out successfully.')));
                      },
                      child: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, {VoidCallback? onTap, bool isSwitch = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: AppTheme.primaryBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        trailing: isSwitch 
            ? Switch(
                value: _biometricsEnabled, 
                activeColor: AppTheme.primaryBlue, 
                onChanged: (val) {
                  setState(() { _biometricsEnabled = val; });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? 'Biometrics activated' : 'Biometrics disabled')));
                }
              )
            : const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black26, size: 16),
        onTap: isSwitch ? () {
          setState(() { _biometricsEnabled = !_biometricsEnabled; });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_biometricsEnabled ? 'Biometrics activated' : 'Biometrics disabled')));
        } : onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
