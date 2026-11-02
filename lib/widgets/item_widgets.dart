import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import 'common.dart';

class ItemCard extends StatelessWidget {
  const ItemCard({super.key, required this.item});

  final ClothingItem item;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final cat = app.categoryName(item.categoryId);
    final label = (item.tags.isNotEmpty ? item.tags.first : cat).toUpperCase();
    return GestureDetector(
      onTap: () => showItemDetail(context, item),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: AppColors.tile,
                        padding: const EdgeInsets.all(16),
                        child: GarmentArt(warna: item.warna, categoryName: cat),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.chip,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 9, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: GestureDetector(
                      onTap: () => app.toggleItemFavorite(item.id),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          item.isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: item.isFavorite ? AppColors.accent : AppColors.text,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.namaItem,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              item.brand ?? cat,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

void showItemDetail(BuildContext context, ClothingItem item) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ItemDetailSheet(itemId: item.id),
  );
}

class _ItemDetailSheet extends StatelessWidget {
  const _ItemDetailSheet({required this.itemId});

  final int itemId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final item = app.itemById(itemId);
    if (item == null) return const SizedBox.shrink();
    final cat = app.categoryName(item.categoryId);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 200,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: AppColors.tile,
                  padding: const EdgeInsets.all(24),
                  child: GarmentArt(warna: item.warna, categoryName: cat),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.namaItem,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              [item.brand, item.ukuran].whereType<String>().join(' · '),
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _pill(cat),
                if (item.warna != null) _pill(item.warna!),
                if (item.styleOccasion != null) _pill(item.styleOccasion!),
                for (final t in item.tags) _pill('#$t'),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => app.toggleItemFavorite(item.id),
              icon: Icon(item.isFavorite ? Icons.favorite : Icons.favorite_border),
              label: Text(item.isFavorite ? 'Remove from favourites' : 'Add to favourites'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.chip,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      );
}
