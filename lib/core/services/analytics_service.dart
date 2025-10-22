import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_stats.dart';

/// Kullanıcı analizi ve istatistiklerini yöneten servis
/// Lokal depolama ve Firebase entegrasyonu sağlar
class AnalyticsService {
  static const String _statsKey = 'user_stats';
  static const String _lastSyncKey = 'last_analytics_sync';

  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  UserStats _currentStats = UserStats();

  AnalyticsService(this._firestore, this._prefs);

  /// Mevcut istatistikleri al
  UserStats get currentStats => _currentStats;

  /// Servisi başlat ve verileri yükle
  Future<void> initialize() async {
    await _loadStatsFromLocal();
    await _syncWithFirebase();
  }

  /// Lokal depodan istatistikleri yükle
  Future<void> _loadStatsFromLocal() async {
    final statsJson = _prefs.getString(_statsKey);
    if (statsJson != null) {
      try {
        final statsMap = json.decode(statsJson);
        _currentStats = UserStats.fromJson(statsMap);
      } catch (e) {
        print('Error loading stats from local: $e');
        _currentStats = UserStats();
      }
    }
  }

  /// İstatistikleri lokal depoya kaydet
  Future<void> _saveStatsToLocal() async {
    try {
      final statsJson = json.encode(_currentStats.toJson());
      await _prefs.setString(_statsKey, statsJson);
    } catch (e) {
      print('Error saving stats to local: $e');
    }
  }

  /// Firebase ile senkronize et
  Future<void> _syncWithFirebase() async {
    try {
      final user = await _getCurrentUser();
      if (user == null) return;

      final userEmail = user.email;
      if (userEmail == null) return;

      // Email'i hash et (basit hash, production'da daha güvenli yöntem kullan)
      final userHash = _hashEmail(userEmail);

      final docRef = _firestore.collection('user_analytics').doc(userHash);
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        // Firebase'den veriyi al ve birleştir
        final firebaseData = docSnapshot.data() as Map<String, dynamic>;
        final firebaseStats = UserStats.fromJson(firebaseData['stats'] ?? {});

        // Lokal ve Firebase verilerini birleştir
        _currentStats = _currentStats.merge(firebaseStats);
        await _saveStatsToLocal();
      } else {
        // Firebase'de veri yoksa, lokal veriyi yükle
        await _uploadStatsToFirebase(userHash);
      }

      // Son sync zamanını kaydet
      await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error syncing with Firebase: $e');
    }
  }

  /// İstatistikleri Firebase'e yükle
  Future<void> _uploadStatsToFirebase(String userHash) async {
    try {
      final user = await _getCurrentUser();
      if (user == null) return;

      final userEmail = user.email;
      if (userEmail == null) return;

      final docRef = _firestore.collection('user_analytics').doc(userHash);

      await docRef.set({
        'user_email_hash': userHash,
        'stats': _currentStats.toJson(),
        'last_updated': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error uploading stats to Firebase: $e');
    }
  }

  /// Rota arama olayını kaydet
  Future<void> logRouteSearch({String? destination, double? distance}) async {
    _currentStats.totalRouteSearches++;
    _currentStats.lastUpdated = DateTime.now();

    final todayKey = UserStats.getTodayKey();
    _currentStats.dailySearches[todayKey] =
        (_currentStats.dailySearches[todayKey] ?? 0) + 1;

    if (destination != null && !_currentStats.favoriteDestinations.contains(destination)) {
      _currentStats.favoriteDestinations.add(destination);
      // Sadece ilk 10 favori destinasyonu tut
      if (_currentStats.favoriteDestinations.length > 10) {
        _currentStats.favoriteDestinations.removeAt(0);
      }
    }

    await _saveStatsToLocal();
    await _syncWithFirebaseAsync();
  }

  /// Rota tamamlama olayını kaydet
  Future<void> logRouteCompleted(double distanceKm, {double? fuelSaved}) async {
    _currentStats.completedRoutes++;
    _currentStats.totalKm += distanceKm;
    _currentStats.lastUpdated = DateTime.now();

    // Ortalama rota uzunluğunu güncelle
    final totalRoutes = _currentStats.totalRouteSearches;
    if (totalRoutes > 0) {
      _currentStats.averageRouteLength =
          (_currentStats.averageRouteLength * (totalRoutes - 1) + distanceKm) / totalRoutes;
    }

    // Aylık kilometre verisini güncelle
    final monthKey = UserStats.getCurrentMonthKey();
    _currentStats.monthlyKm[monthKey] =
        (_currentStats.monthlyKm[monthKey] ?? 0) + distanceKm;

    // Yakıt tasarrufu
    if (fuelSaved != null) {
      _currentStats.fuelSaved += fuelSaved;
    }

    await _saveStatsToLocal();
    await _syncWithFirebaseAsync();
  }

  /// Favori sayısı güncelleme
  Future<void> updateFavoriteCount(int count) async {
    _currentStats.activeFavorites = count;
    _currentStats.lastUpdated = DateTime.now();

    await _saveStatsToLocal();
    await _syncWithFirebaseAsync();
  }

  /// Aylık istatistikleri al
  Map<String, dynamic> getMonthlyStats([String? monthKey]) {
    monthKey ??= UserStats.getCurrentMonthKey();
    return _currentStats.getMonthlyStats(monthKey);
  }

  /// Günlük istatistikleri al
  Map<String, dynamic> getDailyStats([String? date]) {
    date ??= UserStats.getTodayKey();
    return _currentStats.getDailyStats(date);
  }

  /// Tüm istatistikleri sıfırla (test/debug için)
  Future<void> resetStats() async {
    _currentStats.reset();
    await _saveStatsToLocal();

    // Firebase'den de sil
    try {
      final user = await _getCurrentUser();
      if (user != null && user.email != null) {
        final userHash = _hashEmail(user.email!);
        await _firestore.collection('user_analytics').doc(userHash).delete();
      }
    } catch (e) {
      print('Error resetting Firebase stats: $e');
    }
  }

  /// Firebase async sync (ana thread'i bloklamaz)
  Future<void> _syncWithFirebaseAsync() async {
    try {
      await _syncWithFirebase();
    } catch (e) {
      // Firebase hatası ana akışı etkilemesin
      print('Async Firebase sync failed: $e');
    }
  }

  /// Mevcut kullanıcıyı al
  Future<User?> _getCurrentUser() async {
    // Firebase Auth'tan kullanıcıyı al
    return FirebaseAuth.instance.currentUser;
  }

  /// Email'i basit hash et (production'da SHA256 kullan)
  String _hashEmail(String email) {
    // Basit hash, production'da crypto library kullan
    return email.hashCode.toString();
  }

  /// Debug için istatistikleri yazdır
  void printStats() {
    print('=== User Stats ===');
    print('Total Route Searches: ${_currentStats.totalRouteSearches}');
    print('Total Km: ${_currentStats.totalKm}');
    print('Active Favorites: ${_currentStats.activeFavorites}');
    print('Completed Routes: ${_currentStats.completedRoutes}');
    print('Average Route Length: ${_currentStats.averageRouteLength}');
    print('Fuel Saved: ${_currentStats.fuelSaved}');
    print('Last Updated: ${_currentStats.lastUpdated}');
    print('==================');
  }
}