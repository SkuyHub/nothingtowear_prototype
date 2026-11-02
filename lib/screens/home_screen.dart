import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/item_widgets.dart';
import '../widgets/page_header.dart';
import 'shell.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final first = (app.currentUser?.nama ?? 'there').split(' ').first;
    final recent = app.items.take(8).toList();
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          PageHeader(title: 'Hello, $first'),
          const _DailyRecommendation(),
          SectionHeader('Recent Items', onSeeAll: () => tabIndex.value = 1),
          SizedBox(
            height: 150,
            child: recent.isEmpty
                ? const EmptyState(
                    icon: Icons.checkroom,
                    message: 'No items yet. Tap + to add your first piece.',
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: recent.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) => _RecentTile(item: recent[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.item});

  final ClothingItem item;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return GestureDetector(
      onTap: () => showItemDetail(context, item),
      child: SizedBox(
        width: 100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  color: AppColors.tile,
                  padding: const EdgeInsets.all(12),
                  child: GarmentArt(
                    warna: item.warna,
                    categoryName: app.categoryName(item.categoryId),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.namaItem,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyRecommendation extends StatelessWidget {
  const _DailyRecommendation();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final rec = app.todaysRecommendation;
    if (rec == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const EmptyState(
          icon: Icons.auto_awesome,
          message: 'Your daily recommendation appears here once you have a few pieces.',
        ),
      );
    }
    final outfit = app.outfitById(rec.outfitId);
    final layout = app.outfitItems(rec.outfitId);
    var names = layout
        .where((e) => e.isKeyItem)
        .map((e) => app.itemById(e.itemId)?.namaItem)
        .whereType<String>()
        .toList();
    if (names.isEmpty) {
      names = layout
          .map((e) => app.itemById(e.itemId)?.namaItem)
          .whereType<String>()
          .toList();
    }
    names = names.take(2).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(radius: 4, backgroundColor: AppColors.accent),
              SizedBox(width: 8),
              Text(
                'DAILY RECOMMENDATION',
                style: TextStyle(fontSize: 10, letterSpacing: 1, color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rec.judulRekomendasi,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          if (rec.deskripsiKonteks != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                rec.deskripsiKonteks!,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            height: 240,
            child: Stack(
              children: [
                Positioned.fill(child: OutfitPreview(layout: layout)),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [for (final n in names) SmallChip(n)],
                  ),
                ),
                if (rec.tagCuaca != null)
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: SmallChip(rec.tagCuaca!),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    if (!rec.isSaved) {
                      app.toggleRecommendationSaved(rec.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to your collection')),
                      );
                    }
                  },
                  icon: Icon(rec.isSaved ? Icons.check_circle : Icons.check_circle_outline),
                  label: Text(rec.isSaved ? 'In Collection' : 'Add to Collection'),
                ),
              ),
              IconButton(
                tooltip: 'Favourite',
                onPressed: outfit == null ? null : () => app.toggleOutfitFavorite(outfit.id),
                icon: Icon(
                  (outfit?.isFavorite ?? false) ? Icons.favorite : Icons.favorite_border,
                  color: (outfit?.isFavorite ?? false) ? AppColors.accent : AppColors.muted,
                ),
              ),
              IconButton(
                tooltip: 'Bookmark',
                onPressed: () => app.toggleRecommendationSaved(rec.id),
                icon: Icon(
                  rec.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: rec.isSaved ? AppColors.accent : AppColors.muted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
