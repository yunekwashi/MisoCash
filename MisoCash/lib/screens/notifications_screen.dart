import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/n8n_service.dart';
import '../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final user = AuthService().currentUser;
    if (user != null) {
      setState(() => _isLoading = true);
      final liveNotifs = await N8nService.fetchNotifications(user.mobileNumber);
      if (mounted) {
        setState(() {
          _notifications = liveNotifs;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _buildTab('All', _notifications.length),
              _buildTab('Finance', _notifications.where((n) => n['category'] == 'Finance').length),
              _buildTab('Security', _notifications.where((n) => n['category'] == 'Security').length),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadNotifications,
          child: Container(
            margin: const EdgeInsets.only(top: 16),
            decoration: const BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
            ),
            child: _isLoading && _notifications.isEmpty
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : TabBarView(
                    children: [
                      _buildNotificationList(_notifications),
                      _buildNotificationList(_notifications.where((n) => n['category'] == 'Finance').toList()),
                      _buildNotificationList(_notifications.where((n) => n['category'] == 'Security').toList()),
                    ],
                  ),
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
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final notif = items[index];
        final isUnread = notif['is_read'] == 0 || notif['is_read'] == false;
        
        // Dynamic icons/colors based on category
        IconData icon = Icons.notifications_rounded;
        Color color = AppTheme.primaryBlue;
        
        switch (notif['category']?.toString().toLowerCase()) {
          case 'finance':
            icon = Icons.account_balance_wallet_rounded;
            color = Colors.green;
            break;
          case 'security':
            icon = Icons.shield_rounded;
            color = Colors.orange;
            break;
          case 'promo':
            icon = Icons.auto_awesome_rounded;
            color = AppTheme.accentAmber;
            break;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUnread ? AppTheme.surface : AppTheme.surface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: isUnread ? Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)) : null,
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text((notif['category'] ?? 'INFO').toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                      Text(notif['date'] != null ? notif['date'].toString().substring(0, 10) : 'Now', style: const TextStyle(fontSize: 10, color: Colors.black26, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(notif['title'] ?? 'Alert', style: TextStyle(fontWeight: isUnread ? FontWeight.bold : FontWeight.w600, fontSize: 16, color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(notif['message'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
                  ],
                ),
              ),
              if (isUnread)
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
