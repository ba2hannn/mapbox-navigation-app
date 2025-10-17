# Proje Yapısı ve Modüler Mimari

## 📁 Dosya Organizasyonu

### Core (Çekirdek Modüller)
```
core/
├── config/app_config.dart        # Mapbox API token ve sabitler
├── theme/app_theme.dart          # Tema yapılandırması (light/dark)
└── di/injection_container.dart   # Dependency injection kurulumu
```

### Features (Özellik Modülleri)
Her özellik kendi klasöründe, 3 katmanlı mimari ile organize edilmiştir:

```
features/map/
├── domain/                       # İş Mantığı Katmanı
│   ├── entities/                 # İş nesneleri (pure Dart)
│   │   ├── location_entity.dart  # Konum entity'si
│   │   └── failure.dart          # Hata tipleri
│   ├── repositories/             # Repository arayüzleri
│   │   └── location_repository.dart
│   └── usecases/                 # Use case'ler (tek sorumluluk)
│       └── get_user_location.dart
│
├── data/                         # Veri Katmanı
│   ├── models/                   # Veri modelleri
│   │   └── location_model.dart
│   ├── datasources/              # Veri kaynakları
│   │   └── location_local_data_source.dart
│   └── repositories/             # Repository implementasyonları
│       └── location_repository_impl.dart
│
└── presentation/                 # Sunum Katmanı
    ├── bloc/                     # State Management
    │   ├── map_bloc.dart         # Business Logic Component
    │   ├── map_event.dart        # Events
    │   └── map_state.dart        # States
    └── pages/                    # UI Sayfaları
        └── map_screen.dart
```

## 🔄 Veri Akışı

```
UI (MapScreen)
    ↓ Event
BLoC (MapBloc)
    ↓ Use Case
Repository Interface
    ↓ Implementation
Data Source
    ↓ API/Local
Data
    ↑ Model
Repository Implementation
    ↑ Entity
BLoC
    ↑ State
UI
```

## 🎯 Clean Architecture Avantajları

### 1. Bağımsızlık
- **Framework Bağımsızlığı**: İş mantığı Flutter'a bağlı değil
- **UI Bağımsızlığı**: UI değişirse domain etkilenmez
- **Database Bağımsızlığı**: Veri kaynağı değişebilir
- **Test Edilebilirlik**: Her katman bağımsız test edilebilir

### 2. Modülerlik
- Her özellik kendi klasöründe
- Yeni özellik eklemek kolay
- Kod çakışmaları minimum

### 3. Ölçeklenebilirlik
- Takım çalışmasına uygun
- Kod review kolay
- Paralel geliştirme mümkün

## 🔧 Yeni Özellik Ekleme Kılavuzu

### Örnek: "Favori Konumlar" Özelliği

#### 1. Domain Layer
```dart
// entities/favorite_location.dart
class FavoriteLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
}

// repositories/favorite_repository.dart
abstract class FavoriteRepository {
  Future<List<FavoriteLocation>> getFavorites();
  Future<void> addFavorite(FavoriteLocation location);
}

// usecases/get_favorites.dart
class GetFavorites {
  final FavoriteRepository repository;
  Future<List<FavoriteLocation>> call() => repository.getFavorites();
}
```

#### 2. Data Layer
```dart
// models/favorite_model.dart
class FavoriteModel extends FavoriteLocation {
  // JSON serialization
}

// datasources/favorite_local_data_source.dart
class FavoriteLocalDataSource {
  // SharedPreferences veya SQLite implementasyonu
}

// repositories/favorite_repository_impl.dart
class FavoriteRepositoryImpl implements FavoriteRepository {
  final FavoriteLocalDataSource dataSource;
  // Implementation
}
```

#### 3. Presentation Layer
```dart
// bloc/favorite_bloc.dart
class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  final GetFavorites getFavorites;
  // BLoC logic
}

// pages/favorites_screen.dart
class FavoritesScreen extends StatelessWidget {
  // UI implementation
}
```

#### 4. Dependency Injection
```dart
// core/di/injection_container.dart
void init() {
  // Bloc
  sl.registerFactory(() => FavoriteBloc(getFavorites: sl()));
  
  // Use cases
  sl.registerLazySingleton(() => GetFavorites(sl()));
  
  // Repository
  sl.registerLazySingleton<FavoriteRepository>(
    () => FavoriteRepositoryImpl(dataSource: sl()),
  );
  
  // Data source
  sl.registerLazySingleton<FavoriteLocalDataSource>(
    () => FavoriteLocalDataSourceImpl(),
  );
}
```

## 📝 Kod Standartları

### Dosya İsimlendirme
- `snake_case.dart` - Tüm dosyalar
- `feature_name_widget.dart` - Widget dosyaları
- `feature_name_bloc.dart` - BLoC dosyaları

### Sınıf İsimlendirme
- `PascalCase` - Tüm sınıflar
- `FeatureNameBloc` - BLoC sınıfları
- `FeatureNameRepository` - Repository'ler
- `FeatureNameDataSource` - Data source'lar

### Değişken İsimlendirme
- `camelCase` - Değişkenler ve fonksiyonlar
- `_privateVariable` - Private değişkenler
- `SCREAMING_SNAKE_CASE` - Sabitler

## 🧪 Test Yapısı

```
test/
├── core/
├── features/
│   └── map/
│       ├── domain/
│       │   └── usecases/
│       │       └── get_user_location_test.dart
│       ├── data/
│       │   └── repositories/
│       │       └── location_repository_impl_test.dart
│       └── presentation/
│           └── bloc/
│               └── map_bloc_test.dart
```

## 🚀 Deployment Checklist

### Android
- [ ] applicationId ayarlandı mı?
- [ ] Signing config yapıldı mı?
- [ ] ProGuard rules eklendi mi?
- [ ] Permissions kontrol edildi mi?
- [ ] Icon ve splash screen ayarlandı mı?

### iOS
- [ ] Bundle identifier ayarlandı mı?
- [ ] Signing & Capabilities yapıldı mı?
- [ ] Permissions kontrol edildi mi?
- [ ] Icon ve launch screen ayarlandı mı?
- [ ] App Store Connect kuruldu mu?

### Her İkisi İçin
- [ ] Version number güncellendi mi?
- [ ] Build number artırıldı mı?
- [ ] README.md güncellendi mi?
- [ ] CHANGELOG.md oluşturuldu mu?
- [ ] Privacy policy eklendi mi?

## 💡 İpuçları

1. **Always start with Domain** - İş mantığını önce tasarla
2. **Keep it simple** - Gereksiz karmaşıklıktan kaçın
3. **Write tests** - Özellikle domain layer'ı test et
4. **Use const constructors** - Performance için önemli
5. **Follow DRY principle** - Kod tekrarından kaçın
6. **Document your code** - Yorumları ihmal etme
7. **Use meaningful names** - Değişken isimleri açıklayıcı olsun

## 📚 Önerilen Kaynaklar

- Clean Architecture - Robert C. Martin
- Flutter & Dart - The Complete Guide (Udemy)
- BLoC Pattern Documentation
- Flutter Architecture Samples (GitHub)
