import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'dart:math';

class ReceiptScreen extends StatelessWidget {
  final String title;
  final double amount;
  final bool isCashIn;
  final String date = DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.now());
  final String refNumber = List.generate(12, (index) => Random().nextInt(10).toString()).join();

  ReceiptScreen({
    super.key, 
    required this.title, 
    required this.amount, 
    this.isCashIn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const SizedBox(), 
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.textPrimary),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
              ),
              const SizedBox(height: 24),
              Text(
                'Transaction Successful',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 32),
              
              // Receipt Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Amount',
                      style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₱ ${amount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.textPrimary, letterSpacing: -1.0),
                    ),
                    const SizedBox(height: 32),
                    const Divider(color: Colors.black12, thickness: 1.5),
                    const SizedBox(height: 24),
                    _buildReceiptRow('Type', isCashIn ? 'Cash-In / Top Up' : 'Payment / Send'),
                    const SizedBox(height: 16),
                    _buildReceiptRow('Date & Time', date),
                    const SizedBox(height: 16),
                    _buildReceiptRow('Ref No.', refNumber),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Receipt securely saved to Gallery! ✓'), backgroundColor: Colors.green)
                    );
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Save as Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Dashboard', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
              )

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
