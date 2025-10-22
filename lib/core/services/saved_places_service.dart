import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_design.dart';
import 'geocoding_service.dart';

  /// Kaydedilen yer sınıfı
class SavedPlace {
  final String id;
  final String name;
  final GeocodingResult location;
  final String iconName;
  final DateTime savedAt;
  final Color? customColor;
  final String? emoji;

  const SavedPlace({
    required this.id,
    required this.name,
    required this.location,
    required this.iconName,
    required this.savedAt,
    this.customColor,
    this.emoji,
  });

  /// İkon getter'ı (iconName'den IconData döndürür)
  IconData get icon => getIcon(iconName);

  /// İkon rengini hesaplar (arka plan rengine göre kontrast için)
  Color get iconColor {
    final backgroundColor = customColor ?? AppDesign.primaryColor;

    // Arka plan rengine göre kontrastlı ikon rengi seç
    // Açık renkler için koyu ikon, koyu renkler için açık ikon
    final brightness = backgroundColor.computeLuminance();

    if (brightness > 0.5) {
      // Açık arka plan (sarı, açık mavi vb.) için koyu ikon
      return Colors.black87;
    } else {
      // Koyu arka plan için açık ikon
      return Colors.white;
    }
  }

  /// İkon adından emoji karakteri döndürür (harita marker'ı için)
  String get emojiForMap {
    switch (iconName) {
      case 'home': return '🏠';
      case 'work': return '💼';
      case 'school': return '🏫';
      case 'restaurant': return '🍽️';
      case 'shopping_cart': return '🛒';
      case 'local_gas_station': return '⛽';
      case 'local_hospital': return '🏥';
      case 'park': return '🌳';
      case 'sports_soccer': return '⚽';
      case 'favorite': return '❤️';
      case 'star': return '⭐';

      // Eğitim ve öğrenim
      case 'library_books': return '📚';
      case 'menu_book': return '📖';
      case 'edit': return '✏️';
      case 'science': return '🔬';

      // Sağlık ve bakım
      case 'medical_services': return '⚕️';
      case 'local_pharmacy': return '💊';
      case 'healing': return '🩹';

      // Yiyecek ve içecek
      case 'local_dining': return '🍽️';
      case 'local_cafe': return '☕';
      case 'local_bar': return '🍺';

      // Ulaşım
      case 'directions_car': return '🚗';
      case 'local_taxi': return '🚕';
      case 'directions_bus': return '🚌';
      case 'train': return '🚂';
      case 'flight': return '✈️';

      // Eğlence ve dinlenme
      case 'movie': return '🎬';
      case 'music_note': return '🎵';
      case 'sports_basketball': return '🏀';
      case 'pool': return '🏊';

      // Alışveriş ve hizmetler
      case 'store': return '🏪';
      case 'local_laundry_service': return '👔';
      case 'local_atm': return '🏧';
      case 'local_florist': return '💐';

      // Diğer önemli yerler
      case 'museum': return '🏛️';
      case 'church': return '⛪';
      case 'mosque': return '🕌';
      case 'beach_access': return '🏖️';

      default: return '📍'; // Varsayılan pin emoji
    }
  }

  /// JSON'dan SavedPlace oluştur
  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: json['id'] as String,
      name: json['name'] as String,
      location: GeocodingResult.fromJson(json['location'] as Map<String, dynamic>),
      iconName: json['iconName'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      customColor: json['customColor'] != null ? Color(json['customColor'] as int) : null,
      emoji: json['emoji'] as String?,
    );
  }

  /// SavedPlace'i JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location.toJson(),
      'iconName': iconName,
      'savedAt': savedAt.toIso8601String(),
      'customColor': customColor?.toARGB32(),
      'emoji': emoji,
    };
  }

  /// İkon adından IconData döndürür
  static IconData getIcon(String iconName) {
    // Genişletilmiş Material Design ikonları için
    switch (iconName) {
      // Temel kategoriler
      case 'home': return Icons.home;
      case 'work': return Icons.work;
      case 'school': return Icons.school;
      case 'restaurant': return Icons.restaurant;
      case 'shopping_cart': return Icons.shopping_cart;
      case 'local_gas_station': return Icons.local_gas_station;
      case 'local_hospital': return Icons.local_hospital;
      case 'park': return Icons.park;
      case 'sports_soccer': return Icons.sports_soccer;
      case 'favorite': return Icons.favorite;
      case 'star': return Icons.star;

      // Eğitim ve öğrenim
      case 'library_books': return Icons.library_books;
      case 'menu_book': return Icons.menu_book;
      case 'edit': return Icons.edit;
      case 'science': return Icons.science;

      // Sağlık ve bakım
      case 'medical_services': return Icons.medical_services;
      case 'local_pharmacy': return Icons.local_pharmacy;
      case 'healing': return Icons.healing;

      // Yiyecek ve içecek
      case 'local_dining': return Icons.local_dining;
      case 'local_cafe': return Icons.local_cafe;
      case 'local_bar': return Icons.local_bar;

      // Ulaşım
      case 'directions_car': return Icons.directions_car;
      case 'local_taxi': return Icons.local_taxi;
      case 'directions_bus': return Icons.directions_bus;
      case 'train': return Icons.train;
      case 'flight': return Icons.flight;

      // Eğlence ve dinlenme
      case 'movie': return Icons.movie;
      case 'music_note': return Icons.music_note;
      case 'sports_basketball': return Icons.sports_basketball;
      case 'pool': return Icons.pool;

      // Alışveriş ve hizmetler
      case 'store': return Icons.store;
      case 'local_laundry_service': return Icons.local_laundry_service;
      case 'local_atm': return Icons.local_atm;
      case 'local_florist': return Icons.local_florist;

      // Diğer önemli yerler
      case 'museum': return Icons.museum;
      case 'church': return Icons.church;
      case 'mosque': return Icons.mosque;
      case 'beach_access': return Icons.beach_access;

      default: return Icons.place; // Varsayılan ikon
    }
  }

  /// Önerilen ikonlar listesi (Genişletilmiş Material Design ikon isimleri)
  static List<String> get suggestedIcons => [
    // Temel kategoriler
    'home',           // Ev
    'work',           // İş
    'school',         // Okul
    'restaurant',     // Restoran
    'shopping_cart',  // Alışveriş
    'local_gas_station', // Benzin İstasyonu
    'local_hospital', // Hastane
    'park',           // Park
    'sports_soccer',  // Spor
    'favorite',       // Favori
    'star',           // Yıldız

    // Eğitim ve öğrenim
    'library_books',  // Kütüphane
    'menu_book',      // Kitap
    'edit',           // Düzenleme
    'science',        // Bilim

    // Sağlık ve bakım
    'medical_services', // Tıbbi Hizmetler
    'local_pharmacy',   // Eczane
    'healing',          // İyileşme

    // Yiyecek ve içecek
    'local_dining',   // Yemek
    'local_cafe',     // Kafe
    'local_bar',      // Bar

    // Ulaşım
    'directions_car', // Araba
    'local_taxi',     // Taksi
    'directions_bus', // Otobüs
    'train',          // Tren
    'flight',         // Uçak

    // Eğlence ve dinlenme
    'movie',          // Sinema
    'music_note',     // Müzik
    'sports_basketball', // Basketbol
    'pool',           // Yüzme Havuzu

    // Alışveriş ve hizmetler
    'store',          // Mağaza
    'local_laundry_service', // Çamaşırhane
    'local_atm',      // ATM
    'local_florist',  // Çiçekçi

    // Diğer önemli yerler
    'museum',         // Müze
    'church',         // Kilise
    'mosque',         // Cami
    'beach_access',   // Plaj
  ];

  /// İkon adından display name
  static String getIconDisplayName(String iconName) {
    // Genişletilmiş Material Design ikonları için Türkçe isimler
    switch (iconName) {
      // Temel kategoriler
      case 'home': return 'Ev';
      case 'work': return 'İş';
      case 'school': return 'Okul';
      case 'restaurant': return 'Restoran';
      case 'shopping_cart': return 'Alışveriş';
      case 'local_gas_station': return 'Benzin İstasyonu';
      case 'local_hospital': return 'Hastane';
      case 'park': return 'Park';
      case 'sports_soccer': return 'Futbol';
      case 'favorite': return 'Favori';
      case 'star': return 'Yıldız';

      // Eğitim ve öğrenim
      case 'library_books': return 'Kütüphane';
      case 'menu_book': return 'Kitap';
      case 'edit': return 'Düzenleme';
      case 'science': return 'Bilim';

      // Sağlık ve bakım
      case 'medical_services': return 'Tıbbi Hizmetler';
      case 'local_pharmacy': return 'Eczane';
      case 'healing': return 'İyileşme';

      // Yiyecek ve içecek
      case 'local_dining': return 'Yemek';
      case 'local_cafe': return 'Kafe';
      case 'local_bar': return 'Bar';

      // Ulaşım
      case 'directions_car': return 'Araba';
      case 'local_taxi': return 'Taksi';
      case 'directions_bus': return 'Otobüs';
      case 'train': return 'Tren';
      case 'flight': return 'Uçak';

      // Eğlence ve dinlenme
      case 'movie': return 'Sinema';
      case 'music_note': return 'Müzik';
      case 'sports_basketball': return 'Basketbol';
      case 'pool': return 'Yüzme Havuzu';

      // Alışveriş ve hizmetler
      case 'store': return 'Mağaza';
      case 'local_laundry_service': return 'Çamaşırhane';
      case 'local_atm': return 'ATM';
      case 'local_florist': return 'Çiçekçi';

      // Diğer önemli yerler
      case 'museum': return 'Müze';
      case 'church': return 'Kilise';
      case 'mosque': return 'Cami';
      case 'beach_access': return 'Plaj';

      default: return 'İkon';
    }
  }

  /// Önerilen renkler listesi (Apple Maps tarzı)
  static List<Color> get suggestedColors => [
    const Color(0xFFFF3B30), // Kırmızı
    const Color(0xFFFF9500), // Turuncu
    const Color(0xFFFFCC00), // Sarı
    const Color(0xFF34C759), // Yeşil
    const Color(0xFF007AFF), // Mavi
    const Color(0xFF5856D6), // İndigo
    const Color(0xFFAF52DE), // Mor
    const Color(0xFFFF2D55), // Pembe
    const Color(0xFFA2845E), // Kahve
    const Color(0xFF8E8E93), // Gri
    const Color(0xFFFF6B6B), // Açık kırmızı
    const Color(0xFFFFA726), // Açık turuncu
    const Color(0xFFFFEB3B), // Açık sarı
    const Color(0xFF66BB6A), // Açık yeşil
    const Color(0xFF42A5F5), // Açık mavi
    const Color(0xFF7E57C2), // Açık mor
    const Color(0xFFEC407A), // Açık pembe
    const Color(0xFF26A69A), // Teal
    const Color(0xFFAB47BC), // Derin mor
    const Color(0xFFEF5350), // Coral
  ];
}

/// Kaydedilen yerler servisi
class SavedPlacesService {
  static const String _savedPlacesKey = 'saved_places';
  static const int _maxPlaces = 50;

  /// Kaydedilen yerleri getir
  Future<List<SavedPlace>> getSavedPlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_savedPlacesKey) ?? [];

      final results = <SavedPlace>[];

      for (final jsonStr in jsonList) {
        try {
          final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
          results.add(SavedPlace.fromJson(jsonMap));
        } catch (e) {
          debugPrint('⚠️ Bozuk saved place verisi atlandı: $e');
        }
      }

      // Tarihe göre sırala (en yeni üstte)
      results.sort((a, b) => b.savedAt.compareTo(a.savedAt));

      return results;
    } catch (e) {
      debugPrint('❌ Saved places okuma hatası: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedPlacesKey);
      return [];
    }
  }

  /// Yer kaydet
  Future<void> savePlace(SavedPlace place) async {
    final prefs = await SharedPreferences.getInstance();

    // Mevcut yerleri al
    final places = await getSavedPlaces();

    // Aynı ID'li yeri çıkar (varsa)
    places.removeWhere((p) => p.id == place.id);

    // Başa ekle
    places.insert(0, place);

    // Maksimum sayıda tut
    if (places.length > _maxPlaces) {
      places.removeRange(_maxPlaces, places.length);
    }

    // Kaydet
    final jsonList = places.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(_savedPlacesKey, jsonList);
  }

  /// Yeri güncelle
  Future<void> updatePlace(SavedPlace updatedPlace) async {
    final prefs = await SharedPreferences.getInstance();
    final places = await getSavedPlaces();

    final index = places.indexWhere((p) => p.id == updatedPlace.id);
    if (index != -1) {
      places[index] = updatedPlace;

      final jsonList = places.map((e) => json.encode(e.toJson())).toList();
      await prefs.setStringList(_savedPlacesKey, jsonList);
    }
  }

  /// Yeri sil
  Future<void> deletePlace(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final places = await getSavedPlaces();

    places.removeWhere((place) => place.id == id);

    final jsonList = places.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(_savedPlacesKey, jsonList);
  }

  /// Tüm yerleri temizle
  Future<void> clearAllPlaces() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedPlacesKey);
  }

  /// ID ile yer getir
  Future<SavedPlace?> getPlaceById(String id) async {
    final places = await getSavedPlaces();
    return places.where((place) => place.id == id).firstOrNull;
  }

  /// İsim ile yer ara
  Future<List<SavedPlace>> searchPlaces(String query) async {
    final places = await getSavedPlaces();
    final lowerQuery = query.toLowerCase();

    return places.where((place) =>
        place.name.toLowerCase().contains(lowerQuery) ||
        place.location.placeName.toLowerCase().contains(lowerQuery) ||
        (place.location.address?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }
}