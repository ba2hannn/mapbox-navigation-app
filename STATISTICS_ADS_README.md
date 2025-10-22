# RotaApp - İstatistikler ve Reklam Sistemi Geliştirme Rehberi

## 📊 Gerçek İstatistikler Sistemi

### Mevcut Durum
Profil sayfasında şu anda sahte istatistikler gösteriliyor:
- Rota sayısı: 23 (sabit)
- Km: 145 (sabit) 
- Favori sayısı: 12 (sabit)

### Hedeflenen Sistem

#### 1. Gerçek İstatistikler
Aşağıdaki gerçek verileri takip edeceğiz:

**Temel İstatistikler:**
- **Toplam Rota Araması**: Kullanıcının kaç kez rota arattığı
- **Toplam Km**: Tüm rotalarda kat edilen toplam mesafe
- **Aktif Favoriler**: Şu anda kaydedilmiş favori yer sayısı
- **Tamamlanan Rotalar**: Başarıyla bitirilen rota sayısı

**Detaylı Analiz Verileri:**
- **Günlük/Haftalık/Aylık kullanım istatistikleri**
- **En çok kullanılan araç bilgileri**
- **Favori destinasyonlar**
- **Ortalama rota uzunluğu**
- **Yakıt tasarrufu miktarı**

#### 2. Veri Saklama Stratejisi

**Lokal Depolama (SharedPreferences):**
```dart
// Özel bilgi İÇERMEYECEK veriler
class UserStats {
  int totalRouteSearches = 0;      // Toplam rota araması
  double totalKm = 0.0;            // Toplam km
  int activeFavorites = 0;         // Aktif favoriler
  int completedRoutes = 0;         // Tamamlanan rotalar
  
  // Zaman bazlı veriler
  Map<String, int> dailySearches = {};    // "2024-01-01": 5
  Map<String, double> monthlyKm = {};     // "2024-01": 145.5
  
  // Analiz verileri
  List<String> favoriteDestinations = [];  // En çok gidilen yerler
  double averageRouteLength = 0.0;        // Ortalama rota uzunluğu
  double fuelSaved = 0.0;                 // Tasarruf edilen yakıt (litre)
}
```

**Firebase Depolama (Analytics için):**
```dart
// Sadece email ile ilişkilendirilmiş, anonim veriler
class FirebaseAnalyticsData {
  String userEmail;  // Hash edilmiş veya anonim ID
  Map<String, dynamic> stats;
  DateTime lastUpdated;
  
  // Özel bilgi İÇERMEZ:
  // - Konum verileri
  // - Kişisel bilgiler
  // - Finansal veriler
  // - Sadece kullanım istatistikleri
}
```

#### 3. İstatistik Güncelleme Mantığı

**Rota Araması Yapıldığında:**
```dart
void onRouteSearch() {
  // Lokal güncelleme
  userStats.totalRouteSearches++;
  userStats.dailySearches[today] = (userStats.dailySearches[today] ?? 0) + 1;
  
  // Firebase'e gönder (async, ana akışı bloklamaz)
  analyticsService.logRouteSearch(userEmail, routeData);
}
```

**Rota Tamamlandığında:**
```dart
void onRouteCompleted(Route route) {
  userStats.completedRoutes++;
  userStats.totalKm += route.distanceKm;
  userStats.monthlyKm[currentMonth] += route.distanceKm;
  
  // Yakıt tasarrufu hesaplama
  double fuelSaved = calculateFuelSavings(route);
  userStats.fuelSaved += fuelSaved;
}
```

## 📱 Reklam Sistemi

### Sistem Gereksinimleri

#### 1. Reklam Kütüphanesi
```yaml
# pubspec.yaml
dependencies:
  google_mobile_ads: ^3.0.0
  # veya
  admob_flutter: ^2.0.0
  # veya  
  facebook_audience_network: ^1.0.0
```

#### 2. Reklam Türleri
- **Interstitial Ads**: Rota arama sonrası gösterilecek tam ekran reklam
- **Rewarded Ads**: Kullanıcının izleyip ödül kazanacağı reklam
- **Banner Ads**: Profil sayfasında gösterilecek banner reklam

### Reklam Mantığı

#### 1. Kullanım Limiti Sistemi
```dart
class AdSystem {
  // Bedava kullanım hakkı
  int freeSearchesPerMonth = 5;
  
  // Reklam izleme sonrası kazanılacak hak
  int searchesPerAd = 1;
  
  // Aylık reset tarihi
  DateTime monthlyResetDate;
  
  // Kullanıcının mevcut durumu
  int remainingFreeSearches = 5;
  int watchedAdsThisMonth = 0;
}
```

#### 2. Kullanım Akışı

**Rota Arama İsteği Geldiğinde:**
```dart
Future<bool> canPerformRouteSearch() async {
  // 1. Bedava hak kontrolü
  if (remainingFreeSearches > 0) {
    remainingFreeSearches--;
    return true;
  }
  
  // 2. Reklam izleme kontrolü
  if (await showRewardedAd()) {
    // Reklam başarıyla izlendi
    remainingFreeSearches += searchesPerAd;
    watchedAdsThisMonth++;
    return true;
  }
  
  // 3. Hak kalmadıysa false
  return false;
}
```

**Aylık Reset:**
```dart
void checkMonthlyReset() {
  if (DateTime.now().isAfter(monthlyResetDate)) {
    // Yeni ay başladı
    remainingFreeSearches = freeSearchesPerMonth;
    watchedAdsThisMonth = 0;
    monthlyResetDate = getNextMonthStart();
  }
}
```

### Reklam Entegrasyonu

#### 1. AdMob Kurulumu
```dart
// main.dart
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
  
  // Test cihaz ID'leri
  MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      testDeviceIds: ['TEST_DEVICE_ID_HERE'],
    ),
  );
  
  runApp(MyApp());
}
```

#### 2. Rewarded Ad Implementation
```dart
class AdService {
  RewardedAd? _rewardedAd;
  
  Future<bool> loadRewardedAd() async {
    return await RewardedAd.load(
      adUnitId: Platform.isAndroid 
        ? 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'
        : 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad failed to load: $error');
        },
      ),
    );
  }
  
  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) return false;
    
    bool rewardEarned = false;
    
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewardEarned = true;
        // Kullanıcıya ödül ver
      },
    );
    
    return rewardEarned;
  }
}
```

#### 3. UI Entegrasyonu

**Reklam Gerekli Dialog:**
```dart
void showAdRequiredDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Reklam İzleyin'),
      content: Text(
        'Bu ayki 5 bedava arama hakkınızı kullandınız. '
        '1 reklam izleyerek 1 arama hakkı kazanabilirsiniz.'
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            bool success = await adService.showRewardedAd();
            if (success) {
              // Arama sayfasına yönlendir
              performRouteSearch();
            }
          },
          child: Text('Reklam İzle'),
        ),
      ],
    ),
  );
}
```

## 🔄 Aylık Reset Sistemi

### Zaman Yönetimi
```dart
class MonthlyResetManager {
  static const String RESET_DATE_KEY = 'monthly_reset_date';
  static const String REMAINING_SEARCHES_KEY = 'remaining_free_searches';
  
  DateTime getNextMonthStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }
  
  Future<void> checkAndResetIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final savedResetDate = prefs.getString(RESET_DATE_KEY);
    
    if (savedResetDate == null) {
      // İlk kez, yeni reset tarihi ayarla
      await prefs.setString(RESET_DATE_KEY, getNextMonthStart().toIso8601String());
      await prefs.setInt(REMAINING_SEARCHES_KEY, 5);
      return;
    }
    
    final resetDate = DateTime.parse(savedResetDate);
    if (DateTime.now().isAfter(resetDate)) {
      // Reset zamanı geldi
      await prefs.setString(RESET_DATE_KEY, getNextMonthStart().toIso8601String());
      await prefs.setInt(REMAINING_SEARCHES_KEY, 5);
      
      // Firebase'e aylık rapor gönder
      await analyticsService.logMonthlyReset(userEmail, collectedStats);
    }
  }
}
```

## 📋 Geliştirme Adımları

### Faz 1: Temel İstatistikler
1. ✅ `UserStats` sınıfını oluştur
2. ✅ SharedPreferences ile lokal saklama
3. ✅ Profil sayfasında gerçek verileri göster
4. ✅ Rota arama/tamamlama olaylarında güncelleme

### Faz 2: Firebase Analytics
1. ✅ Firebase koleksiyonu oluştur (`user_analytics`)
2. ✅ Email hash ile anonim veri saklama
3. ✅ Günlük/haftalık raporlar

### Faz 3: Reklam Sistemi
1. ✅ AdMob hesabı ve uygulama kurulumu
2. ✅ Rewarded ad entegrasyonu
3. ✅ Kullanım limiti kontrolü
4. ✅ Aylık reset sistemi

### Faz 4: Gelişmiş Özellikler
1. ✅ Detaylı analiz dashboard'u
2. ✅ Kullanım trendleri grafikleri
3. ✅ Ödül sistemi geliştirmeleri

## 🔒 Güvenlik ve Gizlilik

### Veri Koruma
- **Hiçbir kişisel konum verisi** saklanmaz
- **Email sadece hash edilmiş** şekilde kullanılır
- **Firebase verileri anonim** olarak toplanır
- **Lokal veriler cihazda kalır**

### GDPR Uyumluluğu
- Kullanıcı onaylı veri toplama
- Veri silme hakkı
- Şeffaf kullanım politikası

## 🧪 Test Senaryoları

### İstatistik Testleri
- [ ] Rota arama sonrası sayı artmalı
- [ ] Km hesaplaması doğru olmalı
- [ ] Favori ekleme/çıkarma doğru yansımalı

### Reklam Testleri
- [ ] 5 bedava arama sonrası reklam dialog'u gösterilmeli
- [ ] Reklam izleme sonrası hak kazanılmalı
- [ ] Aylık reset doğru çalışmalı

### Firebase Testleri
- [ ] Veri anonim olarak gönderilmeli
- [ ] Ağ hatasında lokal veri korunmalı
- [ ] Bulk upload doğru çalışmalı

## 📊 Firebase Veri Yapısı

```json
{
  "user_analytics": {
    "user_hash": "abc123def456",
    "stats": {
      "total_searches": 25,
      "total_km": 145.5,
      "completed_routes": 18,
      "last_updated": "2024-01-15T10:30:00Z"
    },
    "monthly_data": {
      "2024-01": {
        "searches": 25,
        "km": 145.5,
        "ads_watched": 3
      }
    }
  }
}
```

Bu sistem kullanıcının gizliliğini korurken uygulama kullanımını analiz etmemizi sağlayacak.</content>
<parameter name="filePath">/home/ba2hann/Masaüstü/oguz_rotaapp/flutter_app/STATISTICS_ADS_README.md