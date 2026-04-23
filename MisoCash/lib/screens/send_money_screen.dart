import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/n8n_service.dart';
import '../services/biometric_service.dart';
import 'receipt_screen.dart';

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _selectedContact;
  final List<Map<String, String>> _recentContacts = [];

  void _handleSend() async {
    if (_amountController.text.isEmpty || _phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final user = AuthService().currentUser;
    final fullPhone = '+63${_phoneController.text.trim()}';

    if (user != null && amount > user.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient balance'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Biometric Authorization (Required for each transfer)
    final authenticated = await BiometricService.authenticate();
    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identity verification failed. Transaction cancelled.'), backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    // Mock processing delay for premium feel
    await Future.delayed(const Duration(seconds: 1));

    try {
      if (user != null) {
        await N8nService.sendTransaction(
          user.mobileNumber,
          'Sent ₱$amount to $fullPhone',
          'Transfer',
        );
        
        // Update local session balance
        user.balance -= amount;

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ReceiptScreen(
              title: 'Send Money to $fullPhone',
              amount: amount,
              isCashIn: false,
            ))
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF101838),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Send Money', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RECENT RECIPIENTS', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _recentContacts[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _phoneController.text = contact['phone']!.replaceAll('+63', '');
                                _selectedContact = contact['name'];
                              });
                            },
                            child: Column(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: _selectedContact == contact['name'] ? AppTheme.accentAmber : Colors.white.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _selectedContact == contact['name'] ? AppTheme.accentAmber : Colors.white.withOpacity(0.1), width: 2),
                                  ),
                                  child: Center(
                                    child: Text(contact['initials']!, style: TextStyle(color: _selectedContact == contact['name'] ? const Color(0xFF101838) : Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(contact['name']!, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Main Input Area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(40), topRight: Radius.circular(40)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 8),
                        child: Text('RECIPIENT DETAILS', style: TextStyle(color: Colors.black38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
                      
                      // Phone Number Input
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white, // UNIFORM WHITE BG
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.black.withOpacity(0.05)),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.accentAmber), // UNIFORM YELLOW TEXT
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                          onChanged: (value) {
                            if (value.startsWith('0') && value.length > 1) {
                              _phoneController.text = value.substring(1);
                              _phoneController.selection = TextSelection.fromPosition(TextPosition(offset: _phoneController.text.length));
                            } else if (value == '0') {
                              _phoneController.clear();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: '9XX XXX XXXX',
                            hintStyle: TextStyle(color: Colors.black.withOpacity(0.1), fontSize: 14),
                            border: InputBorder.none,
                            icon: Icon(Icons.phone_android_rounded, color: AppTheme.accentAmber, size: 20),
                            prefixText: '+63 ',
                            prefixStyle: const TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 8),
                        child: Text('SET TRANSFER AMOUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black38, letterSpacing: 1.5)),
                      ),

                      // Amount Input
                      Container(
                        alignment: Alignment.center,
                        child: Column(
                          children: [
                            const Text('₱', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.accentAmber)),
                            TextField(
                              controller: _amountController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppTheme.accentAmber, letterSpacing: -1),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(color: Colors.black12),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Send Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSend,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF101838),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 8,
                            shadowColor: const Color(0xFF101838).withOpacity(0.5),
                          ),
                          child: _isLoading
                            ? const CircularProgressIndicator(color: AppTheme.accentAmber)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.send_rounded, color: AppTheme.accentAmber),
                                  const SizedBox(width: 12),
                                  const Text('CONFIRM TRANSFER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                                ],
                              ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          'Remaining Balance: ₱${AuthService().currentUser?.balance.toStringAsFixed(2) ?? "0.00"}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
