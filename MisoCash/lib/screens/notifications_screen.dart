import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> notifications = [
      {'title': 'Money Received!', 'message': 'Juan Dela Cruz sent you ₱500.00. Use it wisely!', 'time': '2m ago', 'icon': Icons.add_chart_rounded, 'color': Colors.green, 'isUnread': true, 'category': 'Finance'},
      {'title': 'Security Alert', 'message': 'New login detected on Windows 11 Chrome.', 'time': '1h ago', 'icon': Icons.shield_rounded, 'color': Colors.orange, 'isUnread': true, 'category': 'Security'},
      {'title': 'Weekend Promo', 'message': 'Get 20% cashback on all utility bills this Sunday.', 'time': '5h ago', 'icon': Icons.auto_awesome_rounded, 'color': AppTheme.primaryBlue, 'isUnread': false, 'category': 'Promo'},
      {'title': 'Bill Paid', 'message': 'Meralco bill ₱1,500.00 paid successfully.', 'time': 'Yesterday', 'icon': Icons.receipt_long_rounded, 'color': Colors.blueGrey, 'isUnread': false, 'category': 'Finance'},
    ];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelColor: Colors.white60,
            tabs: [
              _buildTab('All', notifications.length),
              _buildTab('Finance', 2),
              _buildTab('Security', 1),
            ],
          ),
        ),
        body: Container(
          margin: const EdgeInsets.only(top: 16),
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
          ),
          child: TabBarView(
            children: [
              _buildNotificationList(notifications),
              _buildNotificationList(notifications.where((n) => n['category'] == 'Finance').toList()),
              _buildNotificationList(notifications.where((n) => n['category'] == 'Security').toList()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int count) {
    return Tab(
      child: Row(
        children: [
          Text(label),
          const SizedBox(width: 8),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
              child: Text(count.toString(), style: const TextStyle(fontSize: 10)),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(opacity: 0.2, child: Icon(Icons.notifications_off_rounded, size: 80, color: AppTheme.textPrimary)),
            SizedBox(height: 16),
            Text('No notifications here yet', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final notif = items[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notif['isUnread'] ? AppTheme.surface : AppTheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: notif['isUnread'] ? Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)) : null,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (notif['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(notif['icon'], color: notif['color'], size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(notif['category'].toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                      Text(notif['time'], style: const TextStyle(fontSize: 10, color: Colors.black26, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(notif['title'], style: TextStyle(fontWeight: notif['isUnread'] ? FontWeight.bold : FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(notif['message'], style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
                  ],
                ),
              ),
              if (notif['isUnread'])
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
                ),
            ],
          ),
        );
      },
    );
  }
}
