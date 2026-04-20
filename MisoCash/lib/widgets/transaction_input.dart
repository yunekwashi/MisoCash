import 'package:flutter/material.dart';
import '../services/n8n_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class TransactionInput extends StatefulWidget {
  const TransactionInput({super.key});

  @override
  State<TransactionInput> createState() => _TransactionInputState();
}

class _TransactionInputState extends State<TransactionInput> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  bool _isLoading = false;

  void _submitTransaction() async {
    final text = _controller.text.trim();
    final location = _locationController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final mobile = AuthService().currentUser?.mobileNumber ?? '';
    final success = await N8nService.sendTransaction(mobile, text, location);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (success) {
      _controller.clear();
      _locationController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction submitted for AI categorization!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit transaction'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Record',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Just type what you spent. Our AI will automatically categorize and record it.',
            style: TextStyle(
              color: AppTheme.textSecondary, 
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Location Context (e.g. Makati)',
                prefixIcon: Icon(Icons.location_on_rounded, color: AppTheme.secondaryBlue),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _controller,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Bought large coffee at starbucks for 180 pesos',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 24.0),
                  child: Icon(Icons.auto_awesome, color: AppTheme.secondaryBlue),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitTransaction,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text('Record Transaction', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
