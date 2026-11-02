import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/item_widgets.dart';
import '../widgets/page_header.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  static const _sortOptions = ['Recently Added', 'Name A-Z', 'Favorites'];

  String _query = '';
  int? _categoryId;
  String? _style;
  String? _color;
  bool _favOnly = false;
  String _sort = _sortOptions.first;

  List<ClothingItem> _filtered(AppState app) {
    final list = app.items.where((i) {
      if (_categoryId != null && i.categoryId != _categoryId) return false;
      if (_style != null && i.styleOccasion != _style) return false;
      if (_favOnly && !i.isFavorite) return false;
      if (_color != null && i.warna != _color) return false;
      if (_query.isNotEmpty) {
        final hay =
            '${i.namaItem} ${i.brand ?? ''} ${i.tag ?? ''} ${i.warna ?? ''}'.toLowerCase();
        if (!hay.contains(_query.toLowerCase())) return false;
      }
      return true;
    }).toList();
    if (_sort == 'Name A-Z') {
      list.sort((a, b) => a.namaItem.compareTo(b.namaItem));
    } else if (_sort == 'Favorites') {
      list.sort((a, b) => (b.isFavorite ? 1 : 0) - (a.isFavorite ? 1 : 0));
    }
    return list;
  }

  void _openFilters(AppState app) {
    final colors = app.items.map((i) => i.warna).whereType<String>().toSet().toList()..sort();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filter by attribute',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Favourites only'),
                  value: _favOnly,
                  onChanged: (v) {
                    setState(() => _favOnly = v);
                    setSheet(() {});
                  },
                ),
                const Text('Colour', style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in colors)
                      ChoiceChip(
                        label: Text(c),
                        avatar: CircleAvatar(backgroundColor: garmentColor(c), radius: 8),
                        selected: _color == c,
                        onSelected: (sel) {
                          setState(() => _color = sel ? c : null);
                          setSheet(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _favOnly = false;
                      _color = null;
                    });
                    setSheet(() {});
                  },
                  child: const Text('Reset filters'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final all = app.items;
    final shown = _filtered(app);
    final hasFilter = _favOnly || _color != null;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          const PageHeader(title: 'Items'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search ${all.length} Pieces',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _openFilters(app),
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: hasFilter ? AppColors.accent : AppColors.accent.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune, color: kOnAccent),
                  ),
                ),
              ],
            ),
          ),
          SectionHeader(
            'Collections',
            onSeeAll: () => setState(() => _categoryId = null),
          ),
          SizedBox(
            height: 104,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _collection('All', all.length, Icons.apps, _categoryId == null,
                    () => setState(() => _categoryId = null)),
                for (final c in app.categories)
                  _collection(
                    c.namaKategori,
                    all.where((i) => i.categoryId == c.id).length,
                    categoryIcon(c.namaKategori),
                    _categoryId == c.id,
                    () => setState(() => _categoryId = c.id),
                  ),
              ],
            ),
          ),
          SectionHeader(
            'Saved Pieces',
            trailing: SortMenu(
              value: _sort,
              options: _sortOptions,
              onChanged: (v) => setState(() => _sort = v),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                FilterPill(
                  label: 'All (${all.length})',
                  selected: _style == null,
                  onTap: () => setState(() => _style = null),
                ),
                for (final s in app.styles)
                  FilterPill(
                    label: s,
                    selected: _style == s,
                    onTap: () => setState(() => _style = s),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (shown.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyState(
                icon: Icons.search_off,
                message: 'No pieces match. Try another search or filter.',
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.74,
              ),
              itemCount: shown.length,
              itemBuilder: (_, i) => ItemCard(item: shown[i]),
            ),
        ],
      ),
    );
  }

  Widget _collection(
    String label,
    int count,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.accent : AppColors.surfaceHigh,
              ),
              child: Icon(icon, color: selected ? kOnAccent : AppColors.muted),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: selected ? AppColors.text : AppColors.muted,
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                color: selected ? AppColors.text : AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
