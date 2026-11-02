import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../screens/notifications_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/schedule_tab.dart';
import 'common.dart';

/// Title row used on the four main tabs: calendar, bell with badge, avatar.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.showCalendar = true});

  final String title;
  final bool showCalendar;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final unread = app.unreadCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            ),
          ),
          if (showCalendar)
            IconButton(
              tooltip: 'OOTD calendar',
              icon: const Icon(Icons.calendar_today_outlined),
              onPressed: () => pushScreen(context, const ScheduleScreen()),
            ),
          IconButton(
            tooltip: 'Notifications',
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_none),
            ),
            onPressed: () => pushScreen(context, const NotificationsScreen()),
          ),
          GestureDetector(
            onTap: () => pushScreen(context, const ProfileScreen()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: UserAvatar(user: app.currentUser),
            ),
          ),
        ],
      ),
    );
  }
}
