import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TransactionsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;

  const TransactionsScreen({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('All Transactions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Container(
        margin: const EdgeInsets.only(top: 16),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isNegative = tx['amount'] < 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w600, 
                            fontSize: 16, 
                            color: AppTheme.textPrimary
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tx['date'],
                          style: const TextStyle(
                            color: AppTheme.textSecondary, 
                            fontSize: 13
                          ),
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
    );
  }
}
