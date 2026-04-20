import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../services/n8n_service.dart';
import '../services/auth_service.dart';
import 'qr_scanner_screen.dart';
import 'receipt_screen.dart';
import 'transactions_screen.dart';
import 'send_money_screen.dart';
import 'account_screen.dart';
import 'notifications_screen.dart';
import 'login_screen.dart';
import 'buy_load_screen.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _balance = 0.0;
  bool _isLoading = false;
  String? _currentInsight;
  bool _isInsightLoading = false;
  List<Map<String, dynamic>> _mockTransactions = [];

  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _wordsSpoken = "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAIInsight();
  }

  Future<void> _loadAIInsight() async {
    setState(() => _isInsightLoading = true);
    final user = AuthService().currentUser;
    if (user != null) {
      final insight = await N8nService.getPredictiveInsights(user.mobileNumber);
      if (mounted) {
        setState(() {
          _currentInsight = insight;
          _isInsightLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    final user = AuthService().currentUser;
    if (user != null) {
      setState(() => _isLoading = true);
      
      // Fetch live history from backend
      final liveTransactions = await N8nService.fetchTransactions(user.mobileNumber);
      
      if (mounted) {
        setState(() {
          _balance = user.balance;
          if (liveTransactions.isNotEmpty) {
            _mockTransactions = liveTransactions;
            user.transactions = liveTransactions; // Update local session persistence
          } else {
            _mockTransactions = user.transactions;
          }
          _isLoading = false;
        });
      }
    }
  }

  void _showVirtualTransactionDialog(String title, bool isCashIn) {
    final user = AuthService().currentUser;
    final List<String> linkedAccounts = user?.linkedAccounts ?? [];

    if (isCashIn && linkedAccounts.isEmpty) {
      _showNoAccountSheet();
      return;
    }

    final TextEditingController amountController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    String selectedBank = linkedAccounts.isNotEmpty ? linkedAccounts.first : 'Manual Cash-In';

    amountController.addListener(() {
      String text = amountController.text;
      if (text.isEmpty) return;
      
      String cleanText = text.replaceAll(',', '');
      final parts = cleanText.split('.');
      if (parts.length > 2) return;
      
      try {
        final number = double.parse(parts[0].isEmpty ? '0' : parts[0]);
        final formatter = NumberFormat('#,##0', 'en_US');
        String newText = formatter.format(number);
        if (parts.length > 1) {
          newText += '.${parts[1]}';
        }
        
        if (text != newText) {
          amountController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          );
        }
      } catch (e) {}
    });

    phoneController.addListener(() {
      String text = phoneController.text.replaceAll(' ', '');
      if (text.isEmpty) return;

      // Keep only digits and cap at 11 characters (PH Standard)
      text = text.replaceAll(RegExp(r'[^0-9]'), '');
      if (text.length > 11) {
        text = text.substring(0, 11);
      }

      String newText = '';
      for (int i = 0; i < text.length; i++) {
        // Insert space after 4th and 7th digits (e.g., 0912 345 6789)
        if (i == 4 || i == 7) {
          newText += ' ';
        }
        newText += text[i];
      }

      if (phoneController.text != newText) {
        phoneController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    });

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool showQRCode = false;
        return StatefulBuilder(
          builder: (builderContext, setStateDialog) {
            final amountText = amountController.text.replaceAll(',', '');
            final amountValue = double.tryParse(amountText) ?? 0.0;
            final futureBalance = isCashIn ? _balance + amountValue : _balance - amountValue;
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF101838), Color(0xFF0A0F1A)]),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40, offset: const Offset(0, 20))],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.accentAmber.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(isCashIn ? Icons.account_balance_rounded : Icons.send_rounded, color: AppTheme.accentAmber, size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isCashIn ? 'Capital Deposit' : title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                      ),
                      Text(
                        isCashIn ? 'SECURE WALLET FUNDING' : 'SECURE TRANSFER TERMINAL',
                        style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 2.0),
                      ),
                      
                      const SizedBox(height: 32),

                      // RECIPENT MOBILE FOR SEND MONEY
                      if (title == 'Send Money') ...[
                         const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 12, bottom: 8),
                            child: Text('RECIPIENT MOBILE', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
                          child: TextField(
                            controller: phoneController, keyboardType: TextInputType.phone,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            decoration: const InputDecoration(border: InputBorder.none, hintText: '09XX XXX XXXX', hintStyle: TextStyle(color: Colors.white24), icon: Icon(Icons.phone_iphone_rounded, color: AppTheme.accentAmber, size: 20)),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // AMOUNT VAULT (Golden-White Style)
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 12, bottom: 8),
                          child: Text('ENTRY AMOUNT', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        ),
                      ),
                      // AMOUNT VAULT (Hyper-Premium Style)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                            BoxShadow(color: AppTheme.accentAmber.withOpacity(0.1), blurRadius: 10, spreadRadius: 0),
                          ],
                        ),
                        child: TextField(
                          controller: amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          onChanged: (v) => setStateDialog(() {}),
                          style: const TextStyle(
                            fontSize: 42, 
                            fontWeight: FontWeight.w900, 
                            color: AppTheme.accentAmber, 
                            letterSpacing: -1.5,
                            fontFamily: 'monospace', // Sharp numeric feel
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: '0.00',
                            hintStyle: TextStyle(color: Colors.black12),
                            prefixText: '₱ ',
                            prefixStyle: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black12),
                          ),
                        ),
                      ),

                      if (isCashIn) ...[
                        const SizedBox(height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 12, bottom: 8),
                            child: Text('SOURCE CHANNEL', style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedBank,
                              isExpanded: true,
                              dropdownColor: const Color(0xFF101838),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                              items: linkedAccounts.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                              onChanged: (v) => setStateDialog(() { if (v != null) selectedBank = v; }),
                            ),
                          ),
                        ),
                      ],

                      // RECEIVING QR MATRIX
                      if (isCashIn && showQRCode) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                          child: QrImageView(
                            data: 'misocash:${user?.mobileNumber ?? '0000'}?amount=$amountText',
                            version: QrVersions.auto,
                            size: 160.0,
                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.primaryBlue),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('SCAN TO FUND INSTANTLY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.accentAmber, letterSpacing: 1.5)),
                      ],

                      const SizedBox(height: 32),

                      // IMPACT PREVIEW BAR - REFINED & OVERFLOW-SAFE
                      if (amountValue > 0)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('PROJECTED WALLET STATE', 
                                      style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                    const SizedBox(height: 4),
                                    Text(isCashIn ? 'New Balance' : 'Remaining Funds', 
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '₱${NumberFormat('#,##0.00').format(futureBalance)}', 
                                style: TextStyle(
                                  color: isCashIn ? Colors.greenAccent : Colors.redAccent.withOpacity(0.8), 
                                  fontWeight: FontWeight.w900, 
                                  fontSize: 18,
                                  letterSpacing: -0.5,
                                )
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 40),

                      // ACTION PILLARS
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              child: const Text('ABORT', style: TextStyle(color: Colors.white30, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentAmber,
                                foregroundColor: const Color(0xFF101838),
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                elevation: 0,
                              ),
                              onPressed: () async {
                                final amountString = amountController.text.replaceAll(',', '');
                                if (amountString.isEmpty) return;
                                
                                final amount = double.tryParse(amountString) ?? 0.0;
                                if (amount <= 0) return;
                                
                                if (!isCashIn && amount > _balance) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Insufficient Liquid Assets!')));
                                  return;
                                }

                                Navigator.pop(dialogContext);
                                setState(() => _isLoading = true);
                                
                                String logTitle = isCashIn ? '$title ($selectedBank)' : (title == 'Send Money' ? 'Sent to ${phoneController.text}' : title);
                                final actionText = isCashIn 
                                    ? 'Virtual Deposit of $amount pesos from $selectedBank' 
                                    : 'Virtual Transfer of $amount to ${phoneController.text}';
                                
                                final mobile = AuthService().currentUser?.mobileNumber ?? '';
                                final success = await N8nService.sendTransaction(mobile, actionText, 'In-App Vault');
                                
                                if (!mounted) return;
                                setState(() {
                                  _isLoading = false;
                                  if (success) {
                                    if (isCashIn) {
                                      _balance += amount;
                                    } else {
                                      _balance -= amount;
                                    }
                                    
                                    // Sync local service
                                    final curUser = AuthService().currentUser;
                                    if (curUser != null) {
                                      curUser.balance = _balance;
                                      N8nService.syncUser(curUser.fullName, curUser.mobileNumber, curUser.email, _balance, curUser.mpin, curUser.biometricEnabled);
                                    }
                                    
                                    Navigator.push(this.context, MaterialPageRoute(builder: (context) => ReceiptScreen(title: logTitle, amount: amount, isCashIn: isCashIn)));
                                  } else {
                                    ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Terminal handshaking failed.'), backgroundColor: Colors.redAccent));
                                  }
                                });
                              },
                              child: Text(isCashIn ? 'CONFIRM DEPOSIT' : 'AUTHORIZE SEND', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      if (isCashIn)
                        TextButton.icon(
                          onPressed: () => setStateDialog(() => showQRCode = !showQRCode),
                          icon: Icon(showQRCode ? Icons.edit_rounded : Icons.qr_code_2_rounded, size: 18, color: Colors.white38),
                          label: Text(showQRCode ? 'Back to Manual Vault' : 'Generate Receiving QR', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  void _showNoAccountSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.05), shape: BoxShape.circle),
              child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryBlue, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Linked Accounts',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'To add money to your wallet, you first need to link a bank account or e-wallet for secure transfers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('Link Account Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openQRScanner() async {
    final scannedData = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
    
    if (scannedData != null && scannedData is String) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = true;
      });
      
      final mobile = AuthService().currentUser?.mobileNumber ?? '';
      final success = await N8nService.sendTransaction(mobile, 'Scanned Merchant Payment: $scannedData', 'Live Camera Scan');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        if (success) {
          double deductedAmount = 350.00; // Mock amount since n8n handles real parsing backend
          _balance -= deductedAmount;
          final user = AuthService().currentUser;
          if (user != null) {
            user.balance = _balance;
            N8nService.syncUser(user.fullName, user.mobileNumber, user.email, user.balance, user.mpin, user.biometricEnabled);
          }
          _loadUserData(); // Let the backend-fetch handle the list
          

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiptScreen(
                title: 'Merchant QR Payment',
                amount: deductedAmount,
                isCashIn: false,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to process QR code'), backgroundColor: Colors.red),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Forces dark icons (clock, battery)
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Wallet'),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const AccountScreen())
              );
            },
            child: Hero(
              tag: 'profile-pic',
              child: CircleAvatar(
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                backgroundImage: AuthService().currentUser?.profilePicture != null 
                    ? FileImage(File(AuthService().currentUser!.profilePicture!)) 
                    : null,
                child: AuthService().currentUser?.profilePicture == null 
                    ? const Icon(Icons.person_outline_rounded, color: AppTheme.primaryBlue, size: 20)
                    : null,
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded), 
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen())
              );
            }
          ),
        ],
      ),
      body: Column(
        children: [
          // Balance Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              '₱ ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Flexible(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 500),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Text(
                                  NumberFormat('#,##0.00').format(_balance),
                                  key: ValueKey(_balance), // TRiggers animation on change
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 12.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Processing transaction...',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Miso AI: Predictive Insight Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.accentAmber.withOpacity(0.15), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppTheme.accentAmber, shape: BoxShape.circle),
                        child: const Icon(Icons.auto_awesome_rounded, size: 16, color: Color(0xFF101838)),
                      ),
                      const SizedBox(width: 12),
                      const Text('MISO AI: PREDICTIVE INSIGHT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.accentAmber, letterSpacing: 1.5)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _isInsightLoading
                    ? const LinearProgressIndicator(backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentAmber))
                    : Text(
                        _currentInsight ?? "Miso AI is analyzing your spending patterns to predict future savings...",
                        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary, height: 1.5, fontWeight: FontWeight.w600),
                      ),
                ],
              ),
            ),
          ),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionItem(
                  icon: Icons.add_circle_rounded, 
                  label: 'Cash In', 
                  onTap: () => _showVirtualTransactionDialog('Cash-In', true),
                ),
                _buildActionItem(
                  icon: Icons.send_rounded, 
                  label: 'Send', 
                  onTap: () async {
                    final success = await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const SendMoneyScreen())
                    );
                    if (success == true) _loadUserData();
                  },
                ),
                _buildActionItem(
                  icon: Icons.qr_code_scanner_rounded, 
                  label: 'QR Pay', 
                  onTap: () => _openQRScanner(),
                ),
                _buildActionItem(
                  icon: Icons.phone_android_rounded, 
                  label: 'Buy Load', 
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const BuyLoadScreen()));
                    _loadUserData();
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          // Recent Transactions Area
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 32.0, left: 24.0, right: 24.0),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Transactions',
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TransactionsScreen(transactions: _mockTransactions),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.accentAmber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'SEE ALL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.accentAmber,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppTheme.accentAmber),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _mockTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = _mockTransactions[index];
                        final isNegative = tx['amount'] < 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: (tx['color'] as Color).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(tx['icon'], color: tx['color'], size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx['title'],
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tx['date'],
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isNegative ? '-' : '+'} ₱${NumberFormat('#,##0.00').format((tx['amount'] as num).abs())}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: isNegative ? AppTheme.textPrimary : Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isListening ? _stopListening : _startListening,
        backgroundColor: _isListening ? Colors.redAccent : AppTheme.accentAmber,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(_isListening ? Icons.mic_rounded : Icons.mic_none_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryBlue.withOpacity(0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: AppTheme.accentAmber, size: 30),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _startListening() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      bool available = await _speech.initialize(
        onStatus: (status) => print('Speech status: $status'),
        onError: (error) => print('Speech error: $error'),
      );
      
      if (available) {
        var systemLocales = await _speech.locales();
        String? targetLocale;
        // Search for Filipino, Tagalog, or general Philippine English locales
        for (var l in systemLocales) {
          final id = l.localeId.toLowerCase();
          if (id.contains('fil') || id.contains('tl') || id.contains('ceb') || id.contains('ph')) {
            targetLocale = l.localeId;
            break;
          }
        }

        setState(() {
          _isListening = true;
          _wordsSpoken = "";
        });
        
        _speech.listen(
          localeId: targetLocale,
          pauseFor: const Duration(seconds: 3),
          onResult: (result) {
            setState(() {
              _wordsSpoken = result.recognizedWords;
              if (result.finalResult) {
                _isListening = false;
                _processVoiceCommand(_wordsSpoken);
              }
            });
          },
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission is required for voice commands.')));
    }
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _processVoiceCommand(String text) async {
    if (text.isEmpty) return;
    String command = text.toLowerCase();
    
    // 1. Navigation Commands
    if (command.contains('transaction') || command.contains('history')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => TransactionsScreen(transactions: _mockTransactions)));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Transactions History...')));
      return;
    }
    
    if (command.contains('account') || command.contains('profile')) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountScreen()));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Account Settings...')));
      return;
    }

    if (command.contains('logout') || command.contains('exit')) {
      AuthService().logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logging out...')));
      return;
    }

    if (command.contains('balance') || command.contains('money')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your current balance is ₱${_balance.toStringAsFixed(2)}'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
      return;
    }

    // Voice Navigation & Feature Extraction
    if (command.contains('scan') || command.contains('qr') || command.contains('camera')) {
      _openQRScanner();
      return;
    }

    if (command.contains('buy load') || command.contains('load') || command.contains('paload')) {
      // Intelligent data extraction for Buy Load
      double? extractedLoad;
      String? extractedNo;
      
      final amountMatch = RegExp(r'\d+').firstMatch(command);
      if (amountMatch != null) extractedLoad = double.tryParse(amountMatch.group(0)!);
      
      final phoneMatch = RegExp(r'09\d{9}').firstMatch(command.replaceAll(' ', ''));
      if (phoneMatch != null) extractedNo = phoneMatch.group(0);

      await Navigator.push(context, MaterialPageRoute(builder: (context) => BuyLoadScreen(
        initialMobile: extractedNo,
        initialAmount: extractedLoad,
      )));
      _loadUserData();
      return;
    }

    if (command.contains('send money') || command.contains('transfer') || command.contains('padala')) {
       final success = await Navigator.push(context, MaterialPageRoute(builder: (context) => const SendMoneyScreen()));
       if (success == true) _loadUserData();
       return;
    }

    if (command.contains('account') || command.contains('profile') || command.contains('settings')) {
       await Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountScreen()));
       _loadUserData();
       return;
    }

    if ((command.contains('cash in') || command.contains('deposit') || command.contains('loading')) && !RegExp(r'\d').hasMatch(command)) {
      _showVirtualTransactionDialog('Cash-In', true);
      return;
    }

    // 2. Fallback to AI Logging (Smart Parsing)
    final regex = RegExp(r'\d+(\.\d+)?');
    final match = regex.firstMatch(command);
    double amount = 0.0;
    if (match != null) {
      amount = double.tryParse(match.group(0) ?? '0') ?? 0.0;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not detect an exact amount. Please specify an amount or use a direct command!'), backgroundColor: Colors.orange)
      );
      return;
    }


    bool isIncome = command.contains('cash in') || command.contains('deposit') || 
                    command.contains('receive') || command.contains('add') || 
                    command.contains('tanggap') || command.contains('pasok') || 
                    command.contains('dawat') || command.contains('sulod') || 
                    command.contains('padala');


    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isIncome ? 'Confirm Deposit?' : 'Confirm Expense?', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Did you mean to record a ${isIncome ? "deposit" : "payment"} of ₱${amount.toStringAsFixed(2)}?\n\n"$text"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentAmber, foregroundColor: Colors.black, elevation: 0),
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _isLoading = true);
              
              final mobile = AuthService().currentUser?.mobileNumber ?? '';
              final success = await N8nService.sendTransaction(mobile, text, 'Voice Assistant');
              
              if (!mounted) return;
              setState(() {
                _isLoading = false;
                if (success) {
                  if (isIncome) {
                    _balance += amount;
                  } else {
                    _balance -= amount;
                  }
                  
                  final user = AuthService().currentUser;
                  if (user != null) {
                    user.balance = _balance;
                    N8nService.syncUser(user.fullName, user.mobileNumber, user.email, user.balance, user.mpin, user.biometricEnabled);
                  }
                  
                  _loadUserData(); // Force refresh entire ledger from backend
                  
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction securely recorded!'), backgroundColor: Colors.green));
                  
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ReceiptScreen(
                    title: 'Record: ${text.length > 25 ? text.substring(0, 25) + '...' : text}', 
                    amount: amount, 
                    isCashIn: isIncome
                  )));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terminal Handshake Failed. Connection lost.'), backgroundColor: Colors.red));
                }
              });
            },
            child: const Text('Authorize', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      )
    );

  }
}
