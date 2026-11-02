import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Add New Item: upload photo, AI vision auto-tagging, then check brand/size/tags.
/// The demo has no real image picker. "Upload photo" marks a photo as attached
/// and the preview is drawn from the chosen category and colour.
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _size = TextEditingController();
  final _tags = TextEditingController();
  bool _photo = false;
  bool _detecting = false;
  int? _categoryId;
  String? _color;
  String? _style;

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _size.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _autoTag() async {
    final app = context.read<AppState>();
    setState(() => _detecting = true);
    final d = await app.ai.detectFromPhoto();
    if (!mounted) return;
    setState(() {
      _detecting = false;
      _name.text = d.nama;
      _categoryId = app.categoryByName(d.category)?.id ?? _categoryId;
      _color = d.warna;
      _style = d.style;
      _tags.text = d.tags.join(', ');
      if (d.brand != null) _brand.text = d.brand!;
    });
  }

  void _save() {
    final app = context.read<AppState>();
    if (!_photo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload a photo first')),
      );
      return;
    }
    if (_name.text.trim().isEmpty || _categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a name and choose a category')),
      );
      return;
    }
    app.addItem(
      categoryId: _categoryId!,
      nama: _name.text.trim(),
      warna: _color,
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      ukuran: _size.text.trim().isEmpty ? null : _size.text.trim(),
      style: _style,
      tag: _tags.text.trim().isEmpty ? null : _tags.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "${_name.text.trim()}"')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final catName = _categoryId == null ? 'Tops' : app.categoryName(_categoryId!);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Item'),
        actions: [TextButton(onPressed: _save, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () => setState(() => _photo = true),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _photo
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: GarmentArt(warna: _color ?? 'Grey', categoryName: catName),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 44, color: AppColors.accent),
                        SizedBox(height: 8),
                        Text('Upload photo'),
                        Text('Demo: tap to attach a sample photo',
                            style: TextStyle(fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (!_photo || _detecting) ? null : _autoTag,
              icon: _detecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(_detecting ? 'Analysing...' : 'AI Vision Auto-Tagging'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Item name'),
          ),
          const SectionHeader('Category'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in app.categories)
                ChoiceChip(
                  label: Text(c.namaKategori),
                  selected: _categoryId == c.id,
                  onSelected: (_) => setState(() => _categoryId = c.id),
                ),
            ],
          ),
          const SectionHeader('Colour'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in garmentColors.keys)
                ChoiceChip(
                  label: Text(name),
                  avatar: CircleAvatar(backgroundColor: garmentColor(name), radius: 8),
                  selected: _color == name,
                  onSelected: (_) => setState(() => _color = name),
                ),
            ],
          ),
          const SectionHeader('Style'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in styleOptions)
                ChoiceChip(
                  label: Text(s),
                  selected: _style == s,
                  onSelected: (_) => setState(() => _style = s),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _brand,
            decoration: const InputDecoration(labelText: 'Brand'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _size,
            decoration: const InputDecoration(labelText: 'Size'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tags,
            decoration: const InputDecoration(
              labelText: 'Tags',
              hintText: 'comma separated, e.g. wool, tailored',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _save, child: const Text('Save item')),
          ),
        ],
      ),
    );
  }
}
