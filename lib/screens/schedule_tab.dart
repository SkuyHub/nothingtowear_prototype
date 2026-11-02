import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/app_state.dart';
import '../data/services.dart';
import '../models/models.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Full-screen version, opened from the calendar icon in the header.
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OOTD Calendar')),
      body: const ScheduleTab(bottomPadding: 24),
    );
  }
}

class ScheduleTab extends StatefulWidget {
  const ScheduleTab({super.key, this.bottomPadding = 24});

  final double bottomPadding;

  @override
  State<ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<ScheduleTab> {
  late final DateTime _today;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _today = DateTime(n.year, n.month, n.day);
    _selected = _today;
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final days = List.generate(21, (i) => _today.add(Duration(days: i - 3)));
    final entries = app.entriesOn(_selected);
    return ListView(
      padding: EdgeInsets.only(bottom: widget.bottomPadding),
      children: [
        SizedBox(
          height: 76,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: days.length,
            itemBuilder: (_, i) {
              final d = days[i];
              final sel = d == _selected;
              return GestureDetector(
                onTap: () => setState(() => _selected = d),
                child: Container(
                  width: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.accent : AppColors.surfaceHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(d),
                        style: TextStyle(
                          fontSize: 11,
                          color: sel ? kOnAccent : AppColors.muted,
                        ),
                      ),
                      Text(
                        '${d.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: sel ? kOnAccent : AppColors.text,
                        ),
                      ),
                      Icon(
                        Icons.circle,
                        size: 5,
                        color: app.hasEntriesOn(d)
                            ? (sel ? kOnAccent : AppColors.accent)
                            : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SectionHeader(
          DateFormat('EEEE, d MMMM').format(_selected),
          trailing: TextButton.icon(
            onPressed: () => pushScreen(context, AddScheduleScreen(initialDate: _selected)),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Schedule'),
          ),
        ),
        if (entries.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 30),
            child: EmptyState(
              icon: Icons.event_busy_outlined,
              message: 'No outfit planned for this day.',
            ),
          ),
        for (final e in entries) _EntryCard(entry: e),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final CalendarEntry entry;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final outfit = app.outfitById(entry.outfitId);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 100,
            child: OutfitPreview(layout: app.outfitItems(entry.outfitId), radius: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.event ?? 'Outfit',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.waktu.format(context)} · ${entry.lokasi ?? '-'}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  outfit?.nama ?? '',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 8),
                if (entry.kondisiCuaca != null)
                  SmallChip(
                    '${entry.kondisiCuaca}${entry.suhu != null ? ' · ${entry.suhu!.round()}°C' : ''}',
                    color: AppColors.chip,
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove',
            icon: const Icon(Icons.delete_outline, color: AppColors.muted),
            onPressed: () => app.deleteCalendarEntry(entry.id),
          ),
        ],
      ),
    );
  }
}

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  late DateTime _date;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  final _event = TextEditingController();
  late final TextEditingController _location;
  int? _outfitId;
  WeatherForecast? _forecast;
  bool _loadingForecast = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _location = TextEditingController(
      text: context.read<AppState>().currentUser?.lokasiDefault ?? '',
    );
  }

  @override
  void dispose() {
    _event.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2024),
      lastDate: DateTime(2032),
    );
    if (d != null) {
      setState(() {
        _date = d;
        _forecast = null;
      });
    }
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  Future<void> _checkForecast() async {
    if (_location.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a location first')),
      );
      return;
    }
    setState(() => _loadingForecast = true);
    final f = await context.read<AppState>().weather.forecast(_location.text.trim(), _date);
    if (!mounted) return;
    setState(() {
      _forecast = f;
      _loadingForecast = false;
    });
  }

  Future<void> _save() async {
    if (_outfitId == null || _event.text.trim().isEmpty || _location.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick an outfit and fill in event and location')),
      );
      return;
    }
    setState(() => _saving = true);
    await context.read<AppState>().addCalendarEntry(
          tanggal: _date,
          waktu: _time,
          lokasi: _location.text.trim(),
          event: _event.text.trim(),
          outfitId: _outfitId!,
          forecast: _forecast,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Outfit scheduled')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final outfits = app.outfits;
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule outfit')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _event,
            decoration: const InputDecoration(labelText: 'Event name'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(DateFormat('d MMM yyyy').format(_date)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time, size: 16),
                  label: Text(_time.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _location,
            onChanged: (_) => setState(() => _forecast = null),
            decoration: const InputDecoration(
              labelText: 'Location',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _loadingForecast ? null : _checkForecast,
                icon: _loadingForecast
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_outlined, size: 18),
                label: const Text('Check forecast'),
              ),
              const SizedBox(width: 12),
              if (_forecast != null)
                SmallChip(
                  '${_forecast!.kondisi} · ${_forecast!.suhu.round()}°C',
                  color: AppColors.chip,
                ),
            ],
          ),
          const SectionHeader('Choose an outfit'),
          if (outfits.isEmpty)
            const EmptyState(icon: Icons.accessibility_new, message: 'Create an outfit first.')
          else
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: outfits.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final o = outfits[i];
                  final sel = o.id == _outfitId;
                  return GestureDetector(
                    onTap: () => setState(() => _outfitId = o.id),
                    child: Container(
                      width: 110,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: sel ? AppColors.accent : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: OutfitPreview(layout: app.outfitItems(o.id), radius: 10),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            o.nama,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save schedule'),
            ),
          ),
        ],
      ),
    );
  }
}
