import 'dart:async';

// These two abstract classes are the "API AI" and "API Cuaca" external
// entities from the DFD. The mock classes below fake them for the demo.
// To go live, implement the same interfaces with real HTTP calls.

class WeatherForecast {
  const WeatherForecast({required this.kondisi, required this.suhu});
  final String kondisi;
  final double suhu;
}

abstract class WeatherService {
  Future<WeatherForecast> forecast(String location, DateTime date);
}

class MockWeatherService implements WeatherService {
  static const _conditions = ['Sunny', 'Cloudy', 'Light rain', 'Windy', 'Overcast'];

  @override
  Future<WeatherForecast> forecast(String location, DateTime date) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final key = location
        .toLowerCase()
        .codeUnits
        .fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
    final seed = key + date.year * 372 + date.month * 31 + date.day;
    return WeatherForecast(
      kondisi: _conditions[seed % _conditions.length],
      suhu: 24 + (seed % 90) / 10,
    );
  }
}

class AiDetection {
  const AiDetection({
    required this.nama,
    required this.category,
    required this.warna,
    required this.tags,
    required this.style,
    this.brand,
  });

  final String nama;
  final String category;
  final String warna;
  final List<String> tags;
  final String style;
  final String? brand;
}

class AiClassification {
  const AiClassification({required this.tags, required this.style});
  final List<String> tags;
  final String style;
}

abstract class AiService {
  /// "AI Vision Auto-Tagging" on a newly uploaded photo.
  Future<AiDetection> detectFromPhoto();

  /// "AI Taxonomy" on an item already in the wardrobe.
  Future<AiClassification> classify({
    required String name,
    required String categoryName,
    String? warna,
  });
}

class MockAiService implements AiService {
  int _n = 0;

  static const _samples = [
    AiDetection(
      nama: 'Linen Button-Up Shirt',
      category: 'Tops',
      warna: 'White',
      tags: ['linen', 'breathable', 'smart casual'],
      style: 'Casual',
      brand: 'Zara',
    ),
    AiDetection(
      nama: 'Pleated Wool Trousers',
      category: 'Bottoms',
      warna: 'Charcoal',
      tags: ['wool', 'tailored', 'pleated'],
      style: 'Formal & Evening',
      brand: 'COS',
    ),
    AiDetection(
      nama: 'Oversized Bomber Jacket',
      category: 'Outerwear',
      warna: 'Olive',
      tags: ['bomber', 'layering', 'windproof'],
      style: 'Street Fashion',
    ),
    AiDetection(
      nama: 'Leather Chelsea Boots',
      category: 'Footwear',
      warna: 'Black',
      tags: ['leather', 'waterproof', 'chelsea'],
      style: 'Formal & Evening',
    ),
    AiDetection(
      nama: 'Gold Hoop Earrings',
      category: 'Accessories',
      warna: 'Gold',
      tags: ['jewelry', 'statement'],
      style: 'Formal & Evening',
    ),
  ];

  @override
  Future<AiDetection> detectFromPhoto() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    return _samples[_n++ % _samples.length];
  }

  @override
  Future<AiClassification> classify({
    required String name,
    required String categoryName,
    String? warna,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    const base = {
      'Tops': ['top', 'layering'],
      'Bottoms': ['bottoms', 'tailored fit'],
      'Outerwear': ['outerwear', 'weather ready'],
      'Footwear': ['footwear', 'everyday'],
      'Accessories': ['accessory', 'finishing touch'],
    };
    final tags = <String>[
      ...(base[categoryName] ?? const ['wardrobe']),
      if (warna != null) warna.toLowerCase(),
    ];
    final n = name.toLowerCase();
    String style = 'Casual';
    if (n.contains('blazer') ||
        n.contains('wool') ||
        n.contains('cashmere') ||
        n.contains('dress')) {
      style = 'Formal & Evening';
    } else if (n.contains('bomber') ||
        n.contains('hoodie') ||
        n.contains('cargo') ||
        n.contains('sneaker')) {
      style = 'Street Fashion';
    }
    return AiClassification(tags: tags, style: style);
  }
}
