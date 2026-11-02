import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';

const Map<String, Color> garmentColors = {
  'White': Color(0xFFF2EFEA),
  'Cream': Color(0xFFE8DCC4),
  'Beige': Color(0xFFCDB79E),
  'Tan': Color(0xFFB98A5B),
  'Brown': Color(0xFF6B4A3A),
  'Rust': Color(0xFFA5472B),
  'Burgundy': Color(0xFF6D1F2E),
  'Black': Color(0xFF1E1E22),
  'Charcoal': Color(0xFF3C3F46),
  'Grey': Color(0xFF8A8D94),
  'Navy': Color(0xFF1F2D4F),
  'Light Blue': Color(0xFF9FC3E0),
  'Olive': Color(0xFF6B6B3A),
  'Khaki': Color(0xFFB5A877),
  'Gold': Color(0xFFD4AF37),
};

const List<String> styleOptions = [
  'Casual',
  'Formal & Evening',
  'Street Fashion',
  'Sport',
];

Color garmentColor(String? name) => garmentColors[name] ?? const Color(0xFF8A8D94);

IconData categoryIcon(String category) {
  switch (category) {
    case 'Tops':
      return Icons.checkroom;
    case 'Bottoms':
      return Icons.straighten;
    case 'Outerwear':
      return Icons.dry_cleaning;
    case 'Footwear':
      return Icons.hiking;
    case 'Accessories':
      return Icons.watch_outlined;
    default:
      return Icons.style;
  }
}

/// Side length of an item tile on an outfit canvas.
double canvasItemSize(double w, double h, double scale) =>
    min(w * 0.36, h * 0.31) * scale;

/// Stand-in for a garment photo (the demo has no image assets).
class GarmentArt extends StatelessWidget {
  const GarmentArt({
    super.key,
    required this.warna,
    required this.categoryName,
    this.plain = false,
  });

  final String? warna;
  final String categoryName;
  final bool plain; // true = "cut out" look, glyph only

  @override
  Widget build(BuildContext context) {
    final base = garmentColor(warna);
    return LayoutBuilder(builder: (context, box) {
      final side = box.biggest.shortestSide;
      final s = side.isFinite ? side : 80.0;
      if (plain) {
        return Center(
          child: Icon(categoryIcon(categoryName), size: s * 0.75, color: base),
        );
      }
      final light = base.computeLuminance() > 0.5;
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(s * 0.14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [base, Color.lerp(base, Colors.black, 0.35)!],
          ),
        ),
        child: Center(
          child: Icon(
            categoryIcon(categoryName),
            size: s * 0.5,
            color: light ? Colors.black54 : Colors.white70,
          ),
        ),
      );
    });
  }
}

/// Read-only flat-lay of an outfit's items.
class OutfitPreview extends StatelessWidget {
  const OutfitPreview({super.key, required this.layout, this.radius = 16});

  final List<OutfitItem> layout;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final sorted = [...layout]..sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        color: AppColors.tile,
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          return Stack(
            children: [
              for (final oi in sorted) _placed(app, oi, w, h),
            ],
          );
        }),
      ),
    );
  }

  Widget _placed(AppState app, OutfitItem oi, double w, double h) {
    final item = app.itemById(oi.itemId);
    if (item == null) return const SizedBox.shrink();
    final s = canvasItemSize(w, h, oi.scale);
    return Positioned(
      left: oi.posX * w - s / 2,
      top: oi.posY * h - s / 2,
      width: s,
      height: s,
      child: GarmentArt(
        warna: item.warna,
        categoryName: app.categoryName(item.categoryId),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.onSeeAll, this.trailing});

  final String title;
  final VoidCallback? onSeeAll;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          if (trailing != null) trailing!,
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [Text('See All'), Icon(Icons.chevron_right, size: 18)],
              ),
            ),
        ],
      ),
    );
  }
}

class SortMenu extends StatelessWidget {
  const SortMenu({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (_) => [
        for (final o in options) PopupMenuItem<String>(value: o, child: Text(o)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.chip,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_vert, size: 14),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontSize: 11)),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }
}

class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.chip : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? AppColors.text : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 18});

  final AppUser? user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final name = user?.nama ?? '';
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.accent,
      child: Text(
        name.isEmpty ? '?' : name[0].toUpperCase(),
        style: TextStyle(
          color: kOnAccent,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.9,
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.muted),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class SmallChip extends StatelessWidget {
  const SmallChip(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color ?? Colors.black54,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10)),
    );
  }
}

void pushScreen(BuildContext context, Widget screen) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
}
