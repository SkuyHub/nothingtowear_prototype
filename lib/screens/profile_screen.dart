import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.currentUser;
    if (user == null) return const Scaffold(body: SizedBox.shrink());
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(child: UserAvatar(user: user, radius: 44)),
          const SizedBox(height: 14),
          Text(
            user.nama,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted),
          ),
          const SectionHeader('Wardrobe statistics'),
          Row(
            children: [
              Expanded(child: _stat('Total pieces', app.totalItems)),
              const SizedBox(width: 12),
              Expanded(child: _stat('Curated outfits', app.totalOutfits)),
            ],
          ),
          const SectionHeader('Settings'),
          _tile(
            icon: Icons.lock_outline,
            title: 'Update password',
            onTap: () => _passwordDialog(context),
          ),
          _tile(
            icon: Icons.place_outlined,
            title: 'Default location',
            subtitle: (user.lokasiDefault == null || user.lokasiDefault!.isEmpty)
                ? 'Not set'
                : user.lokasiDefault,
            onTap: () => _locationDialog(context),
          ),
          _tile(
            icon: Icons.logout,
            title: 'Log out',
            color: Colors.redAccent,
            onTap: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
              app.logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int value) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text('$value',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      );

  Widget _tile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    Color? color,
  }) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: Icon(icon, color: color),
          title: Text(title, style: TextStyle(color: color)),
          subtitle: subtitle == null
              ? null
              : Text(subtitle, style: const TextStyle(color: AppColors.muted)),
          trailing: color == null ? const Icon(Icons.chevron_right) : null,
          onTap: onTap,
        ),
      );

  Future<void> _locationDialog(BuildContext context) async {
    final app = context.read<AppState>();
    final c = TextEditingController(text: app.currentUser?.lokasiDefault ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Default location'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: 'City, e.g. Bogor'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok == true) app.updateLocation(c.text);
  }

  Future<void> _passwordDialog(BuildContext context) async {
    final app = context.read<AppState>();
    final oldC = TextEditingController();
    final newC = TextEditingController();
    final confirmC = TextEditingController();
    String? error;
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Update password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: oldC,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newC,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirmC,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm new password'),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(error!, style: const TextStyle(color: Colors.redAccent)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (newC.text != confirmC.text) {
                  setDialog(() => error = 'Passwords do not match.');
                  return;
                }
                final err = app.updatePassword(oldC.text, newC.text);
                if (err != null) {
                  setDialog(() => error = err);
                } else {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
    if (done == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
      );
    }
  }
}
