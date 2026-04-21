import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../ticket/ticket_detail_screen.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final notifications = provider.userNotifications;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          if (notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: provider.markAllRead,
              child: Text(
                'Tandai Semua',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              message: 'Tidak ada notifikasi',
              icon: Icons.notifications_none_rounded,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (_, i) {
                final n = notifications[i];
                return _NotificationItem(
                  notification: n,
                  isDark: isDark,
                  onTap: () {
                    provider.markNotificationRead(n.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TicketDetailScreen(ticketId: n.ticketId),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final notification;
  final bool isDark;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.isDark,
    required this.onTap,
  });

  IconData _icon() {
    switch (notification.type) {
      case 'status_update': return Icons.update_rounded;
      case 'new_comment': return Icons.chat_bubble_outline_rounded;
      case 'assigned': return Icons.person_add_rounded;
      case 'resolved': return Icons.check_circle_outline_rounded;
      default: return Icons.notifications_outlined;
    }
  }

  Color _iconColor() {
    switch (notification.type) {
      case 'status_update': return AppTheme.accentAmber;
      case 'new_comment': return AppTheme.primaryBlue;
      case 'assigned': return AppTheme.purpleAccent;
      case 'resolved': return AppTheme.successGreen;
      default: return AppTheme.accentCyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? (isDark
                  ? AppTheme.primaryBlue.withOpacity(0.12)
                  : AppTheme.primaryBlue.withOpacity(0.05))
              : (isDark ? AppTheme.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: isUnread
              ? Border.all(color: AppTheme.primaryBlue.withOpacity(0.25), width: 1.5)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _iconColor().withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon(), color: _iconColor(), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(notification.createdAt),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
