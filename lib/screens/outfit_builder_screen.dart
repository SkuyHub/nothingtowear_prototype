import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Outfit canvas. Used for:
///  - Manual arrangement (Method 1) and editing a saved outfit
///  - Reviewing/tweaking AI results (Method 2 and 3) before saving
/// Positions are stored as fractions of the canvas (see OutfitItem).
class OutfitBuilderScreen extends StatefulWidget {
  const OutfitBuilderScreen({
    super.key,
    this.existing,
    this.initialLayout,
    this.method = 'Manual',
    this.initialMood,
    this.title,
  });

  final Outfit? existing;
  final List<OutfitItem>? initialLayout;
  final String method; // Manual, Key Item AI, Full AI Builder
  final String? initialMood;
  final String? title;

  @override
  State<OutfitBuilderScreen> createState() => _OutfitBuilderScreenState();
}

class _OutfitBuilderScreenState extends State<OutfitBuilderScreen> {
  late List<OutfitItem> _layout;
  int? _selected; // item id
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    if (widget.existing != null) {
      _layout = app.outfitItems(widget.existing!.id).map((e) => e.copy()).toList();
    } else {
      _layout = (widget.initialLayout ?? const <OutfitItem>[]).map((e) => e.copy()).toList();
    }
  }

  OutfitItem? get _sel {
    for (final o in _layout) {
      if (o.itemId == _selected) return o;
    }
    return null;
  }

  int get _maxZ => _layout.isEmpty
      ? 0
      : _layout.map((e) => e.zIndex).reduce((a, b) => a > b ? a : b);
  int get _minZ => _layout.isEmpty
      ? 0
      : _layout.map((e) => e.zIndex).reduce((a, b) => a < b ? a : b);

  void _toggleItem(ClothingItem item) {
    setState(() {
      final idx = _layout.indexWhere((o) => o.itemId == item.id);
      if (idx >= 0) {
        _layout.removeAt(idx);
        if (_selected == item.id) _selected = null;
      } else {
        _layout.add(OutfitItem(
          outfitId: widget.existing?.id ?? 0,
          itemId: item.id,
          zIndex: _maxZ + 1,
        ));
        _selected = item.id;
      }
    });
  }

  Future<void> _save() async {
    if (_layout.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one piece first')),
      );
      return;
    }
    final app = context.read<AppState>();
    final nameC = TextEditingController(text: widget.existing?.nama ?? '');
    final moodC = TextEditingController(
      text: widget.existing?.moodEvent ?? widget.initialMood ?? '',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save outfit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameC,
              decoration: const InputDecoration(labelText: 'Outfit name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: moodC,
              decoration: const InputDecoration(labelText: 'Mood / event'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final name = nameC.text.trim().isEmpty ? 'Untitled outfit' : nameC.text.trim();
    final mood = moodC.text.trim().isEmpty ? null : moodC.text.trim();
    app.saveOutfit(
      existing: widget.existing,
      nama: name,
      mood: mood,
      method: widget.existing?.metodePembuatan ?? widget.method,
      layout: _layout,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved "$name"')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final sel = _sel;
    final sorted = [..._layout]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    final title = widget.title ?? (widget.existing?.nama ?? 'New outfit');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        physics: _dragging ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 0.85,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                color: AppColors.tile,
                child: LayoutBuilder(builder: (context, box) {
                  final w = box.maxWidth;
                  final h = box.maxHeight;
                  return Stack(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(() => _selected = null),
                        child: SizedBox(width: w, height: h),
                      ),
                      if (sorted.isEmpty)
                        const Center(
                          child: Text(
                            'Tap pieces below to add them',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      for (final oi in sorted) _canvasItem(app, oi, w, h),
                    ],
                  );
                }),
              ),
            ),
          ),
          if (sel != null) ...[
            const SizedBox(height: 12),
            _controls(sel),
          ],
          const SectionHeader('Your pieces'),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: app.items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final item = app.items[i];
                final inLayout = _layout.any((o) => o.itemId == item.id);
                return GestureDetector(
                  onTap: () => _toggleItem(item),
                  child: Container(
                    width: 80,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: inLayout ? AppColors.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: GarmentArt(
                            warna: item.warna,
                            categoryName: app.categoryName(item.categoryId),
                          ),
                        ),
                        if (inLayout)
                          const Positioned(
                            right: 0,
                            top: 0,
                            child: CircleAvatar(
                              radius: 9,
                              backgroundColor: AppColors.accent,
                              child: Icon(Icons.check, size: 12, color: kOnAccent),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _canvasItem(AppState app, OutfitItem oi, double w, double h) {
    final item = app.itemById(oi.itemId);
    if (item == null) return const SizedBox.shrink();
    final s = canvasItemSize(w, h, oi.scale);
    final selected = oi.itemId == _selected;
    return Positioned(
      left: oi.posX * w - s / 2,
      top: oi.posY * h - s / 2,
      width: s,
      height: s,
      child: GestureDetector(
        onTap: () => setState(() => _selected = oi.itemId),
        onPanStart: (_) => setState(() {
          _selected = oi.itemId;
          _dragging = true;
        }),
        onPanUpdate: (d) => setState(() {
          oi.posX = (oi.posX + d.delta.dx / w).clamp(0.05, 0.95).toDouble();
          oi.posY = (oi.posY + d.delta.dy / h).clamp(0.05, 0.95).toDouble();
        }),
        onPanEnd: (_) => setState(() => _dragging = false),
        onPanCancel: () => setState(() => _dragging = false),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(s * 0.14),
            border: Border.all(
              color: selected ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: GarmentArt(
            warna: item.warna,
            categoryName: app.categoryName(item.categoryId),
          ),
        ),
      ),
    );
  }

  Widget _controls(OutfitItem sel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.zoom_in, size: 18, color: AppColors.muted),
          Expanded(
            child: Slider(
              value: sel.scale.clamp(0.5, 2.0).toDouble(),
              min: 0.5,
              max: 2.0,
              onChanged: (v) => setState(() => sel.scale = v),
            ),
          ),
          IconButton(
            tooltip: 'Bring to front',
            icon: const Icon(Icons.flip_to_front, size: 20),
            onPressed: () => setState(() => sel.zIndex = _maxZ + 1),
          ),
          IconButton(
            tooltip: 'Send to back',
            icon: const Icon(Icons.flip_to_back, size: 20),
            onPressed: () => setState(() => sel.zIndex = _minZ - 1),
          ),
          IconButton(
            tooltip: 'Key item',
            icon: Icon(
              sel.isKeyItem ? Icons.star : Icons.star_border,
              size: 20,
              color: sel.isKeyItem ? AppColors.accent : null,
            ),
            onPressed: () => setState(() => sel.isKeyItem = !sel.isKeyItem),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => setState(() {
              _layout.removeWhere((o) => o.itemId == sel.itemId);
              _selected = null;
            }),
          ),
        ],
      ),
    );
  }
}
