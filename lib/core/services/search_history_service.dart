import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'geocoding_service.dart';

class SearchHistoryService {
  static const String _searchHistoryKey = 'search_history';
  static const String _savedRoutesKey = 'saved_routes';
  static const int _maxHistoryItems = 20;
  
  /// Arama geçmişine ekle
  Future<void> addToHistory(GeocodingResult result) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Mevcut geçmişi al
    final history = await getSearchHistory();
    
    // Aynı konumu çıkar (varsa)
    history.removeWhere((item) => item.id == result.id);
    
    // Başa ekle
    history.insert(0, result);
    
    // Maksimum sayıda tut
    if (history.length > _maxHistoryItems) {
      history.removeRange(_maxHistoryItems, history.length);
    }
    
    // Kaydet
    final jsonList = history.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(_searchHistoryKey, jsonList);
  }
  
  /// Arama geçmişini getir
  Future<List<GeocodingResult>> getSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_searchHistoryKey) ?? [];
      
      final results = <GeocodingResult>[];
      
      for (final jsonStr in jsonList) {
        try {
          final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
          results.add(GeocodingResult.fromJson(jsonMap));
        } catch (e) {
          // Bozuk veriyi atla
          debugPrint('⚠️ Bozuk history verisi atlandı: $e');
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('❌ History okuma hatası: $e');
      // Hatalı veriyi temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_searchHistoryKey);
      return [];
    }
  }
  
  /// Arama geçmişini temizle
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_searchHistoryKey);
  }
  
  /// Arama geçmişinden sil
  Future<void> removeFromHistory(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getSearchHistory();
    
    history.removeWhere((item) => item.id == id);
    
    final jsonList = history.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(_searchHistoryKey, jsonList);
  }
  
  // ==================== SAVED ROUTES ====================
  
  /// Rotayı kaydet
  Future<void> saveRoute(SavedRoute route) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Mevcut rotaları al
    final routes = await getSavedRoutes();
    
    // Aynı rotayı çıkar (varsa)
    routes.removeWhere((r) => r.id == route.id);
    
    // Başa ekle
    routes.insert(0, route);
    
    // Maksimum 50 rota
    if (routes.length > 50) {
      routes.removeRange(50, routes.length);
    }
    
    // Kaydet
    final jsonList = routes.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(_savedRoutesKey, jsonList);
  }
  
  /// Kaydedilmiş rotaları getir
  Future<List<SavedRoute>> getSavedRoutes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_savedRoutesKey) ?? [];
      
      final results = <SavedRoute>[];
      
      for (final jsonStr in jsonList) {
        try {
          final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
          results.add(SavedRoute.fromJson(jsonMap));
        } catch (e) {
          // Bozuk veriyi atla
          debugPrint('⚠️ Bozuk saved route verisi atlandı: $e');
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('❌ Saved routes okuma hatası: $e');
      // Hatalı veriyi temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_savedRoutesKey);
      return [];
    }
  }
  
  /// Kaydedilmiş rotayı sil
  Future<void> deleteSavedRoute(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final routes = await getSavedRoutes();
    
    routes.removeWhere((route) => route.id == id);
    
    final jsonList = routes.map((e) => json.encode(e.toJson())).toList();
    await prefs.setStringList(_savedRoutesKey, jsonList);
  }
  
  /// Tüm kaydedilmiş rotaları temizle
  Future<void> clearSavedRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedRoutesKey);
  }
}

/// Kaydedilmiş rota
class SavedRoute {
  final String id;
  final String name;
  final GeocodingResult origin;
  final GeocodingResult destination;
  final DateTime savedAt;
  
  SavedRoute({
    required this.id,
    required this.name,
    required this.origin,
    required this.destination,
    required this.savedAt,
  });
  
  factory SavedRoute.fromJson(Map<String, dynamic> json) {
    return SavedRoute(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Rota',
      origin: GeocodingResult.fromJson(json['origin'] ?? {}),
      destination: GeocodingResult.fromJson(json['destination'] ?? {}),
      savedAt: json['savedAt'] != null 
          ? DateTime.parse(json['savedAt']) 
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'savedAt': savedAt.toIso8601String(),
    };
  }
  
  /// Kısa isim (örn: "Ev → İş")
  String get shortName {
    if (name.isNotEmpty) return name;
    return '${origin.shortTitle} → ${destination.shortTitle}';
  }
}
