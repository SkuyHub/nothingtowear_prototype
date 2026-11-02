import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class PackingTab extends StatelessWidget {
  const PackingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final lists = app.packingLists;
    final fmt = DateFormat('d MMM');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => pushScreen(context, const AddPackingScreen()),
            icon: const Icon(Icons.add),
            label: const Text('New packing list'),
          ),
        ),
        const SizedBox(height: 16),
        if (lists.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyState(
              icon: Icons.luggage_outlined,
              message: 'No trips planned yet.',
            ),
          ),
        for (final p in lists)
          Builder(builder: (context) {
            final prog = app.packingProgress(p.id);
            final ratio = prog.total == 0 ? 0.0 : prog.packed / prog.total;
            return GestureDetector(
              onTap: () => pushScreen(context, PackingDetailScreen(listId: p.id)),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.namaPerjalanan,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (p.destinasi != null && p.destinasi!.isNotEmpty) p.destinasi!,
                        '${fmt.format(p.tglMulai)} - ${fmt.format(p.tglSelesai)}',
                      ].join(' · '),
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                      backgroundColor: AppColors.chip,
                      color: AppColors.accent,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${prog.packed} of ${prog.total} packed',
                      style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class PackingDetailScreen extends StatelessWidget {
  const PackingDetailScreen({super.key, required this.listId});

  final int listId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final list = app.packingListById(listId);
    if (list == null) return const Scaffold(body: SizedBox.shrink());
    final entries = app.packingItemsOf(listId);
    final prog = app.packingProgress(listId);
    return Scaffold(
      appBar: AppBar(title: Text(list.namaPerjalanan)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          LinearProgressIndicator(
            value: prog.total == 0 ? 0 : prog.packed / prog.total,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: AppColors.chip,
            color: AppColors.accent,
          ),
          const SizedBox(height: 6),
          Text(
            '${prog.packed} of ${prog.total} packed',
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          for (final e in entries)
            Builder(builder: (context) {
              final item = app.itemById(e.itemId);
              if (item == null) return const SizedBox.shrink();
              final cat = app.categoryName(item.categoryId);
              return CheckboxListTile(
                value: e.isPacked,
                onChanged: (_) => app.togglePacked(listId, e.itemId),
                activeColor: AppColors.accent,
                checkColor: kOnAccent,
                controlAffinity: ListTileControlAffinity.trailing,
                secondary: SizedBox(
                  width: 44,
                  height: 44,
                  child: GarmentArt(warna: item.warna, categoryName: cat),
                ),
                title: Text(
                  item.namaItem,
                  style: TextStyle(
                    decoration: e.isPacked ? TextDecoration.lineThrough : null,
                    color: e.isPacked ? AppColors.muted : AppColors.text,
                  ),
                ),
                subtitle: Text(
                  e.jumlah > 1 ? '$cat · x${e.jumlah}' : cat,
                  style: const TextStyle(color: AppColors.muted),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class AddPackingScreen extends StatefulWidget {
  const AddPackingScreen({super.key});

  @override
  State<AddPackingScreen> createState() => _AddPackingScreenState();
}

class _AddPackingScreenState extends State<AddPackingScreen> {
  final _name = TextEditingController();
  final _dest = TextEditingController();
  DateTimeRange? _range;
  final Set<int> _picked = {};

  @override
  void dispose() {
    _name.dispose();
    _dest.dispose();
    super.dispose();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
      initialDateRange: _range,
    );
    if (r != null) setState(() => _range = r);
  }

  void _save() {
    if (_name.text.trim().isEmpty || _range == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a trip name and dates')),
      );
      return;
    }
    context.read<AppState>().addPackingList(
          nama: _name.text.trim(),
          destinasi: _dest.text.trim().isEmpty ? null : _dest.text.trim(),
          start: _range!.start,
          end: _range!.end,
          itemIds: _picked,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final fmt = DateFormat('d MMM yyyy');
    return Scaffold(
      appBar: AppBar(
        title: const Text('New packing list'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Trip name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dest,
            decoration: const InputDecoration(labelText: 'Destination'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickRange,
            icon: const Icon(Icons.date_range),
            label: Text(_range == null
                ? 'Choose dates'
                : '${fmt.format(_range!.start)} - ${fmt.format(_range!.end)}'),
          ),
          const SectionHeader('Pieces to bring'),
          for (final item in app.items)
            CheckboxListTile(
              value: _picked.contains(item.id),
              onChanged: (v) => setState(() {
                if (v == true) {
                  _picked.add(item.id);
                } else {
                  _picked.remove(item.id);
                }
              }),
              activeColor: AppColors.accent,
              checkColor: kOnAccent,
              controlAffinity: ListTileControlAffinity.trailing,
              secondary: SizedBox(
                width: 40,
                height: 40,
                child: GarmentArt(
                  warna: item.warna,
                  categoryName: app.categoryName(item.categoryId),
                ),
              ),
              title: Text(item.namaItem),
              subtitle: Text(
                app.categoryName(item.categoryId),
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
        ],
      ),
    );
  }
}
