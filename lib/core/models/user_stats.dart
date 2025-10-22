/// Kullanıcı istatistiklerini takip eden model sınıfı
/// Sadece kullanım verilerini içerir, kişisel bilgi içermez
class UserStats {
  /// Toplam rota arama sayısı
  int totalRouteSearches;

  /// Toplam kat edilen kilometre
  double totalKm;

  /// Aktif favori yer sayısı
  int activeFavorites;

  /// Tamamlanan rota sayısı
  int completedRoutes;

  /// Günlük arama sayıları (tarih: sayı)
  Map<String, int> dailySearches;

  /// Aylık kilometre verileri (ay: km)
  Map<String, double> monthlyKm;

  /// En çok gidilen destinasyonlar
  List<String> favoriteDestinations;

  /// Ortalama rota uzunluğu (km)
  double averageRouteLength;

  /// Tasarruf edilen toplam yakıt (litre)
  double fuelSaved;

  /// Son güncelleme tarihi
  DateTime lastUpdated;

  UserStats({
    this.totalRouteSearches = 0,
    this.totalKm = 0.0,
    this.activeFavorites = 0,
    this.completedRoutes = 0,
    Map<String, int>? dailySearches,
    Map<String, double>? monthlyKm,
    List<String>? favoriteDestinations,
    this.averageRouteLength = 0.0,
    this.fuelSaved = 0.0,
    DateTime? lastUpdated,
  }) :
    dailySearches = dailySearches ?? {},
    monthlyKm = monthlyKm ?? {},
    favoriteDestinations = favoriteDestinations ?? [],
    lastUpdated = lastUpdated ?? DateTime.now();

  /// JSON'dan UserStats oluştur
  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalRouteSearches: json['totalRouteSearches'] ?? 0,
      totalKm: (json['totalKm'] ?? 0.0).toDouble(),
      activeFavorites: json['activeFavorites'] ?? 0,
      completedRoutes: json['completedRoutes'] ?? 0,
      dailySearches: Map<String, int>.from(json['dailySearches'] ?? {}),
      monthlyKm: Map<String, double>.from(json['monthlyKm'] ?? {}),
      favoriteDestinations: List<String>.from(json['favoriteDestinations'] ?? []),
      averageRouteLength: (json['averageRouteLength'] ?? 0.0).toDouble(),
      fuelSaved: (json['fuelSaved'] ?? 0.0).toDouble(),
      lastUpdated: json['lastUpdated'] != null
        ? DateTime.parse(json['lastUpdated'])
        : DateTime.now(),
    );
  }

  /// UserStats'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'totalRouteSearches': totalRouteSearches,
      'totalKm': totalKm,
      'activeFavorites': activeFavorites,
      'completedRoutes': completedRoutes,
      'dailySearches': dailySearches,
      'monthlyKm': monthlyKm,
      'favoriteDestinations': favoriteDestinations,
      'averageRouteLength': averageRouteLength,
      'fuelSaved': fuelSaved,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// İki UserStats'i birleştir (Firebase sync için)
  UserStats merge(UserStats other) {
    // En yeni veriyi koru
    final merged = UserStats(
      totalRouteSearches: other.totalRouteSearches > totalRouteSearches
        ? other.totalRouteSearches : totalRouteSearches,
      totalKm: other.totalKm > totalKm ? other.totalKm : totalKm,
      activeFavorites: other.activeFavorites,
      completedRoutes: other.completedRoutes > completedRoutes
        ? other.completedRoutes : completedRoutes,
      dailySearches: {...dailySearches, ...other.dailySearches},
      monthlyKm: {...monthlyKm, ...other.monthlyKm},
      favoriteDestinations: [...favoriteDestinations, ...other.favoriteDestinations]
        ..toSet().toList(), // Duplicateleri kaldır
      averageRouteLength: other.averageRouteLength > 0
        ? other.averageRouteLength : averageRouteLength,
      fuelSaved: other.fuelSaved > fuelSaved ? other.fuelSaved : fuelSaved,
      lastUpdated: other.lastUpdated.isAfter(lastUpdated)
        ? other.lastUpdated : lastUpdated,
    );

    return merged;
  }

  /// Günlük istatistikleri hesapla
  Map<String, dynamic> getDailyStats(String date) {
    return {
      'searches': dailySearches[date] ?? 0,
      'km': monthlyKm[_getMonthKey(date)] ?? 0.0,
    };
  }

  /// Aylık istatistikleri hesapla
  Map<String, dynamic> getMonthlyStats(String monthKey) {
    return {
      'totalSearches': dailySearches.entries
        .where((entry) => entry.key.startsWith(monthKey))
        .fold(0, (sum, entry) => sum + entry.value),
      'totalKm': monthlyKm[monthKey] ?? 0.0,
      'completedRoutes': completedRoutes,
      'fuelSaved': fuelSaved,
    };
  }

  /// İstatistikleri sıfırla (test için)
  void reset() {
    totalRouteSearches = 0;
    totalKm = 0.0;
    activeFavorites = 0;
    completedRoutes = 0;
    dailySearches.clear();
    monthlyKm.clear();
    favoriteDestinations.clear();
    averageRouteLength = 0.0;
    fuelSaved = 0.0;
    lastUpdated = DateTime.now();
  }

  /// Bugünün tarih anahtarını al
  static String getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Bu ayın anahtarını al
  static String getCurrentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Verilen tarihin ay anahtarını al
  static String _getMonthKey(String date) {
    // date format: YYYY-MM-DD
    return date.substring(0, 7);
  }

  @override
  String toString() {
    return 'UserStats(totalRouteSearches: $totalRouteSearches, totalKm: $totalKm, activeFavorites: $activeFavorites, completedRoutes: $completedRoutes)';
  }
}