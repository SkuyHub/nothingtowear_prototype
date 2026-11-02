import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/models.dart';
import 'seed.dart';
import 'services.dart';

/// Single source of truth for the demo. Every method here maps to something
/// the backend will eventually do. Swap the bodies for API calls and the
/// screens do not need to change.
class AppState extends ChangeNotifier {
  AppState({WeatherService? weather, AiService? ai})
      : weather = weather ?? MockWeatherService(),
        ai = ai ?? MockAiService() {
    final s = SeedData.build();
    _users.addAll(s.users);
    _passwords.addAll(s.passwords);
    categories = List.unmodifiable(s.categories);
    _items.addAll(s.items);
    _outfits.addAll(s.outfits);
    _calendar.addAll(s.calendar);
    _recs.addAll(s.recs);
    _notifs.addAll(s.notifs);
    _packingLists.addAll(s.packingLists);
    _packingItems.addAll(s.packingItems);
    s.outfitRecipes.forEach((outfitId, itemIds) {
      final chosen = itemIds.map(itemById).whereType<ClothingItem>().toList();
      _outfitItems.addAll(layoutFor(
        chosen,
        keyItemId: s.outfitKeyItem[outfitId],
        outfitId: outfitId,
      ));
    });
  }

  final WeatherService weather;
  final AiService ai;

  // ---- storage (one list per SQL table) ----
  final List<AppUser> _users = [];
  final Map<String, String> _passwords = {}; // demo only, backend stores password_hash
  late final List<WardrobeCategory> categories;
  final List<ClothingItem> _items = [];
  final List<Outfit> _outfits = [];
  final List<OutfitItem> _outfitItems = [];
  final List<CalendarEntry> _calendar = [];
  final List<AiRecommendation> _recs = [];
  final List<AppNotification> _notifs = [];
  final List<PackingList> _packingLists = [];
  final List<PackingItem> _packingItems = [];

  AppUser? currentUser;
  int get _uid => currentUser?.id ?? -1;

  int _next(Iterable<int> ids) => ids.isEmpty ? 1 : ids.reduce(max) + 1;
  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ---- auth ----
  String? login(String email, String password) {
    final e = email.trim().toLowerCase();
    final match = _users.where((u) => u.email.toLowerCase() == e).toList();
    if (match.isEmpty || _passwords[match.first.email] != password) {
      return 'Email or password is incorrect.';
    }
    currentUser = match.first;
    notifyListeners();
    return null;
  }

  String? register(String nama, String email, String password) {
    final e = email.trim();
    if (_users.any((u) => u.email.toLowerCase() == e.toLowerCase())) {
      return 'That email is already registered.';
    }
    final user = AppUser(
      id: _next(_users.map((u) => u.id)),
      nama: nama.trim(),
      email: e,
    );
    _users.add(user);
    _passwords[e] = password;
    _notifs.add(AppNotification(
      id: _next(_notifs.map((n) => n.id)),
      userId: user.id,
      judul: 'Welcome to NothingToWear',
      pesan: 'Add your first pieces and let your stylist do the rest.',
      tipeNotifikasi: 'General',
      createdAt: DateTime.now(),
    ));
    currentUser = user;
    notifyListeners();
    return null;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  // ---- categories & items ----
  String categoryName(int id) {
    for (final c in categories) {
      if (c.id == id) return c.namaKategori;
    }
    return 'Other';
  }

  WardrobeCategory? categoryByName(String name) {
    for (final c in categories) {
      if (c.namaKategori == name) return c;
    }
    return null;
  }

  /// Current user's items, newest first.
  List<ClothingItem> get items {
    final list = _items.where((i) => i.userId == _uid).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  ClothingItem? itemById(int id) {
    for (final i in _items) {
      if (i.id == id) return i;
    }
    return null;
  }

  List<String> get styles =>
      items.map((i) => i.styleOccasion).whereType<String>().toSet().toList()..sort();

  ClothingItem addItem({
    required int categoryId,
    required String nama,
    String? warna,
    String? brand,
    String? ukuran,
    String? style,
    String? tag,
  }) {
    final item = ClothingItem(
      id: _next(_items.map((e) => e.id)),
      userId: _uid,
      categoryId: categoryId,
      namaItem: nama,
      warna: warna,
      brand: brand,
      ukuran: ukuran,
      styleOccasion: style,
      tag: tag,
      urlGambar: 'local://upload/${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
    );
    _items.add(item);
    notifyListeners();
    return item;
  }

  void toggleItemFavorite(int id) {
    final it = itemById(id);
    if (it == null) return;
    it.isFavorite = !it.isFavorite;
    notifyListeners();
  }

  /// AI Taxonomy: classify an existing item and merge the new tags in.
  Future<List<String>> runTaxonomy(int itemId) async {
    final it = itemById(itemId);
    if (it == null) return [];
    final r = await ai.classify(
      name: it.namaItem,
      categoryName: categoryName(it.categoryId),
      warna: it.warna,
    );
    final merged = <String>{...it.tags, ...r.tags}.toList();
    it.tag = merged.join(', ');
    it.styleOccasion = r.style;
    notifyListeners();
    return merged;
  }

  // ---- outfits ----
  List<Outfit> get outfits {
    final list = _outfits.where((o) => o.userId == _uid).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Outfit? outfitById(int id) {
    for (final o in _outfits) {
      if (o.id == id) return o;
    }
    return null;
  }

  List<OutfitItem> outfitItems(int outfitId) {
    final list = _outfitItems.where((e) => e.outfitId == outfitId).toList();
    list.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return list;
  }

  void toggleOutfitFavorite(int id) {
    final o = outfitById(id);
    if (o == null) return;
    o.isFavorite = !o.isFavorite;
    notifyListeners();
  }

  Outfit saveOutfit({
    Outfit? existing,
    required String nama,
    String? mood,
    required String method,
    required List<OutfitItem> layout,
  }) {
    late final Outfit o;
    if (existing != null) {
      o = existing;
      o.nama = nama;
      o.moodEvent = mood;
      _outfitItems.removeWhere((e) => e.outfitId == o.id);
    } else {
      o = Outfit(
        id: _next(_outfits.map((e) => e.id)),
        userId: _uid,
        nama: nama,
        moodEvent: mood,
        metodePembuatan: method,
        createdAt: DateTime.now(),
      );
      _outfits.add(o);
    }
    for (final l in layout) {
      _outfitItems.add(l.copy(outfitId: o.id));
    }
    notifyListeners();
    return o;
  }

  void deleteOutfit(int id) {
    final entryIds =
        _calendar.where((c) => c.outfitId == id).map((c) => c.id).toSet();
    _notifs.removeWhere((n) => n.calendarId != null && entryIds.contains(n.calendarId));
    _calendar.removeWhere((c) => c.outfitId == id);
    _recs.removeWhere((r) => r.outfitId == id);
    _outfitItems.removeWhere((e) => e.outfitId == id);
    _outfits.removeWhere((o) => o.id == id);
    notifyListeners();
  }

  // ---- layout / AI curation ----
  static const _slots = <String, List<Offset>>{
    'Outerwear': [Offset(0.27, 0.27)],
    'Tops': [Offset(0.70, 0.24)],
    'Bottoms': [Offset(0.50, 0.58)],
    'Footwear': [Offset(0.50, 0.85)],
    'Accessories': [
      Offset(0.85, 0.60),
      Offset(0.15, 0.62),
      Offset(0.85, 0.85),
      Offset(0.15, 0.85),
    ],
  };

  /// Places items on the canvas in a flat-lay arrangement.
  List<OutfitItem> layoutFor(
    List<ClothingItem> chosen, {
    int? keyItemId,
    int outfitId = 0,
  }) {
    final used = <String, int>{};
    var z = 1;
    final out = <OutfitItem>[];
    for (final it in chosen) {
      final cat = categoryName(it.categoryId);
      final slots = _slots[cat] ?? const [Offset(0.5, 0.5)];
      final n = used[cat] ?? 0;
      used[cat] = n + 1;
      final p = slots[n % slots.length];
      out.add(OutfitItem(
        outfitId: outfitId,
        itemId: it.id,
        posX: p.dx,
        posY: p.dy,
        zIndex: z++,
        isKeyItem: it.id == keyItemId,
      ));
    }
    return out;
  }

  String _styleForMood(String? mood) {
    final m = (mood ?? '').toLowerCase();
    if (m.contains('formal') ||
        m.contains('work') ||
        m.contains('meeting') ||
        m.contains('dinner') ||
        m.contains('wedding')) {
      return 'Formal & Evening';
    }
    if (m.contains('street') || m.contains('hangout') || m.contains('gig')) {
      return 'Street Fashion';
    }
    return 'Casual';
  }

  /// Method 2 (key item) and Method 3 (full AI) both end up here.
  /// If a location is given the forecast is used (no outerwear when it is hot).
  Future<List<OutfitItem>> curateOutfit({
    int? keyItemId,
    String? mood,
    String? location,
  }) async {
    double? temp;
    if (location != null && location.trim().isNotEmpty) {
      final f = await weather.forecast(location.trim(), DateTime.now());
      temp = f.suhu;
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
    final pool = items;
    final key = keyItemId == null ? null : itemById(keyItemId);
    final style = key?.styleOccasion ?? _styleForMood(mood);
    final rnd = Random();
    final chosen = <ClothingItem>[if (key != null) key];
    for (final name in const ['Tops', 'Bottoms', 'Outerwear', 'Footwear', 'Accessories']) {
      final cat = categoryByName(name);
      if (cat == null) continue;
      if (chosen.any((i) => i.categoryId == cat.id)) continue;
      if (name == 'Outerwear' && temp != null && temp >= 29.5) continue;
      var options =
          pool.where((i) => i.categoryId == cat.id && i.styleOccasion == style).toList();
      if (options.isEmpty) options = pool.where((i) => i.categoryId == cat.id).toList();
      if (options.isEmpty) continue;
      chosen.add(options[rnd.nextInt(options.length)]);
    }
    return layoutFor(chosen, keyItemId: keyItemId);
  }

  // ---- AI stylist chat ----
  /// Mock of the chat endpoint. Swap for a real call later.
  /// If the message mentions a piece you own, the outfit is built around it.
  Future<StylistReply> askStylist(String message) async {
    const stop = {
      'what', 'wear', 'today', 'with', 'from', 'should', 'something',
      'outfit', 'look', 'help', 'need', 'want', 'for',
    };
    final words = message
        .toLowerCase()
        .split(RegExp(r'[^a-z]+'))
        .where((w) => w.length > 3 && !stop.contains(w))
        .toSet();
    ClothingItem? key;
    for (final it in items) {
      final hay = '${it.namaItem} ${it.tag ?? ''}'.toLowerCase();
      if (words.any(hay.contains)) {
        key = it;
        break;
      }
    }
    final layout = await curateOutfit(
      keyItemId: key?.id,
      mood: message,
      location: currentUser?.lokasiDefault,
    );
    if (layout.isEmpty) {
      return const StylistReply(
        text: 'Your wardrobe is empty. Add a few pieces and I can style them.',
      );
    }
    final names = layout
        .map((o) => itemById(o.itemId)?.namaItem)
        .whereType<String>()
        .join(', ');
    return StylistReply(
      text: key != null
          ? 'Built around your ${key.namaItem}: $names.'
          : 'Here is a look for "$message": $names.',
      layout: layout,
      method: key != null ? 'Key Item AI' : 'Full AI Builder',
    );
  }

  // ---- daily recommendation ----
  AiRecommendation? get todaysRecommendation {
    final list = _recs.where((r) => r.userId == _uid).toList();
    if (list.isEmpty) return null;
    list.sort((a, b) {
      final c = b.tanggalRekomendasi.compareTo(a.tanggalRekomendasi);
      return c != 0 ? c : b.id.compareTo(a.id);
    });
    return list.first;
  }

  void toggleRecommendationSaved(int id) {
    for (final r in _recs) {
      if (r.id == id) r.isSaved = !r.isSaved;
    }
    notifyListeners();
  }

  // ---- calendar ----
  List<CalendarEntry> entriesOn(DateTime d) {
    final list =
        _calendar.where((e) => e.userId == _uid && _sameDay(e.tanggal, d)).toList();
    list.sort((a, b) => (a.waktu.hour * 60 + a.waktu.minute)
        .compareTo(b.waktu.hour * 60 + b.waktu.minute));
    return list;
  }

  bool hasEntriesOn(DateTime d) => entriesOn(d).isNotEmpty;

  Future<CalendarEntry> addCalendarEntry({
    required DateTime tanggal,
    required TimeOfDay waktu,
    required String lokasi,
    required String event,
    required int outfitId,
    WeatherForecast? forecast,
  }) async {
    final f = forecast ?? await weather.forecast(lokasi, tanggal);
    final entry = CalendarEntry(
      id: _next(_calendar.map((e) => e.id)),
      userId: _uid,
      outfitId: outfitId,
      tanggal: DateTime(tanggal.year, tanggal.month, tanggal.day),
      waktu: waktu,
      lokasi: lokasi,
      event: event,
      kondisiCuaca: f.kondisi,
      suhu: f.suhu,
    );
    _calendar.add(entry);
    final outfitName = outfitById(outfitId)?.nama ?? 'Your outfit';
    _notifs.add(AppNotification(
      id: _next(_notifs.map((n) => n.id)),
      userId: _uid,
      calendarId: entry.id,
      judul: 'OOTD Reminder',
      pesan:
          '$event on ${DateFormat('d MMM').format(tanggal)}: $outfitName is ready. Forecast: ${f.kondisi}, ${f.suhu.round()}°C.',
      tipeNotifikasi: 'OOTD Reminder',
      createdAt: DateTime.now(),
    ));
    notifyListeners();
    return entry;
  }

  void deleteCalendarEntry(int id) {
    _notifs.removeWhere((n) => n.calendarId == id);
    _calendar.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  // ---- notifications ----
  List<AppNotification> get notifications {
    final list = _notifs.where((n) => n.userId == _uid).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  void markRead(int id) {
    for (final n in _notifs) {
      if (n.id == id) n.isRead = true;
    }
    notifyListeners();
  }

  void markAllRead() {
    for (final n in _notifs) {
      if (n.userId == _uid) n.isRead = true;
    }
    notifyListeners();
  }

  // ---- packing ----
  List<PackingList> get packingLists {
    final list = _packingLists.where((p) => p.userId == _uid).toList();
    list.sort((a, b) => a.tglMulai.compareTo(b.tglMulai));
    return list;
  }

  PackingList? packingListById(int id) {
    for (final p in _packingLists) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<PackingItem> packingItemsOf(int listId) =>
      _packingItems.where((p) => p.packingId == listId).toList();

  ({int packed, int total}) packingProgress(int listId) {
    final list = packingItemsOf(listId);
    return (packed: list.where((p) => p.isPacked).length, total: list.length);
  }

  PackingList addPackingList({
    required String nama,
    String? destinasi,
    required DateTime start,
    required DateTime end,
    required Set<int> itemIds,
  }) {
    final p = PackingList(
      id: _next(_packingLists.map((e) => e.id)),
      userId: _uid,
      namaPerjalanan: nama,
      destinasi: destinasi,
      tglMulai: start,
      tglSelesai: end,
    );
    _packingLists.add(p);
    for (final id in itemIds) {
      _packingItems.add(PackingItem(packingId: p.id, itemId: id));
    }
    notifyListeners();
    return p;
  }

  void togglePacked(int listId, int itemId) {
    for (final p in _packingItems) {
      if (p.packingId == listId && p.itemId == itemId) p.isPacked = !p.isPacked;
    }
    notifyListeners();
  }

  // ---- profile ----
  void updateLocation(String value) {
    currentUser?.lokasiDefault = value.trim();
    notifyListeners();
  }

  String? updatePassword(String oldPw, String newPw) {
    final u = currentUser;
    if (u == null) return 'Not signed in.';
    if (_passwords[u.email] != oldPw) return 'Current password is incorrect.';
    if (newPw.length < 6) return 'New password must be at least 6 characters.';
    _passwords[u.email] = newPw;
    u.passwordUpdatedAt = DateTime.now();
    notifyListeners();
    return null;
  }

  int get totalItems => items.length;
  int get totalOutfits => outfits.length;
}

class StylistReply {
  const StylistReply({required this.text, this.layout, this.method = 'Full AI Builder'});

  final String text;
  final List<OutfitItem>? layout;
  final String method;
}
