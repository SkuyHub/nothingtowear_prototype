import 'package:flutter/material.dart';

// Dart models mirroring db_nothingtowear (field names are camelCase versions
// of the SQL columns). Add fromJson/toJson to the others when the real API
// is ready; ClothingItem.fromJson below shows the pattern.

class AppUser {
  AppUser({
    required this.id,
    required this.nama,
    required this.email,
    this.avatarUrl,
    this.lokasiDefault,
    this.passwordUpdatedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final int id;
  String nama;
  final String email;
  String? avatarUrl;
  String? lokasiDefault;
  DateTime? passwordUpdatedAt;
  final DateTime createdAt;
}

class WardrobeCategory {
  const WardrobeCategory({
    required this.id,
    required this.namaKategori,
    required this.urutanTampil,
    this.ikonUrl,
  });

  final int id;
  final String namaKategori;
  final int urutanTampil;
  final String? ikonUrl;
}

class ClothingItem {
  ClothingItem({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.namaItem,
    required this.urlGambar,
    required this.createdAt,
    this.warna,
    this.brand,
    this.ukuran,
    this.styleOccasion,
    this.tag,
    this.isFavorite = false,
  });

  final int id;
  final int userId;
  int categoryId;
  String namaItem;
  String? warna;
  String? brand;
  String? ukuran;
  String? styleOccasion;
  String? tag; // comma separated, e.g. "wool, tailored"
  String urlGambar;
  bool isFavorite;
  final DateTime createdAt;

  List<String> get tags => (tag == null || tag!.trim().isEmpty)
      ? <String>[]
      : tag!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  factory ClothingItem.fromJson(Map<String, dynamic> j) => ClothingItem(
        id: j['id'] as int,
        userId: j['user_id'] as int,
        categoryId: j['category_id'] as int,
        namaItem: j['nama_item'] as String,
        warna: j['warna'] as String?,
        brand: j['brand'] as String?,
        ukuran: j['ukuran'] as String?,
        styleOccasion: j['style_occasion'] as String?,
        tag: j['tag'] as String?,
        urlGambar: j['url_gambar'] as String,
        isFavorite: j['is_favorite'] == 1 || j['is_favorite'] == true,
        createdAt: DateTime.tryParse('${j['created_at']}') ?? DateTime.now(),
      );
}

class Outfit {
  Outfit({
    required this.id,
    required this.userId,
    required this.nama,
    required this.metodePembuatan, // Manual, Key Item AI, Full AI Builder
    required this.createdAt,
    this.moodEvent,
    this.previewUrl,
    this.isFavorite = false,
  });

  final int id;
  final int userId;
  String nama;
  String? moodEvent;
  final String metodePembuatan;
  String? previewUrl;
  bool isFavorite;
  final DateTime createdAt;
}

/// Position of an item on an outfit canvas. posX/posY are the item centre as a
/// fraction (0..1) of canvas width/height so the layout is screen-size independent.
class OutfitItem {
  OutfitItem({
    required this.outfitId,
    required this.itemId,
    this.posX = 0.5,
    this.posY = 0.5,
    this.zIndex = 1,
    this.scale = 1,
    this.isKeyItem = false,
  });

  final int outfitId;
  final int itemId;
  double posX;
  double posY;
  int zIndex;
  double scale;
  bool isKeyItem;

  OutfitItem copy({int? outfitId}) => OutfitItem(
        outfitId: outfitId ?? this.outfitId,
        itemId: itemId,
        posX: posX,
        posY: posY,
        zIndex: zIndex,
        scale: scale,
        isKeyItem: isKeyItem,
      );
}

class CalendarEntry {
  CalendarEntry({
    required this.id,
    required this.userId,
    required this.outfitId,
    required this.tanggal,
    required this.waktu,
    this.lokasi,
    this.event,
    this.kondisiCuaca,
    this.suhu,
  });

  final int id;
  final int userId;
  final int outfitId;
  final DateTime tanggal;
  final TimeOfDay waktu;
  final String? lokasi;
  final String? event;
  final String? kondisiCuaca;
  final double? suhu;
}

class AiRecommendation {
  AiRecommendation({
    required this.id,
    required this.userId,
    required this.outfitId,
    required this.judulRekomendasi,
    required this.tanggalRekomendasi,
    this.deskripsiKonteks,
    this.tagCuaca,
    this.isSaved = false,
  });

  final int id;
  final int userId;
  final int outfitId;
  final String judulRekomendasi;
  final String? deskripsiKonteks;
  final String? tagCuaca;
  bool isSaved;
  final DateTime tanggalRekomendasi;
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.userId,
    required this.judul,
    required this.pesan,
    required this.tipeNotifikasi, // OOTD Reminder, Weather Alert, ...
    required this.createdAt,
    this.calendarId,
    this.isRead = false,
  });

  final int id;
  final int userId;
  final int? calendarId;
  final String judul;
  final String pesan;
  final String tipeNotifikasi;
  bool isRead;
  final DateTime createdAt;
}

class PackingList {
  PackingList({
    required this.id,
    required this.userId,
    required this.namaPerjalanan,
    required this.tglMulai,
    required this.tglSelesai,
    this.destinasi,
  });

  final int id;
  final int userId;
  final String namaPerjalanan;
  final String? destinasi;
  final DateTime tglMulai;
  final DateTime tglSelesai;
}

class PackingItem {
  PackingItem({
    required this.packingId,
    required this.itemId,
    this.jumlah = 1,
    this.isPacked = false,
  });

  final int packingId;
  final int itemId;
  int jumlah;
  bool isPacked;
}
