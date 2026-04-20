import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/n8n_service.dart';
import '../services/auth_service.dart';
import 'receipt_screen.dart';

class BuyLoadScreen extends StatefulWidget {
  final String? initialMobile;
  final double? initialAmount;
  const BuyLoadScreen({super.key, this.initialMobile, this.initialAmount});

  @override
  State<BuyLoadScreen> createState() => _BuyLoadScreenState();
}

class _BuyLoadScreenState extends State<BuyLoadScreen> {
  final TextEditingController _mobileController = TextEditingController();
  double? _selectedAmount;

  @override
  void initState() {
    super.initState();
    if (widget.initialMobile != null) {
      _mobileController.text = widget.initialMobile!;
    }
    if (widget.initialAmount != null) {
      _selectedAmount = widget.initialAmount;
    }
  }

  bool _isLoading = false;

  final List<double> _amounts = [10, 20, 30, 50, 100, 150, 200, 300, 500, 1000];

  String _getProvider(String phone) {
    if (phone.length < 4) return "NONE";
    String prefix = phone.substring(0, 4);
    
    // Globe / TM
    List<String> globePrefixes = ['0917', '0916', '0905', '0906', '0915', '0926', '0927', '0935', '0936', '0945', '0955', '0956', '0965', '0966', '0975', '0977', '0995', '0817'];
    if (globePrefixes.contains(prefix)) return "GLOBE";
    
    // Smart / TNT / Sun
    List<String> smartPrefixes = ['0918', '0919', '0920', '0921', '0928', '0929', '0939', '0947', '0949', '0907', '0908', '0909', '0910', '0912', '0930', '0938', '0946', '0948', '0950', '0922', '0923', '0925', '0931', '0932', '0933', '0934', '0942', '0943'];
    if (smartPrefixes.contains(prefix)) return "SMART";
    
    // DITO
    if (prefix.startsWith('0991') || prefix.startsWith('0992') || prefix.startsWith('0993') || prefix.startsWith('0994')) return "DITO";
    
    return "NONE";
  }

  Color _getProviderColor() {
    String provider = _getProvider(_mobileController.text);
    switch (provider) {
      case "GLOBE": return Colors.teal;
      case "SMART": return Colors.green;
      case "DITO": return Colors.redAccent;
      default: return AppTheme.primaryBlue;
    }
  }

  List<Map<String, dynamic>> _getPromos() {
    String provider = _getProvider(_mobileController.text);
    if (provider == "GLOBE") {
      return [
        {'name': 'Go50', 'desc': '5GB Data for 3 Days', 'price': 50.0},
        {'name': 'Go90', 'desc': '8GB Data for 7 Days', 'price': 90.0},
        {'name': 'Go+99', 'desc': '10GB Data + 8GB Choice of App', 'price': 99.0},
        {'name': 'Go+149', 'desc': '12GB Data + 8GB Choice of App', 'price': 149.0},
      ];
    } else if (provider == "SMART") {
      return [
        {'name': 'PowerAll 99', 'desc': '8GB Shareable Data + Unli TikTok', 'price': 99.0},
        {'name': 'GIGA Power 149', 'desc': '20GB Total Data (2GB/Day)', 'price': 149.0},
        {'name': 'Unli Data 399', 'desc': 'Unli Data for All Apps (30 Days)', 'price': 399.0},
      ];
    } else if (provider == "DITO") {
      return [
        {'name': 'Level-Up 99', 'desc': '7GB Data + Unli Allnet Texts', 'price': 99.0},
        {'name': 'Level-Up 199', 'desc': '16GB Data + Unli Allnet Texts', 'price': 199.0},
      ];
    }
    return [];
  }

  Future<void> _processPurchase(String name, double amount) async {
    if (_mobileController.text.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid number.')));
      return;
    }

    setState(() => _isLoading = true);

    final mobile = AuthService().currentUser?.mobileNumber ?? '';
    final success = await N8nService.sendTransaction(
      mobile,
      "Buy $name for ${_mobileController.text}",
      'Mobile Load'
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      final user = AuthService().currentUser;
      if (user != null) {
        user.balance -= amount;
        N8nService.syncUser(user.fullName, user.mobileNumber, user.email, user.balance, user.mpin, user.biometricEnabled);
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ReceiptScreen(
          title: 'Buy Load: $name (${_mobileController.text})',
          amount: amount,
          isCashIn: false,
        ))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Buy Load & Promos', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Regular Load'),
              Tab(text: 'Promos'),
            ],
          ),
        ),
        body: Container(
          margin: const EdgeInsets.only(top: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mobile Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _mobileController,
                      onChanged: (val) => setState(() {}),
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                      decoration: InputDecoration(
                        hintText: '09XX XXX XXXX',
                        prefixIcon: const Icon(Icons.phone_android_rounded),
                        suffixIcon: _getProvider(_mobileController.text) == "NONE" 
                          ? null 
                          : Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: _getProviderColor(), borderRadius: BorderRadius.circular(8)),
                                child: Text(_getProvider(_mobileController.text), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.03),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildRegularLoad(),
                    _buildPromosList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegularLoad() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black45)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2,
            ),
            itemCount: _amounts.length,
            itemBuilder: (context, index) {
              final amount = _amounts[index];
              bool isSelected = _selectedAmount == amount;
              return GestureDetector(
                onTap: () => setState(() => _selectedAmount = amount),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? _getProviderColor() : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? _getProviderColor() : Colors.black12, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '₱${amount.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isSelected ? Colors.white : AppTheme.textPrimary),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading || _selectedAmount == null ? null : () => _processPurchase('₱${_selectedAmount!.toStringAsFixed(0)} Load', _selectedAmount!),
              style: ElevatedButton.styleFrom(
                backgroundColor: _getProviderColor(),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Buy Regular Load', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromosList() {
    final promos = _getPromos();
    if (promos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.black.withOpacity(0.1)),
            const SizedBox(height: 16),
            const Text('Enter a number to see promos', style: TextStyle(color: Colors.black38, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: promos.length,
      itemBuilder: (context, index) {
        final promo = promos[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(promo['name'], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(promo['desc'], style: TextStyle(color: Colors.black.withOpacity(0.5), fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : () => _processPurchase(promo['name'], promo['price']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getProviderColor(),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text('₱${promo['price'].toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}
