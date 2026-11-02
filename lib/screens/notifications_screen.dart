import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _icon(String type) {
    switch (type) {
      case 'OOTD Reminder':
        return Icons.event_available_outlined;
      case 'Weather Alert':
        return Icons.cloud_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = app.notifications;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: app.unreadCount == 0 ? null : app.markAllRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: list.isEmpty
          ? const EmptyState(icon: Icons.notifications_off_outlined, message: 'Nothing here yet.')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (_, i) {
                final n = list[i];
                return GestureDetector(
                  onTap: () => app.markRead(n.id),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: n.isRead ? AppColors.surface : AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_icon(n.tipeNotifikasi), color: AppColors.accent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.judul,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n.pesan,
                                style: const TextStyle(fontSize: 13, color: AppColors.muted),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                DateFormat('d MMM, HH:mm').format(n.createdAt),
                                style: const TextStyle(fontSize: 11, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        if (!n.isRead)
                          const CircleAvatar(radius: 4, backgroundColor: AppColors.accent),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
