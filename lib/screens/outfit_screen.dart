import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/page_header.dart';
import 'outfit_builder_screen.dart';
import 'packing_tab.dart';
import 'schedule_tab.dart';

class OutfitScreen extends StatefulWidget {
  const OutfitScreen({super.key});

  @override
  State<OutfitScreen> createState() => _OutfitScreenState();
}

class _OutfitScreenState extends State<OutfitScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const PageHeader(title: 'Outfit', showCalendar: false),
          _Segments(index: _tab, onChanged: (i) => setState(() => _tab = i)),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [
                _OutfitTab(),
                PackingTab(),
                ScheduleTab(bottomPadding: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['OUTFIT', 'PACKING', 'SCHEDULE'];
    const icons = [Icons.accessibility_new, Icons.luggage_outlined, Icons.event_outlined];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: i == index ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icons[i],
                          size: 14, color: i == index ? kOnAccent : AppColors.muted),
                      const SizedBox(width: 6),
                      Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: i == index ? kOnAccent : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _OutfitTab extends StatefulWidget {
  const _OutfitTab();

  @override
  State<_OutfitTab> createState() => _OutfitTabState();
}

class _OutfitTabState extends State<_OutfitTab> {
  static const _sortOptions = ['Recently Added', 'Favorites', 'Name A-Z'];
  String _sort = _sortOptions.first;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = [...app.outfits];
    if (_sort == 'Favorites') {
      list.sort((a, b) => (b.isFavorite ? 1 : 0) - (a.isFavorite ? 1 : 0));
    } else if (_sort == 'Name A-Z') {
      list.sort((a, b) => a.nama.compareTo(b.nama));
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        SectionHeader(
          'Curated Outfits',
          trailing: SortMenu(
            value: _sort,
            options: _sortOptions,
            onChanged: (v) => setState(() => _sort = v),
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.72,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            for (final o in list) _OutfitCard(outfit: o),
            const _AddOutfitCard(),
          ],
        ),
      ],
    );
  }
}

class _OutfitCard extends StatelessWidget {
  const _OutfitCard({required this.outfit});

  final Outfit outfit;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return GestureDetector(
      onTap: () => pushScreen(context, OutfitBuilderScreen(existing: outfit)),
      onLongPress: () async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete outfit?'),
            content: Text('"${outfit.nama}" and its scheduled entries will be removed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (ok == true) app.deleteOutfit(outfit.id);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(18),
              ),
              child: OutfitPreview(layout: app.outfitItems(outfit.id)),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  outfit.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              GestureDetector(
                onTap: () => app.toggleOutfitFavorite(outfit.id),
                child: Icon(
                  outfit.isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 18,
                  color: outfit.isFavorite ? AppColors.accent : AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddOutfitCard extends StatelessWidget {
  const _AddOutfitCard();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => pushScreen(context, const OutfitBuilderScreen()),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.accent,
              child: Icon(Icons.add, color: kOnAccent, size: 28),
            ),
            SizedBox(height: 10),
            Text('Add New Outfits', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
