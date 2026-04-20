import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock notifications for a GCash-style experience
    final List<Map<String, dynamic>> notifications = [
      {
        'title': 'You have received money!',
        'message': 'Juan Dela Cruz sent you ₱500.00. Your new balance is ₱12,950.00',
        'time': 'Just now',
        'icon': Icons.arrow_downward_rounded,
        'color': Colors.green,
        'isUnread': true,
      },
      {
        'title': 'Security Alert: New Login',
        'message': 'Your account was accessed from a new Windows device.',
        'time': '2 hours ago',
        'icon': Icons.security_rounded,
        'color': Colors.orange,
        'isUnread': true,
      },
      {
        'title': 'Promo: 50% Cashback!',
        'message': 'Scan to pay at partner merchants this weekend and get up to ₱200 cashback.',
        'time': 'Yesterday',
        'icon': Icons.local_offer_rounded,
        'color': AppTheme.primaryBlue,
        'isUnread': false,
      },
      {
        'title': 'Bill Payment Successful',
        'message': 'Your payment of ₱1,500.00 to Meralco was successfully posted.',
        'time': 'Apr 16, 2026',
        'icon': Icons.receipt_long_rounded,
        'color': Colors.blueGrey,
        'isUnread': false,
      },
      {
        'title': 'System Maintenance',
        'message': 'Scheduled maintenance on Saturday 2:00 AM to 4:00 AM. Services will be temporarily unavailable.',
        'time': 'Apr 14, 2026',
        'icon': Icons.build_rounded,
        'color': Colors.redAccent,
        'isUnread': false,
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Mark all as read',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read')),
              );
            },
          ),
        ],
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
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          itemCount: notifications.length,
          separatorBuilder: (context, index) => const Divider(height: 32, color: Colors.black12),
          itemBuilder: (context, index) {
            final notif = notifications[index];
            return _buildNotificationTile(notif);
          },
        ),
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> notif) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon Container
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (notif['color'] as Color).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(notif['icon'], color: notif['color'], size: 24),
        ),
        const SizedBox(width: 16),
        
        // Text Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      notif['title'],
                      style: TextStyle(
                        fontWeight: notif['isUnread'] ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (notif['isUnread'])
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    )
                ],
              ),
              const SizedBox(height: 6),
              Text(
                notif['message'],
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                notif['time'],
                style: const TextStyle(
                  color: Colors.black38,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
