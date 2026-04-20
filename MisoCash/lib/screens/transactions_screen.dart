import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class TransactionsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;

  const TransactionsScreen({super.key, required this.transactions});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  late List<Map<String, dynamic>> _filteredTransactions;
  String _searchQuery = "";
  String _selectedFilter = "All"; // All, In, Out

  @override
  void initState() {
    super.initState();
    _filteredTransactions = widget.transactions;
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = widget.transactions.where((tx) {
        final matchesSearch = tx['title'].toLowerCase().contains(_searchQuery.toLowerCase());
        final isNegative = tx['amount'] < 0;
        
        bool matchesFilter = true;
        if (_selectedFilter == "In") matchesFilter = !isNegative;
        if (_selectedFilter == "Out") matchesFilter = isNegative;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF101838),
        appBar: AppBar(
          title: const Text('Transaction History', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: -0.5, color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // Search & Filters Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Search Bar - ULTIMATE CONTRAST STYLE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) {
                        _searchQuery = value;
                        _applyFilters();
                      },
                      style: const TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.bold, fontSize: 16), // UNIFORM YELLOW TEXT
                      cursorColor: AppTheme.accentAmber,
                      decoration: InputDecoration(
                        hintText: 'Search transactions...',
                        hintStyle: TextStyle(color: Colors.black.withOpacity(0.2)),
                        border: InputBorder.none,
                        icon: const Icon(Icons.search_rounded, color: AppTheme.accentAmber),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filter Pills
                  Row(
                    children: [
                      _buildFilterPill('All'),
                      const SizedBox(width: 8),
                      _buildFilterPill('In'),
                      const SizedBox(width: 8),
                      _buildFilterPill('Out'),
                    ],
                  ),
                ],
              ),
            ),

            // Transactions List
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: _filteredTransactions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        itemCount: _filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final tx = _filteredTransactions[index];
                          final isNegative = tx['amount'] < 0;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.black.withOpacity(0.04)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (tx['color'] as Color).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(tx['icon'], color: tx['color'], size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx['title'],
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(tx['date'], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isNegative ? '-' : '+'} ₱${NumberFormat('#,##0.00').format((tx['amount'] as num).abs())}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: isNegative ? AppTheme.textPrimary : Colors.green[700],
                                  ),
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
      ),
    );
  }

  Widget _buildFilterPill(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = label);
        _applyFilters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentAmber : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.accentAmber : Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF101838) : Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off_rounded, size: 80, color: Colors.black.withOpacity(0.1)),
        const SizedBox(height: 16),
        const Text('No transactions found', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
