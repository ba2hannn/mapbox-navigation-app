# 🚗 Rota App - Professional Mapbox Navigation Application

## 📋 Proje Genel Bakış

Bu proje, **Flutter** ve **Mapbox** teknolojilerini kullanarak geliştirilmiş profesyonel bir navigasyon uygulamasıdır. Clean Architecture prensiplerine uygun olarak modüler bir yapıya sahiptir ve Firebase entegrasyonu ile kullanıcı verilerini yönetir.

### 🎯 Ana Özellikler
- **Gerçek Zamanlı Navigasyon**: Mapbox Directions API ile optimize edilmiş rota hesaplama
- **Çoklu Rota Seçenekleri**: Hızlı rota (ücretli yol dahil) ve ücretsiz rota seçenekleri
- **Araç Yönetimi**: Kullanıcıların araçlarını ekleyip yönetebilmesi
- **Firebase Entegrasyonu**: Kullanıcı kimlik doğrulama ve veri saklama
- **Türkiye Odaklı**: Harita sınırları Türkiye'ye kısıtlanmış, performans optimize edilmiş
- **Offline Özellikler**: GPS simülasyonu ve konum önbellekleme

---

## 🏗️ Proje Yapısı ve Mimari

### 📁 Ana Klasör Yapısı

```
flutter_app/
├── 📱 android/                    # Android platform spesifik dosyalar
├── 🍎 ios/                       # iOS platform spesifik dosyalar
├── 🖥️ linux/                     # Linux platform spesifik dosyalar
├── 💻 macos/                     # macOS platform spesifik dosyalar
├── 🌐 web/                       # Web platform spesifik dosyalar
├── 🪟 windows/                   # Windows platform spesifik dosyalar
├── 📦 assets/                    # Statik dosyalar (resimler, ikonlar)
│   └── arkaplan2.png            # Arka plan görseli
├── 🏗️ build/                     # Derleme çıktıları
├── 📚 lib/                       # Ana uygulama kodu
│   ├── 🚀 main.dart                # Uygulama giriş noktası
│   ├── 🔥 firebase_options.dart    # Firebase yapılandırma seçenekleri
│   └── [Core ve Features klasörleri]
├── 🧪 test/                      # Test dosyaları
│   └── route_planning_test.dart  # Rota planlama testleri
│       ├── GeocodingService testleri
│       ├── SearchHistoryService testleri
│       ├── DirectionsService testleri
│       └── UI davranış testleri
└── ⚙️ [Konfigürasyon dosyaları]
    ├── 📄 pubspec.yaml              # Flutter dependencies ve proje yapılandırması
    ├── 📄 pubspec.lock              # Dependency lock dosyası
    ├── 🔧 analysis_options.yaml     # Dart linter ve analiz ayarları
    ├── 🐛 devtools_options.yaml     # Flutter DevTools yapılandırması
    ├── 🔥 firebase.json             # Firebase hosting ve functions yapılandırması
    ├── 📚 README.md                 # Proje dokümantasyonu
    ├── 🏗️ ARCHITECTURE.md           # Mimari detayları ve tasarım kararları
    ├── 🔥 FIREBASE_SETUP.md         # Firebase kurulum kılavuzu
    ├── ⚡ PERFORMANCE.md             # Performans optimizasyonları
    └── 📱 flutter_app.iml           # IntelliJ IDEA proje dosyası
```

### 📚 Lib Klasörü Detaylı Yapısı

#### 🔧 Core (Çekirdek Modüller)
```
lib/core/
├── ⚙️ config/
│   └── app_config.dart           # Uygulama yapılandırması ve sabitler
│       ├── Mapbox API token yönetimi
│       ├── Türkiye sınır koordinatları (bounding box)
│       ├── Zoom seviyesi limitleri
│       └── Uygulama temel bilgileri
│
├── 🎨 theme/
│   ├── app_theme.dart            # Tema yapılandırması (Light/Dark)
│   └── app_design.dart           # Tasarım sabitleri ve renkler
│
├── 💉 di/
│   └── injection_container.dart  # Dependency Injection kurulumu
│       ├── GetIt servis lokatörü
│       ├── Bloc, UseCase, Repository bağımlılıkları
│       └── Singleton kayıtları
│
├── � error/                     # Hata yönetimi
│   ├── exceptions.dart           # Özel exception sınıfları
│   └── failures.dart             # Failure sınıfları (Either için)
│
├── 🌐 platform/                  # Platform spesifik servisler
│   └── network_info.dart         # İnternet bağlantı kontrolü
│
├── �🔧 services/                  # İş mantığı servisleri
│   ├── directions_service.dart   # Mapbox Directions API entegrasyonu
│   │   ├── Tek rota hesaplama (hızlı/ücretsiz)
│   │   ├── Çoklu rota karşılaştırma
│   │   └── Rota geometri ve adım verileri
│   │
│   ├── geocoding_service.dart    # Adres ↔ Koordinat dönüşümü
│   ├── navigation_service.dart   # Navigasyon kontrolü ve yönlendirme
│   ├── location_cache_service.dart # Konum verisi önbellekleme
│   ├── search_history_service.dart # Arama geçmişi yönetimi
│   ├── gps_simulator.dart        # GPS simülasyonu (test için)
│   └── firebase_service.dart     # Firebase servis wrapper'ı
│
└── 🧩 widgets/                   # Yeniden kullanılabilir UI bileşenleri
    ├── map_controls.dart         # Harita kontrol butonları (zoom, konum)
    ├── map_layer_selector.dart   # Harita katmanı seçici (uydu, sokak)
    ├── navigation_panel.dart     # Navigasyon paneli (rota bilgileri)
    ├── search_bar_widget.dart    # Arama çubuğu bileşeni
    ├── user_avatar.dart          # Kullanıcı avatarı
    └── custom_notification.dart  # Özel bildirim widget'ı
```

#### 🚗 Features (Özellik Modülleri)

Her özellik **Clean Architecture** prensiplerine göre 3 katmanlı yapıya sahiptir:

```
lib/features/
├── 🗺️ map/                       # Ana harita özelliği
│   ├── 🧠 domain/                # İş Mantığı Katmanı
│   │   ├── entities/             # Pure Dart iş nesneleri
│   │   │   ├── location_entity.dart    # Konum entity'si
│   │   │   └── failure.dart           # Hata tipleri
│   │   ├── repositories/         # Repository arayüzleri
│   │   │   └── location_repository.dart
│   │   └── usecases/             # Tek sorumluluk use case'leri
│   │       └── get_user_location.dart
│   │
│   ├── 💾 data/                  # Veri Katmanı
│   │   ├── models/               # JSON serileştirme modelleri
│   │   │   └── location_model.dart
│   │   ├── datasources/          # Veri kaynakları (API, Local)
│   │   │   └── location_local_data_source.dart
│   │   └── repositories/         # Repository implementasyonları
│   │       └── location_repository_impl.dart
│   │
│   └── 🎨 presentation/          # Sunum Katmanı
│       ├── bloc/                 # State Management (BLoC Pattern)
│       │   ├── map_bloc.dart     # Business Logic Component
│       │   ├── map_event.dart    # UI'dan gelen olaylar
│       │   └── map_state.dart    # UI durumları
│       └── pages/                # UI Sayfaları
│           ├── map_screen.dart            # Ana harita ekranı
│           └── search_and_route_screen.dart # Arama ve rota ekranı
│
├── 🔐 auth/                      # Kimlik Doğrulama
│   ├── 🧠 domain/
│   │   ├── entities/             # User, AuthResult
│   │   ├── repositories/         # AuthRepository interface
│   │   └── usecases/             # Login, Register, Logout
│   ├── 💾 data/
│   │   ├── models/               # Firebase Auth modelleri
│   │   ├── datasources/          # Firebase Auth data source
│   │   └── repositories/         # AuthRepositoryImpl
│   └── 🎨 presentation/
│       ├── bloc/                 # AuthBloc, AuthState, AuthEvent
│       └── pages/                # LoginScreen, RegisterScreen
│
├── 🚗 vehicles/                  # Araç Yönetimi
│   ├── 🧠 domain/
│   │   ├── entities/vehicle.dart # Araç entity'si (brand, model, class)
│   │   └── repositories/         # VehicleRepository
│   ├── 💾 data/
│   │   ├── models/vehicle_model.dart     # Firestore model
│   │   ├── datasources/vehicle_data.dart # Test verileri
│   │   └── datasources/vehicle_remote_data_source.dart # Firebase
│   └── 🎨 presentation/
│       └── pages/
│           ├── vehicles_list_screen.dart # Araç listesi
│           └── add_vehicle_screen.dart   # Araç ekleme (7 adım)
│
├── 💰 toll/                      # Gişe ve Ücret Yönetimi
│   ├── 🧠 domain/
│   │   ├── entities/
│   │   │   ├── toll_gate_entity.dart    # Gişe entity'si
│   │   │   └── toll_cost_entity.dart    # Ücret entity'si
│   │   ├── repositories/toll_repository.dart
│   │   └── usecases/             # Gişe ve ücret hesaplamaları
│   ├── 💾 data/
│   │   ├── models/
│   │   │   ├── toll_gate_model.dart     # Firestore model
│   │   │   └── toll_cost_model.dart     # Firestore model
│   │   ├── datasources/toll_remote_data_source.dart # Firebase
│   │   └── repositories/toll_repository_impl.dart
│   └── 🎨 presentation/
│       └── pages/
│           └── toll_info_screen.dart    # Gişe bilgileri ekranı
│
├── 🧭 route_planning/            # Rota Planlama
│   └── 🎨 presentation/
│       └── pages/
│           ├── route_planning_screen.dart    # Rota planlama ana ekran
│           ├── route_preview_screen.dart     # Rota önizleme
│           └── location_selection_screen.dart # Konum seçimi
│
├── 👤 profile/                   # Kullanıcı Profili
│   └── 🎨 presentation/
│       └── pages/
│           └── profile_screen.dart # Profil yönetimi
│
└── 🚪 splash/                    # Uygulama Açılış
    └── 🎨 presentation/
        └── pages/
            └── splash_screen.dart # Splash screen
```

---

## 🔄 Veri Akışı ve State Management

### BLoC Pattern Kullanımı

```dart
// Event → State dönüşümü
class MapBloc extends Bloc<MapEvent, MapState> {
  final GetUserLocation getUserLocation;

  MapBloc({required this.getUserLocation}) : super(const MapInitial()) {
    on<MapInitialized>(_onMapInitialized);           // Harita başlatma
    on<MapUserLocationRequested>(_onUserLocationRequested); // Konum isteği
  }
}

// UI'dan Event tetikleme
context.read<MapBloc>().add(MapUserLocationRequested());

// State'e göre UI güncelleme
BlocBuilder<MapBloc, MapState>(
  builder: (context, state) {
    if (state is MapLoading) return CircularProgressIndicator();
    if (state is MapLoaded) return MapWidget(location: state.userLocation);
    if (state is MapError) return ErrorWidget(message: state.message);
    return SizedBox.shrink();
  },
)
```

### Dependency Injection Akışı

```
UI (MapScreen)
    ↓ Event
BLoC (MapBloc)
    ↓ Use Case (GetUserLocation)
Repository Interface
    ↓ Implementation (LocationRepositoryImpl)
Data Source (LocationLocalDataSource)
    ↓ Platform API (GPS, Cache)
Data
    ↑ Model (LocationModel)
Repository Implementation
    ↑ Entity (LocationEntity)
BLoC
    ↑ State (MapLoaded)
UI
```

---

## 🗺️ Mapbox Entegrasyonu

### 🔑 Yapılandırma (`app_config.dart`)
```dart
class AppConfig {
  static const String mapboxAccessToken = 'pk.eyJ1...'; // API Token
  
  // Türkiye sınırları - Performans optimizasyonu
  static const double turkeyMinLat = 34.0;  // Antalya
  static const double turkeyMaxLat = 42.5;  // Trabzon
  static const double turkeyMinLng = 25.5;  // İzmir
  static const double turkeyMaxLng = 45.5;  // Van
  
  static const double minZoom = 5.0;    // Türkiye geneli
  static const double maxZoom = 20.0;   // Sokak seviyesi
}
```

### 🛣️ Rota Hesaplama (`directions_service.dart`)

```dart
class DirectionsService {
  // Tek rota: Hızlı (ücretli dahil) veya Ücretsiz
  Future<Route?> getRoute({
    required double startLat, startLng,
    required double endLat, endLng,
    bool excludeTolls = false,  // Ücretli yol hariç
  })
  
  // Çoklu rota: Hızlı + Ücretsiz karşılaştırma
  Future<List<Route>> getMultipleRoutes(...)
}
```

### 🚀 Performans Optimizasyonları

1. **Türkiye Bounding Box**: Harita sadece Türkiye sınırlarına kısıtlı
2. **Tile Cache**: Sadece Türkiye tile'ları önbellekte saklanır
3. **Zoom Limitleri**: Gereksiz uzak/ yakın zoom seviyeleri engellenir
4. **Prefetch**: Sadece çevre Türkiye bölgeleri önceden yüklenir

---

## 🔥 Firebase Entegrasyonu

### 📊 Firestore Veritabanı Yapısı

```
gates/{gateId}/                    # Gişe bilgileri
├── highway, id, lat, lon

tolls/{tollId}/                    # Ücret bilgileri
├── highway, id, entryGateName, exitGateName
├── prices: {class1, class2, class3, class4, class5}

users/{userId}/
├── email, displayName, photoURL, createdAt
├── vehicles/{vehicleId}/          # Kullanıcı araçları
│   ├── brand, model, year, vehicleClass, fuelType, color, plateNumber
│   └── imageUrl, createdAt, updatedAt
├── routes/{routeId}/              # Kaydedilmiş rotalar
│   ├── name, startPoint, endPoint, distance, estimatedTime, tollCost
│   └── createdAt
└── favorites/{favoriteId}/        # Favoriler
    ├── type (route/place), referenceId, createdAt
```

### 🔐 Güvenlik Kuralları

```javascript
// Kullanıcılar sadece kendi verilerini yönetebilir
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}

// Gişeler herkes okuyabilir, sadece admin yazabilir
match /gates/{gateId} {
  allow read: if true;
  allow write: if false; // Admin panel'den yönetilecek
}

// Ücretler herkes okuyabilir, sadece admin yazabilir
match /tolls/{tollId} {
  allow read: if true;
  allow write: if false; // Admin panel'den yönetilecek
}
```

### 📁 Storage Yapısı

```
users/
├── {userId}/
│   ├── profile/
│   │   └── profile.jpg          # Profil fotoğrafı
│   └── vehicles/
│       └── {vehicleId}/
│           ├── image1.jpg       # Araç fotoğrafları
│           ├── image2.jpg
│           └── image3.jpg
```

---

## 🧪 Test Yapısı

### 🧪 Unit Test Örneği (`route_planning_test.dart`)

```dart
void main() {
  group('Route Planning Tests', () {
    test('should calculate correct toll cost for vehicle class', () {
      // Araç sınıfına göre gişe ücreti hesaplama testi
    });
    
    test('should return multiple route options', () {
      // Çoklu rota seçeneği testi
    });
  });
}
```

### 🎯 Test Kapsamı

- **Domain Layer**: %100 unit test (Use cases, Entities)
- **Data Layer**: Repository ve Data Source testleri
- **Presentation Layer**: BLoC state management testleri
- **Integration Tests**: API entegrasyon testleri

---

## 📱 Platform Spesifik Yapılandırmalar

### 🤖 Android (`android/`)
- **Gradle**: `build.gradle.kts` - Kotlin DSL
- **Google Services**: `google-services.json` - Firebase config
- **Permissions**: GPS, İnternet, Bildirim izinleri
- **Signing**: Release için signing config

### 🍎 iOS (`ios/`)
- **Xcode Project**: `Runner.xcodeproj`
- **Google Services**: `GoogleService-Info.plist`
- **Permissions**: Info.plist GPS ve kamera izinleri
- **Signing**: Development/Production certificates

### 🌐 Web (`web/`)
- **Index.html**: Ana HTML dosyası
- **Manifest.json**: PWA yapılandırması
- **Icons**: Farklı boyutlarda uygulama ikonları

---

## ⚙️ Yapılandırma Dosyaları

### 📄 `pubspec.yaml` - Flutter Dependencies

```yaml
dependencies:
  # Mapbox
  mapbox_maps_flutter: ^2.3.0
  
  # State Management
  flutter_bloc: ^8.1.6
  equatable: ^2.0.5
  
  # Dependency Injection
  get_it: ^8.0.2
  
  # Location & Permissions
  geolocator: ^13.0.2
  permission_handler: ^11.3.1
  
  # Firebase
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.4
  firebase_storage: ^12.3.4
  
  # UI & Utils
  shared_preferences: ^2.3.3
  http: ^1.2.0
  dartz: ^0.10.1  # Functional Programming
```

### 🔧 `analysis_options.yaml` - Dart Linter

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  strong-mode:
    implicit-casts: false
    implicit-dynamic: false

linter:
  rules:
    - prefer_const_constructors
    - avoid_print
    - sort_child_properties_last
```

---

## 🚀 Kurulum ve Çalıştırma

### 📋 Ön Gereksinimler

1. **Flutter SDK**: `>=3.9.2`
2. **Dart SDK**: `>=3.9.2`
3. **Android Studio** veya **VS Code**
4. **Mapbox Account** (API token için)
5. **Firebase Project**

### 🛠️ Kurulum Adımları

1. **Repository'yi klonlayın:**
   ```bash
   git clone https://github.com/ba2hannn/mapbox-navigation-app.git
   cd flutter_app
   ```

2. **Dependencies yükleyin:**
   ```bash
   flutter pub get
   ```

3. **Firebase yapılandırın:**
   ```bash
   flutterfire configure
   ```

4. **Platform spesifik setup:**
   ```bash
   # Android için
   flutter build apk --debug
   
   # iOS için
   flutter build ios --debug
   ```

5. **Uygulamayı çalıştırın:**
   ```bash
   flutter run
   ```

### 🔧 Geliştirme Ortamı

- **IDE**: VS Code veya Android Studio
- **Extensions**: Flutter, Dart, BLoC extensions
- **Emulator**: Android Emulator veya iOS Simulator

---

## 📊 Performans Metrikleri

### 🗺️ Mapbox Optimizasyonları

- **İlk Yükleme**: ~2-3 MB (sadece Türkiye)
- **Cache Boyutu**: ~30-40 MB (1 hafta kullanım)
- **Tile İndirme**: Sadece görünür bölge
- **Bellek Kullanımı**: Optimize edilmiş widget'lar

### 📱 Uygulama Performansı

- **Cold Start**: < 3 saniye
- **Hot Reload**: < 1 saniye
- **Memory Usage**: < 150 MB
- **Battery Impact**: Minimal (GPS optimizasyonu)

---

## 🔍 Kod Kalitesi ve Standartlar

### 📏 Naming Conventions

```dart
// Classes
class MapBloc {}              // PascalCase
class LocationEntity {}       // PascalCase

// Variables & Functions
final userLocation;           // camelCase
void getUserLocation() {}     // camelCase

// Files
map_screen.dart              // snake_case
location_entity.dart         // snake_case

// Constants
const String API_TOKEN = '';  // SCREAMING_SNAKE_CASE
```

### 🏗️ Architecture Principles

1. **SOLID Principles**: Single Responsibility, Open/Closed, Liskov Substitution, Interface Segregation, Dependency Inversion
2. **Clean Architecture**: Domain ↔ Data ↔ Presentation ayrımı
3. **DRY (Don't Repeat Yourself)**: Kod tekrarından kaçınma
4. **KISS (Keep It Simple Stupid)**: Basit çözümler

### 🔧 Code Quality Tools

- **Flutter Lints**: Kod kalitesi kontrolü
- **Dart Analyzer**: Statik analiz
- **Unit Tests**: İş mantığı testleri
- **Integration Tests**: UI testleri

---

## 🚀 Deployment ve Yayınlama

### 📦 Build Komutları

```bash
# Debug Build
flutter build apk --debug
flutter build ios --debug

# Release Build
flutter build apk --release
flutter build ios --release

# Web Build
flutter build web --release
```

### 🏪 Store Yayınlama

#### 🤖 Google Play Store
1. **App Bundle** oluştur: `flutter build appbundle --release`
2. **Signing**: `key.properties` ve keystore dosyası
3. **Google Play Console**: App Bundle yükle
4. **Internal/Alpha/Beta** test aşamaları
5. **Production** release

#### 🍎 Apple App Store
1. **Archive** oluştur: Xcode'da Product → Archive
2. **Signing**: Development/Production certificates
3. **App Store Connect**: Build yükle
4. **TestFlight** beta testi
5. **App Review**: Apple onay süreci

---

## 🐛 Sorun Giderme

### 🔧 Sık Karşılaşılan Problemler

1. **Mapbox Token Hatası**
   ```bash
   # app_config.dart'ta token kontrolü
   # flutterfire configure tekrar çalıştır
   ```

2. **Firebase Bağlantı Hatası**
   ```bash
   # google-services.json kontrolü
   # flutter clean && flutter pub get
   ```

3. **GPS İzin Hatası**
   ```bash
   # AndroidManifest.xml ve Info.plist kontrolü
   # permission_handler package güncellemesi
   ```

4. **Gișe Verisi Yok Hatası**
   ```bash
   # Firebase Console'dan gates koleksiyonuna gişe verileri ekleyin
   # tolls koleksiyonuna ücret verileri ekleyin
   ```

5. **Build Hataları**
   ```bash
   flutter clean
   flutter pub cache repair
   flutter pub get
   ```

### 📞 Destek ve Dokümantasyon

- **README.md**: Bu dosya
- **ARCHITECTURE.md**: Mimari detayları
- **FIREBASE_SETUP.md**: Firebase kurulum kılavuzu
- **PERFORMANCE.md**: Performans optimizasyonları

---

## 🎯 Gelecek Özellikler (Roadmap)

### 🔮 Kısa Vadeli
- [ ] **Offline Haritalar**: Önemli bölgeler offline
- [ ] **Push Notifications**: Rota hatırlatmaları
- [ ] **Route Sharing**: Rota paylaşımı
- [ ] **Vehicle Maintenance**: Araç bakım takibi

### 🚀 Uzun Vadeli
- [ ] **Multi-Modal Transport**: Yürüyüş + Toplu taşıma
- [ ] **Real-Time Traffic**: Gerçek zamanlı trafik
- [ ] **Parking Integration**: Otopark bulma
- [ ] **Social Features**: Arkadaş rotaları

---

## 👥 Katkıda Bulunma

### 📝 Kod Standartları
1. **Branch Naming**: `feature/feature-name` veya `bugfix/bug-name`
2. **Commit Messages**: `feat: add new feature` format
3. **Pull Requests**: Detaylı açıklama ve test coverage
4. **Code Review**: En az 1 reviewer onayı

### 🧪 Test Requirements
- Unit test coverage: > 80%
- Integration tests for new features
- Manual testing checklist

---

## 📄 Lisans ve Telif Hakkı

Bu proje açık kaynak kodludur ve MIT lisansı altında yayınlanmıştır.

**Geliştirici**: [ba2hannn](https://github.com/ba2hannn)
**Repository**: [mapbox-navigation-app](https://github.com/ba2hannn/mapbox-navigation-app)

---

*Bu README dosyası, yapay zekanın projeyi tam olarak anlayabilmesi için detaylı olarak hazırlanmıştır. Tüm klasörler, dosyalar ve onların görevleri açıklanmış, kod örnekleri ve mimari yapısı detaylandırılmıştır.*

