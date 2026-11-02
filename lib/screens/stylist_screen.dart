import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/page_header.dart';
import 'ai_taxonomy_screen.dart';
import 'ootd_curator_screen.dart';
import 'stylist_chat_screen.dart';

/// Personal Stylist tab: Studio Visual Canvas on top, feature cards below.
class StylistScreen extends StatefulWidget {
  const StylistScreen({super.key});

  @override
  State<StylistScreen> createState() => _StylistScreenState();
}

class _StylistScreenState extends State<StylistScreen> {
  int? _itemId;
  double _brightness = 0; // -0.3 .. 0.3
  bool _grayscale = false;
  bool _flip = false;
  bool _cutout = false;
  bool _layerVisible = true;
  bool _aiBusy = false;
  List<String> _aiTags = [];

  void _reset() => setState(() {
        _brightness = 0;
        _grayscale = false;
        _flip = false;
        _cutout = false;
        _layerVisible = true;
        _aiTags = [];
      });

  ColorFilter get _filter {
    final b = _brightness * 255;
    if (_grayscale) {
      return ColorFilter.matrix([
        0.2126, 0.7152, 0.0722, 0, b, //
        0.2126, 0.7152, 0.0722, 0, b,
        0.2126, 0.7152, 0.0722, 0, b,
        0, 0, 0, 1, 0,
      ]);
    }
    return ColorFilter.matrix([
      1, 0, 0, 0, b, //
      0, 1, 0, 0, b,
      0, 0, 1, 0, b,
      0, 0, 0, 1, 0,
    ]);
  }

  void _pickImage() {
    final app = context.read<AppState>();
    final items = app.items;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'Pick a piece for the canvas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final it = items[i];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _itemId = it.id;
                          _aiTags = [];
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.tile,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: GarmentArt(
                          warna: it.warna,
                          categoryName: app.categoryName(it.categoryId),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFilters() {
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
                const Text('Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                const Text('Brightness', style: TextStyle(color: AppColors.muted)),
                Slider(
                  value: _brightness,
                  min: -0.3,
                  max: 0.3,
                  onChanged: (v) {
                    setState(() => _brightness = v);
                    setSheet(() {});
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Black & white'),
                  value: _grayscale,
                  onChanged: (v) {
                    setState(() => _grayscale = v);
                    setSheet(() {});
                  },
                ),
                TextButton(
                  onPressed: () {
                    _reset();
                    setSheet(() {});
                  },
                  child: const Text('Reset all'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openLayers(ClothingItem? item) {
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
                const Text('Layers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                if (item == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No layers yet. Pick a piece first.',
                        style: TextStyle(color: AppColors.muted)),
                  )
                else
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.namaItem),
                    subtitle: const Text('Layer 1'),
                    value: _layerVisible,
                    onChanged: (v) {
                      setState(() => _layerVisible = v);
                      setSheet(() {});
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _runAiLab(AppState app) async {
    final id = _itemId;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a piece first')),
      );
      return;
    }
    setState(() => _aiBusy = true);
    final tags = await app.runTaxonomy(id);
    if (!mounted) return;
    setState(() {
      _aiBusy = false;
      _aiTags = tags;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final item = _itemId == null ? null : app.itemById(_itemId!);
    final cat = item == null ? '' : app.categoryName(item.categoryId);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          const PageHeader(title: 'Personal Stylist'),
          Container(
            height: 320,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2A0A45), Color(0xFF1A0530)],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: item == null ? _pickImage : null,
                    child: Center(
                      child: item == null
                          ? const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.camera_alt_outlined, size: 56, color: AppColors.text),
                                SizedBox(height: 8),
                                Text('Your Pictures Here', style: TextStyle(fontSize: 12)),
                                Text('Tap to pick from your wardrobe',
                                    style: TextStyle(fontSize: 11, color: AppColors.muted)),
                              ],
                            )
                          : _layerVisible
                              ? Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.diagonal3Values(_flip ? -1 : 1, 1, 1),
                                  child: ColorFiltered(
                                    colorFilter: _filter,
                                    child: SizedBox(
                                      width: 190,
                                      height: 190,
                                      child: GarmentArt(
                                        warna: item.warna,
                                        categoryName: cat,
                                        plain: _cutout,
                                      ),
                                    ),
                                  ),
                                )
                              : const Text('Layer hidden',
                                  style: TextStyle(color: AppColors.muted)),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  top: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        tooltip: 'Layers',
                        icon: const Icon(Icons.layers_outlined),
                        onPressed: () => _openLayers(item),
                      ),
                      IconButton(
                        tooltip: 'Filters',
                        icon: const Icon(Icons.tune),
                        onPressed: _openFilters,
                      ),
                      IconButton(
                        tooltip: 'Reset',
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          _reset();
                          setState(() => _itemId = null);
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Edit (mirror)',
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: item == null ? null : () => setState(() => _flip = !_flip),
                        ),
                        IconButton(
                          tooltip: 'AI Lab',
                          icon: _aiBusy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.science_outlined, size: 20),
                          onPressed: _aiBusy ? null : () => _runAiLab(app),
                        ),
                        IconButton(
                          tooltip: 'Cutout',
                          icon: Icon(
                            Icons.content_cut,
                            size: 20,
                            color: _cutout ? AppColors.accent : null,
                          ),
                          onPressed: item == null ? null : () => setState(() => _cutout = !_cutout),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_aiTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  const Text('AI tags:', style: TextStyle(color: AppColors.muted)),
                  for (final t in _aiTags) SmallChip('#$t', color: AppColors.chip),
                ],
              ),
            ),
          const SectionHeader('Stylist Features'),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.45,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _FeatureCard(
                icon: Icons.auto_awesome,
                title: 'AI Taxonomy',
                subtitle: 'Figure out your clothing\'s style with just one click',
                onTap: () => pushScreen(context, const AiTaxonomyScreen()),
              ),
              _FeatureCard(
                icon: Icons.psychology_outlined,
                title: 'OOTD Curator',
                subtitle: 'Have our AI stylist curate your outfit of the day',
                onTap: () => pushScreen(context, const OotdCuratorScreen()),
              ),
              _FeatureCard(
                icon: Icons.palette_outlined,
                title: 'Palette Picker',
                subtitle: 'Color match your clothes to craft the perfect outfit',
                onTap: () => _notBuilt('Palette Picker'),
              ),
              _FeatureCard(
                icon: Icons.person_search_outlined,
                title: 'Digital TryOn',
                subtitle: 'See how an outfit would look on you',
                onTap: () => _notBuilt('Digital TryOn'),
              ),
            ],
          ),
          const StylistChatCard(),
        ],
      ),
    );
  }

  void _notBuilt(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name has no screen in the prototype yet')),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.chip,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
