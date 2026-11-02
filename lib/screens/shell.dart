import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import 'add_item_screen.dart';
import 'home_screen.dart';
import 'items_screen.dart';
import 'outfit_builder_screen.dart';
import 'outfit_screen.dart';
import 'schedule_tab.dart';
import 'stylist_screen.dart';

/// Selected bottom-nav tab. 0 Home, 1 Items, 2 Outfit, 3 Stylist.
final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: ValueListenableBuilder<int>(
        valueListenable: tabIndex,
        builder: (context, i, _) => IndexedStack(
          index: i,
          children: const [
            HomeScreen(),
            ItemsScreen(),
            OutfitScreen(),
            StylistScreen(),
          ],
        ),
      ),
      bottomNavigationBar: const _NavBar(),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        height: 66,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(33),
          border: Border.all(color: AppColors.chip),
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: tabIndex,
          builder: (context, current, _) => Row(
            children: [
              _item(Icons.home_outlined, 'Home', 0, current),
              _item(Icons.checkroom, 'Items', 1, current),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () => _showCreateMenu(context),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, size: 32, color: kOnAccent),
                    ),
                  ),
                ),
              ),
              _item(Icons.accessibility_new, 'Outfit', 2, current),
              _item(Icons.auto_awesome, 'Stylist', 3, current),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, int index, int current) {
    final selected = index == current;
    final color = selected ? AppColors.accent : AppColors.accent.withValues(alpha: 0.55);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => tabIndex.value = index,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_a_photo_outlined),
              title: const Text('Add clothing item'),
              onTap: () {
                Navigator.pop(sheetContext);
                pushScreen(context, const AddItemScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_customize_outlined),
              title: const Text('Create outfit'),
              onTap: () {
                Navigator.pop(sheetContext);
                pushScreen(context, const OutfitBuilderScreen());
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_available_outlined),
              title: const Text('Schedule an outfit'),
              onTap: () {
                Navigator.pop(sheetContext);
                pushScreen(context, AddScheduleScreen(initialDate: DateTime.now()));
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
