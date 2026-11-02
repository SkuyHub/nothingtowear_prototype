import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'outfit_builder_screen.dart';

/// OOTD Curator with the three methods from the sitemap:
/// 0 = arrange manually on the canvas
/// 1 = pick one key item and let AI complete the outfit
/// 2 = full AI builder from a mood/event and location
class OotdCuratorScreen extends StatefulWidget {
  const OotdCuratorScreen({super.key, this.initialMethod = 0});

  final int initialMethod;

  @override
  State<OotdCuratorScreen> createState() => _OotdCuratorScreenState();
}

class _OotdCuratorScreenState extends State<OotdCuratorScreen> {
  late int _method;
  int? _keyItemId;
  final _mood = TextEditingController();
  late final TextEditingController _location;
  bool _busy = false;

  static const _titles = ['Manual', 'Key Item', 'Full AI'];
  static const _blurbs = [
    'Arrange your own pieces on the canvas.',
    'Choose one hero piece and AI completes the look.',
    'Tell AI the mood and place. It builds the whole outfit.',
  ];

  @override
  void initState() {
    super.initState();
    _method = widget.initialMethod;
    _location = TextEditingController(
      text: context.read<AppState>().currentUser?.lokasiDefault ?? '',
    );
  }

  @override
  void dispose() {
    _mood.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final app = context.read<AppState>();
    if (_method == 0) {
      pushScreen(context, const OutfitBuilderScreen());
      return;
    }
    if (_method == 1 && _keyItemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a key item first')),
      );
      return;
    }
    if (app.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some pieces first')),
      );
      return;
    }
    setState(() => _busy = true);
    final layout = await app.curateOutfit(
      keyItemId: _method == 1 ? _keyItemId : null,
      mood: _mood.text,
      location: _method == 2 ? _location.text : null,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    pushScreen(
      context,
      OutfitBuilderScreen(
        initialLayout: layout,
        method: _method == 1 ? 'Key Item AI' : 'Full AI Builder',
        initialMood: _mood.text.trim().isEmpty ? null : _mood.text.trim(),
        title: 'AI suggestion',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = app.items;
    return Scaffold(
      appBar: AppBar(title: const Text('OOTD Curator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 2 ? 0 : 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _method = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _method == i ? AppColors.accent : AppColors.surfaceHigh,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Method ${i + 1}',
                              style: TextStyle(
                                fontSize: 10,
                                color: _method == i ? kOnAccent : AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _titles[i],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _method == i ? kOnAccent : AppColors.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_blurbs[_method], style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          if (_method == 1) ...[
            const Text('Key item', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final it = items[i];
                  final sel = it.id == _keyItemId;
                  return GestureDetector(
                    onTap: () => setState(() => _keyItemId = it.id),
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sel ? AppColors.accent : Colors.transparent,
                          width: 2,
                        ),
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
            const SizedBox(height: 16),
          ],
          if (_method != 0)
            TextField(
              controller: _mood,
              decoration: const InputDecoration(
                labelText: 'Mood or event',
                hintText: 'e.g. client meeting, weekend hangout',
              ),
            ),
          if (_method == 2) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Location (for the forecast)',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : _go,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_method == 0 ? Icons.dashboard_customize_outlined : Icons.auto_awesome),
              label: Text(
                _busy
                    ? 'Styling...'
                    : (_method == 0 ? 'Open canvas' : 'Generate outfit'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
