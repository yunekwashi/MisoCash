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
import 'account_screen.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double _balance = 0.0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _mockTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = AuthService().currentUser;
    if (user != null) {
      setState(() {
        _balance = user.balance;
        _mockTransactions = user.transactions;
      });
    }
  }

  void _showVirtualTransactionDialog(String title, bool isCashIn) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();
    String selectedBank = 'BPI'; // Default bank

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
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryBlue,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title == 'Send Money' 
                        ? 'Enter recipient number and amount'
                        : isCashIn ? 'Select source and enter amount' : 'Enter amount to proceed',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  if (title == 'Send Money') ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text('Recipient Mobile No.', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '09XX XXX XXXX',
                          icon: Icon(Icons.phone_iphone_rounded, color: AppTheme.primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: -1.0),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0.00',
                        hintStyle: TextStyle(color: Colors.black26),
                        prefixText: '₱ ',
                        prefixStyle: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppTheme.secondaryBlue),
                      ),
                    ),
                  ),
                  if (isCashIn) ...[
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text('Source Bank', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.2), width: 1.5),
                        boxShadow: [
                          BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedBank,
                          isExpanded: true,
                          icon: const Icon(Icons.expand_more_rounded, color: AppTheme.primaryBlue),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                          items: ['BPI', 'BDO', 'UnionBank', 'Metrobank', 'GCash', 'Over-the-Counter']
                              .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                              .toList(),
                          onChanged: (v) {
                            setStateDialog(() {
                              if (v != null) selectedBank = v;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                  if (isCashIn && showQRCode) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: QrImageView(
                        data: 'novapay:${AuthService().currentUser?.mobileNumber ?? '0000'}?amount=${amountController.text.replaceAll(',', '')}',
                        version: QrVersions.auto,
                        size: 200.0,
                        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppTheme.primaryBlue),
                        dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: AppTheme.primaryBlue),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Scan this QR to receive funds', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                  ],
                  if (isCashIn) ...[
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: () => setStateDialog(() => showQRCode = !showQRCode),
                      icon: Icon(showQRCode ? Icons.edit_rounded : Icons.qr_code_2_rounded),
                      label: Text(showQRCode ? 'Back to Manual Entry' : 'Generate Receiving QR'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primaryBlue),
                    ),
                  ],
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () async {
                            final amountString = amountController.text.replaceAll(',', '');
                            if (amountString.isEmpty) return;
                            
                            final amount = double.tryParse(amountString) ?? 0.0;
                            if (amount <= 0) return;

                            if (!isCashIn && amount > _balance) {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(content: Text('Insufficient balance!')),
                              );
                              Navigator.pop(dialogContext);
                              return;
                            }

                            Navigator.pop(dialogContext); // Close dialog

                            setState(() {
                              _isLoading = true;
                            });

                            // Format text for the AI to parse
                            String finalTitle = title;
                            if (isCashIn) {
                              finalTitle = '$title via $selectedBank';
                            } else if (title == 'Send Money') {
                              final phone = phoneController.text.isNotEmpty ? phoneController.text : 'Unknown Number';
                              finalTitle = 'Sent to $phone';
                            }

                            final actionText = isCashIn 
                                ? 'Virtual Cash-In of $amount pesos from $selectedBank' 
                                : title == 'Send Money' 
                                    ? 'Sent $amount pesos to ${phoneController.text}'
                                    : 'Virtual Payment of $amount pesos';
                            
                            final success = await N8nService.sendTransaction(actionText, 'In-App Virtual Action');

                            if (!mounted) return;

                            setState(() {
                              _isLoading = false;
                              if (success) {
                                if (isCashIn) {
                                  _balance += amount;
                                  _mockTransactions.insert(0, {
                                    'title': 'Linked Bank ($selectedBank)',
                                    'date': 'Just now',
                                    'amount': amount,
                                    'icon': Icons.account_balance_rounded,
                                    'color': Colors.green,
                                  });
                                } else {
                                  _balance -= amount;
                                  _mockTransactions.insert(0, {
                                    'title': title == 'Send Money' ? 'Transfer to ${phoneController.text}' : 'Payment ($title)',
                                    'date': 'Just now',
                                    'amount': -amount,
                                    'icon': title == 'Send Money' ? Icons.send_rounded : Icons.payments_rounded,
                                    'color': AppTheme.textPrimary,
                                  });
                                }
                                
                                // Automatic Backend State Update
                                final user = AuthService().currentUser;
                                if (user != null) {
                                  user.balance = _balance; // Update local service
                                  N8nService.syncUser(user.fullName, user.mobileNumber, _balance);
                                }
                              }
                            });

                            if (success) {
                              Navigator.push(
                                this.context,
                                MaterialPageRoute(
                                  builder: (context) => ReceiptScreen(
                                    title: finalTitle,
                                    amount: amount,
                                    isCashIn: isCashIn,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(content: Text('Transaction failed to record.'), backgroundColor: Colors.red),
                              );
                            }
                          },
                          child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      },
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
      
      final success = await N8nService.sendTransaction('Scanned Merchant Payment: $scannedData', 'Live Camera Scan');
      
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        if (success) {
          double deductedAmount = 350.00; // Mock amount since n8n handles real parsing backend
          _balance -= deductedAmount;
          _mockTransactions.insert(0, {
            'title': 'Merchant QR Payment', 
            'date': 'Just now', 
            'amount': -deductedAmount, 
            'icon': Icons.camera_alt_rounded, 
            'color': AppTheme.textPrimary
          });
          
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
      appBar: AppBar(
        title: const Text('My Wallet'),
        leading: IconButton(
          icon: const Icon(Icons.person_outline_rounded), 
          onPressed: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const AccountScreen())
            );
          }
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
                              child: Text(
                                _balance.toStringAsFixed(2),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showVirtualTransactionDialog('Cash-In', true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_circle_rounded, color: AppTheme.primaryBlue, size: 20),
                              SizedBox(width: 6),
                              Text(
                                'Top Up',
                                style: TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
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
          
          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionItem(
                  icon: Icons.send_rounded, 
                  label: 'Send', 
                  onTap: () => _showVirtualTransactionDialog('Send Money', false),
                ),
                _buildActionItem(
                  icon: Icons.qr_code_scanner_rounded, 
                  label: 'QR Pay', 
                  onTap: () => _openQRScanner(),
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
                        child: const Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondaryBlue,
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
                                '${isNegative ? '-' : '+'} ₱${tx['amount'].abs().toStringAsFixed(2)}',
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
            child: Icon(icon, color: AppTheme.secondaryBlue, size: 30),
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
}
