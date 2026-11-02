import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// AI Taxonomy: one-click style identification for pieces already in the wardrobe.
class AiTaxonomyScreen extends StatefulWidget {
  const AiTaxonomyScreen({super.key});

  @override
  State<AiTaxonomyScreen> createState() => _AiTaxonomyScreenState();
}

class _AiTaxonomyScreenState extends State<AiTaxonomyScreen> {
  final Set<int> _busy = {};

  Future<void> _analyze(int id) async {
    final app = context.read<AppState>();
    setState(() => _busy.add(id));
    await app.runTaxonomy(id);
    if (!mounted) return;
    setState(() => _busy.remove(id));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Style and tags updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = app.items;
    return Scaffold(
      appBar: AppBar(title: const Text('AI Taxonomy')),
      body: items.isEmpty
          ? const EmptyState(icon: Icons.checkroom, message: 'Add some pieces first.')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final it = items[i];
                final busy = _busy.contains(it.id);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: GarmentArt(
                          warna: it.warna,
                          categoryName: app.categoryName(it.categoryId),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.namaItem,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              it.styleOccasion ?? 'Not classified',
                              style: const TextStyle(fontSize: 12, color: AppColors.accent),
                            ),
                            Text(
                              it.tags.isEmpty ? 'No tags yet' : it.tags.map((t) => '#$t').join(' '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      busy
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : FilledButton.tonal(
                              onPressed: () => _analyze(it.id),
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(64, 36),
                                backgroundColor: AppColors.chip,
                                foregroundColor: AppColors.text,
                              ),
                              child: const Text('Analyze'),
                            ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
