import 'package:flutter/material.dart';
import '../models/models.dart';

/// Dummy data shaped like the SQL tables. Replace with API responses later.
class SeedData {
  SeedData._();

  static const demoEmail = 'demo@nothingtowear.com';
  static const demoPassword = 'demo123';

  final users = <AppUser>[];
  final passwords = <String, String>{};
  final categories = <WardrobeCategory>[];
  final items = <ClothingItem>[];
  final outfits = <Outfit>[];
  final outfitRecipes = <int, List<int>>{}; // outfit id -> item ids
  final outfitKeyItem = <int, int>{}; // outfit id -> key item id
  final calendar = <CalendarEntry>[];
  final recs = <AiRecommendation>[];
  final notifs = <AppNotification>[];
  final packingLists = <PackingList>[];
  final packingItems = <PackingItem>[];

  static SeedData build() {
    final s = SeedData._();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    s.users.add(AppUser(
      id: 1,
      nama: 'Gumga',
      email: demoEmail,
      lokasiDefault: 'Bogor',
    ));
    s.passwords[demoEmail] = demoPassword;

    const cats = ['Tops', 'Bottoms', 'Outerwear', 'Footwear', 'Accessories'];
    for (var i = 0; i < cats.length; i++) {
      s.categories.add(WardrobeCategory(
        id: i + 1,
        namaKategori: cats[i],
        urutanTampil: i + 1,
      ));
    }

    // id, category, name, colour, brand, size, style, tags
    const rows = <List<Object>>[
      [1, 3, 'Double Cashmere Coat', 'Brown', 'Massimo Dutti', 'M', 'Formal & Evening', 'cashmere, wool, belted'],
      [2, 1, 'Ribbed Wool Turtleneck', 'Cream', 'COS', 'M', 'Casual', 'knitwear, wool, layering'],
      [3, 3, 'Cashmere Trench', 'Beige', 'Massimo Dutti', 'M', 'Formal & Evening', 'cashmere, wind resistant'],
      [4, 2, 'Pleated Wool Trousers', 'Charcoal', 'COS', '30', 'Formal & Evening', 'wool, tailored'],
      [5, 4, 'Leather Chelsea Boots', 'Black', 'Lemaire', '42', 'Formal & Evening', 'leather, waterproof'],
      [6, 1, 'Rust Turtleneck', 'Rust', 'Uniqlo', 'M', 'Casual', 'knitwear, autumn'],
      [7, 1, 'Black Crew Tee', 'Black', 'Uniqlo', 'M', 'Casual', 'cotton, basic'],
      [8, 2, 'Light Wash Jeans', 'Light Blue', "Levi's", '30', 'Casual', 'denim, straight leg'],
      [9, 4, 'Black Slide Sandals', 'Black', 'Zara', '42', 'Casual', 'summer, easy'],
      [10, 5, 'Tan Leather Tote', 'Tan', 'Coach', 'One Size', 'Casual', 'leather, bag'],
      [11, 5, 'Gold Hoop Earrings', 'Gold', 'Mejuri', 'One Size', 'Formal & Evening', 'jewelry'],
      [12, 3, 'Oversized Bomber Jacket', 'Olive', 'Zara', 'L', 'Street Fashion', 'bomber, windproof'],
      [13, 2, 'Utility Cargo Pants', 'Khaki', 'H&M', '30', 'Street Fashion', 'cargo, relaxed'],
      [14, 4, 'White Sneakers', 'White', 'Nike', '42', 'Street Fashion', 'sneakers, everyday'],
      [15, 1, 'Graphic Hoodie', 'Grey', 'Uniqlo', 'L', 'Street Fashion', 'hoodie, cotton'],
      [16, 1, 'Linen Shirt', 'White', 'Zara', 'M', 'Casual', 'linen, breathable'],
      [17, 3, 'Navy Blazer', 'Navy', 'Zara', 'M', 'Formal & Evening', 'blazer, tailored'],
      [18, 1, 'White Dress Shirt', 'White', 'Massimo Dutti', 'M', 'Formal & Evening', 'cotton, crisp'],
    ];
    for (final r in rows) {
      final id = r[0] as int;
      s.items.add(ClothingItem(
        id: id,
        userId: 1,
        categoryId: r[1] as int,
        namaItem: r[2] as String,
        warna: r[3] as String,
        brand: r[4] as String,
        ukuran: r[5] as String,
        styleOccasion: r[6] as String,
        tag: r[7] as String,
        urlGambar: 'seed://item/$id',
        isFavorite: id == 1 || id == 10,
        createdAt: today.subtract(const Duration(days: 30)).add(Duration(days: id)),
      ));
    }

    void outfit(int id, String name, String mood, String method, List<int> itemIds,
        {int? key, bool fav = false, int daysAgo = 0}) {
      s.outfits.add(Outfit(
        id: id,
        userId: 1,
        nama: name,
        moodEvent: mood,
        metodePembuatan: method,
        isFavorite: fav,
        createdAt: today.subtract(Duration(days: daysAgo)),
      ));
      s.outfitRecipes[id] = itemIds;
      if (key != null) s.outfitKeyItem[id] = key;
    }

    outfit(1, 'Autumn Smart Casual', 'Overcast, pumpkin spice latte outing',
        'Full AI Builder', [3, 6, 4, 5, 11], key: 3, daysAgo: 1);
    outfit(2, 'Summer', 'Beach day', 'Manual', [7, 8, 9, 10], fav: true, daysAgo: 6);
    outfit(3, 'Street Run', 'Weekend hangout', 'Manual', [12, 15, 13, 14], daysAgo: 3);
    outfit(4, 'Boardroom', 'Client meeting', 'Key Item AI', [17, 18, 4, 5],
        key: 17, daysAgo: 2);

    s.calendar.addAll([
      CalendarEntry(
        id: 1, userId: 1, outfitId: 1, tanggal: today,
        waktu: const TimeOfDay(hour: 19, minute: 0),
        lokasi: 'Bogor', event: 'Pumpkin spice latte outing',
        kondisiCuaca: 'Overcast', suhu: 27.5,
      ),
      CalendarEntry(
        id: 2, userId: 1, outfitId: 4,
        tanggal: today.add(const Duration(days: 2)),
        waktu: const TimeOfDay(hour: 9, minute: 0),
        lokasi: 'Jakarta', event: 'Client meeting',
        kondisiCuaca: 'Sunny', suhu: 31,
      ),
      CalendarEntry(
        id: 3, userId: 1, outfitId: 3,
        tanggal: today.add(const Duration(days: 5)),
        waktu: const TimeOfDay(hour: 14, minute: 0),
        lokasi: 'Bandung', event: 'Weekend hangout',
        kondisiCuaca: 'Light rain', suhu: 24,
      ),
    ]);

    s.recs.addAll([
      AiRecommendation(
        id: 1, userId: 1, outfitId: 1,
        judulRekomendasi: 'Autumn Smart Casual',
        deskripsiKonteks: 'For overcast skies, and a pumpkin spice latte outing.',
        tagCuaca: 'wind resistant',
        tanggalRekomendasi: today,
      ),
      AiRecommendation(
        id: 2, userId: 1, outfitId: 4,
        judulRekomendasi: 'Boardroom Ready',
        deskripsiKonteks: 'Sharp tailoring for a client meeting.',
        tagCuaca: 'sunny',
        tanggalRekomendasi: today.subtract(const Duration(days: 1)),
      ),
    ]);

    s.notifs.addAll([
      AppNotification(
        id: 1, userId: 1, calendarId: 1,
        judul: 'OOTD Reminder',
        pesan: 'Tonight: Pumpkin spice latte outing. Your Autumn Smart Casual outfit is ready.',
        tipeNotifikasi: 'OOTD Reminder',
        createdAt: now.subtract(const Duration(hours: 1)),
      ),
      AppNotification(
        id: 2, userId: 1, calendarId: 3,
        judul: 'Weather Alert',
        pesan: 'Light rain expected in Bandung. Consider a water resistant layer.',
        tipeNotifikasi: 'Weather Alert',
        createdAt: now.subtract(const Duration(hours: 5)),
      ),
      AppNotification(
        id: 3, userId: 1,
        judul: 'Welcome to NothingToWear',
        pesan: 'Add your first pieces and let your stylist do the rest.',
        tipeNotifikasi: 'General',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ]);

    s.packingLists.addAll([
      PackingList(
        id: 1, userId: 1, namaPerjalanan: 'Bali Weekend', destinasi: 'Bali',
        tglMulai: today.add(const Duration(days: 14)),
        tglSelesai: today.add(const Duration(days: 17)),
      ),
      PackingList(
        id: 2, userId: 1, namaPerjalanan: 'Bandung Trip', destinasi: 'Bandung',
        tglMulai: today.add(const Duration(days: 5)),
        tglSelesai: today.add(const Duration(days: 6)),
      ),
    ]);
    s.packingItems.addAll([
      PackingItem(packingId: 1, itemId: 7, jumlah: 2, isPacked: true),
      PackingItem(packingId: 1, itemId: 8, isPacked: true),
      PackingItem(packingId: 1, itemId: 9),
      PackingItem(packingId: 1, itemId: 10),
      PackingItem(packingId: 2, itemId: 12),
      PackingItem(packingId: 2, itemId: 13),
      PackingItem(packingId: 2, itemId: 14, isPacked: true),
    ]);

    return s;
  }
}
