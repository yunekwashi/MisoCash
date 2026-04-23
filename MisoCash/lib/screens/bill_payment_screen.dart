import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BillPaymentScreen extends StatefulWidget {
  const BillPaymentScreen({super.key});

  @override
  State<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen> {
  final List<Map<String, dynamic>> _billers = [
    {'name': 'Meralco', 'category': 'Electricity', 'icon': Icons.bolt_rounded, 'color': Colors.orange},
    {'name': 'Maynilad', 'category': 'Water', 'icon': Icons.water_drop_rounded, 'color': Colors.blue},
    {'name': 'Manila Water', 'category': 'Water', 'icon': Icons.opacity_rounded, 'color': Colors.lightBlue},
    {'name': 'PLDT', 'category': 'Internet', 'icon': Icons.router_rounded, 'color': Colors.red},
    {'name': 'Globe At Home', 'category': 'Internet', 'icon': Icons.wifi_rounded, 'color': Colors.blueAccent},
    {'name': 'Converge', 'category': 'Internet', 'icon': Icons.speed_rounded, 'color': Colors.purple},
    {'name': 'Sky Cable', 'category': 'Cable TV', 'icon': Icons.tv_rounded, 'color': Colors.indigo},
    {'name': 'Cignal', 'category': 'Cable TV', 'icon': Icons.settings_input_antenna_rounded, 'color': Colors.redAccent},
  ];

  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredBillers = _billers.where((b) => b['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Pay Bills', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search biller...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white38),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
              ),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 0.8,
                ),
                itemCount: filteredBillers.length,
                itemBuilder: (context, index) {
                  final biller = filteredBillers[index];
                  return GestureDetector(
                    onTap: () => _showPaymentForm(biller),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (biller['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(biller['icon'], color: biller['color'], size: 30),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          biller['name'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary),
                        ),
                        Text(
                          biller['category'],
                          style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentForm(Map<String, dynamic> biller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(biller['icon'], color: biller['color']),
                const SizedBox(width: 12),
                Text('Pay ${biller['name']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              ],
            ),
            const SizedBox(height: 32),
            const TextField(
              decoration: InputDecoration(labelText: 'Account Number', hintText: 'Enter account number'),
            ),
            const SizedBox(height: 20),
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount', prefixText: '₱ ', hintText: '0.00'),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Payment to ${biller['name']} processed successfully!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('PAY NOW', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
