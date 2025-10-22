import 'package:shared_preferences/shared_preferences.dart';

/// Aylık reset mantığını yöneten sınıf
/// Reklam sistemi için bedava arama haklarını aylık olarak resetler
class MonthlyResetManager {
  static const String _resetDateKey = 'monthly_reset_date';
  static const String _remainingFreeSearchesKey = 'remaining_free_searches';
  static const String _watchedAdsThisMonthKey = 'watched_ads_this_month';

  static const int _freeSearchesPerMonth = 5;

  final SharedPreferences _prefs;

  MonthlyResetManager(this._prefs);

  /// Aylık bedava arama hakkı sayısı
  int get freeSearchesPerMonth => _freeSearchesPerMonth;

  /// Kalan bedava arama sayısı
  int get remainingFreeSearches =>
      _prefs.getInt(_remainingFreeSearchesKey) ?? _freeSearchesPerMonth;

  set remainingFreeSearches(int value) {
    _prefs.setInt(_remainingFreeSearchesKey, value);
  }

  /// Bu ay izlenen reklam sayısı
  int get watchedAdsThisMonth =>
      _prefs.getInt(_watchedAdsThisMonthKey) ?? 0;

  set watchedAdsThisMonth(int value) {
    _prefs.setInt(_watchedAdsThisMonthKey, value);
  }

  /// Sonraki ayın başlangıç tarihini hesapla
  DateTime getNextMonthStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }

  /// Mevcut ayın başlangıç tarihini al
  DateTime getCurrentMonthStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  /// Aylık reset kontrolü ve gerekirse reset işlemi
  Future<bool> checkAndResetIfNeeded() async {
    final savedResetDateStr = _prefs.getString(_resetDateKey);

    if (savedResetDateStr == null) {
      // İlk kez, yeni reset tarihi ayarla
      await _initializeMonthlyData();
      return false; // Reset olmadı
    }

    final savedResetDate = DateTime.parse(savedResetDateStr);
    final now = DateTime.now();

    if (now.isAfter(savedResetDate) || now.isAtSameMomentAs(savedResetDate)) {
      // Reset zamanı geldi
      await _performMonthlyReset();
      return true; // Reset yapıldı
    }

    return false; // Reset gerekmedi
  }

  /// Aylık verileri başlat
  Future<void> _initializeMonthlyData() async {
    final nextResetDate = getNextMonthStart();
    await _prefs.setString(_resetDateKey, nextResetDate.toIso8601String());
    await _prefs.setInt(_remainingFreeSearchesKey, _freeSearchesPerMonth);
    await _prefs.setInt(_watchedAdsThisMonthKey, 0);
  }

  /// Aylık reset işlemini gerçekleştir
  Future<void> _performMonthlyReset() async {
    final nextResetDate = getNextMonthStart();

    // Reset tarihini güncelle
    await _prefs.setString(_resetDateKey, nextResetDate.toIso8601String());

    // Hakları resetle
    await _prefs.setInt(_remainingFreeSearchesKey, _freeSearchesPerMonth);

    // Reklam sayısını sıfırla
    await _prefs.setInt(_watchedAdsThisMonthKey, 0);
  }

  /// Arama izni kontrolü
  Future<bool> canPerformSearch() async {
    // Önce aylık reset kontrolü yap
    await checkAndResetIfNeeded();

    // Kalan hak kontrolü
    return remainingFreeSearches > 0;
  }

  /// Arama sonrası hak güncelleme
  Future<void> onSearchPerformed() async {
    if (remainingFreeSearches > 0) {
      remainingFreeSearches = remainingFreeSearches - 1;
    }
  }

  /// Reklam izleme sonrası hak verme
  Future<void> onAdWatched() async {
    // Reklam izlendi, hak ver
    remainingFreeSearches = remainingFreeSearches + 1;

    // Bu ay izlenen reklam sayısını artır
    watchedAdsThisMonth = watchedAdsThisMonth + 1;
  }

  /// Aylık istatistikleri al
  Map<String, dynamic> getMonthlyStats() {
    return {
      'remainingFreeSearches': remainingFreeSearches,
      'watchedAdsThisMonth': watchedAdsThisMonth,
      'freeSearchesPerMonth': _freeSearchesPerMonth,
      'resetDate': _prefs.getString(_resetDateKey),
      'canSearch': remainingFreeSearches > 0,
    };
  }

  /// Debug için aylık verileri yazdır
  void printMonthlyStats() {
    final stats = getMonthlyStats();
    print('=== Monthly Reset Stats ===');
    print('Remaining Free Searches: ${stats['remainingFreeSearches']}');
    print('Watched Ads This Month: ${stats['watchedAdsThisMonth']}');
    print('Free Searches Per Month: ${stats['freeSearchesPerMonth']}');
    print('Reset Date: ${stats['resetDate']}');
    print('Can Search: ${stats['canSearch']}');
    print('===========================');
  }

  /// Test için manuel reset (sadece debug modda kullan)
  Future<void> forceResetForTesting() async {
    await _performMonthlyReset();
  }
}