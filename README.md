# Rota App - Mapbox Harita Uygulaması

Profesyonel, modüler ve ölçeklenebilir bir Mapbox harita uygulaması.

## 🏗️ Mimari

Bu proje **Clean Architecture** prensiplerine göre tasarlanmıştır:

```
lib/
├── core/                          # Çekirdek katman
│   ├── config/                    # Uygulama yapılandırması
│   │   └── app_config.dart       # Mapbox token ve ayarlar
│   ├── theme/                     # Tema yapılandırması
│   │   └── app_theme.dart        # Light/Dark tema
│   └── di/                        # Dependency Injection
│       └── injection_container.dart
│
└── features/                      # Özellikler (Feature-based)
    └── map/                       # Harita özelliği
        ├── data/                  # Data Layer
        │   ├── datasources/       # Veri kaynakları
        │   ├── models/            # Data modelleri
        │   └── repositories/      # Repository implementasyonları
        │
        ├── domain/                # Domain Layer (İş Mantığı)
        │   ├── entities/          # İş nesneleri
        │   ├── repositories/      # Repository interface'leri
        │   └── usecases/          # Use case'ler
        │
        └── presentation/          # Presentation Layer (UI)
            ├── bloc/              # State Management (BLoC)
            └── pages/             # Ekranlar
```

## 🔑 Özellikler

- ✅ **Mapbox entegrasyonu** - Yüksek kaliteli harita görünümü
- ✅ **Kullanıcı konumu** - Gerçek zamanlı konum takibi
- ✅ **Clean Architecture** - Modüler ve test edilebilir yapı
- ✅ **BLoC Pattern** - Profesyonel state management
- ✅ **Dependency Injection** - Gevşek bağlı mimari
- ✅ **Dark/Light Theme** - Sistem temasına uyumlu
- ✅ **İzin yönetimi** - Android ve iOS için konum izinleri
- ✅ **Hata yönetimi** - Kullanıcı dostu hata mesajları

## 📦 Kullanılan Paketler

### Harita
- `mapbox_maps_flutter` - Mapbox harita SDK'sı

### State Management
- `flutter_bloc` - BLoC state management
- `equatable` - Value equality

### Dependency Injection
- `get_it` - Service locator

### Konum
- `geolocator` - Konum servisleri
- `permission_handler` - İzin yönetimi

### Functional Programming
- `dartz` - Either, Option vb.

## 🚀 Kurulum

### 1. Projeyi klonlayın
```bash
git clone <repository-url>
cd flutter_app
```

### 2. Bağımlılıkları yükleyin
```bash
flutter pub get
```

### 3. Mapbox Token'ınızı yapılandırın
`lib/core/config/app_config.dart` dosyasında token'ınızı güncelleyin (şu an zaten yapılandırılmış)

### 4. Uygulamayı çalıştırın
```bash
# Android
flutter run

# iOS
flutter run
```

## 📱 Platform Gereksinimleri

### Android
- Minimum SDK: 21
- Target SDK: 34
- Konum izinleri otomatik olarak yapılandırılmıştır

### iOS
- Minimum iOS: 12.0
- Konum izinleri Info.plist'te yapılandırılmıştır

## 🔧 Geliştirme

### Yeni Özellik Ekleme

1. **Feature klasörü oluşturun**
   ```
   lib/features/yeni_feature/
   ├── data/
   ├── domain/
   └── presentation/
   ```

2. **Domain layer'dan başlayın**
   - Entities oluşturun
   - Repository interface tanımlayın
   - Use case'leri yazın

3. **Data layer'ı implemente edin**
   - Models oluşturun
   - Data source'ları yazın
   - Repository'yi implemente edin

4. **Presentation layer'ı oluşturun**
   - BLoC event/state tanımlayın
   - BLoC'u implemente edin
   - UI sayfalarını oluşturun

5. **Dependency Injection**
   - `injection_container.dart`'a kayıt edin

### Kod Kalitesi

```bash
# Analiz
flutter analyze

# Format
flutter format lib/

# Test
flutter test
```

## 🏗️ Build

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 📝 Yapılacaklar

- [ ] Rota çizme özelliği
- [ ] Yer işaretleri (markers)
- [ ] Arama fonksiyonu
- [ ] Offline harita desteği
- [ ] Rota geçmişi
- [ ] Favori konumlar
- [ ] Paylaşım özelliği

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/yeni-ozellik`)
3. Değişikliklerinizi commit edin (`git commit -am 'Yeni özellik eklendi'`)
4. Branch'inizi push edin (`git push origin feature/yeni-ozellik`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT License altında lisanslanmıştır.

## 👨‍💻 Geliştirici

Developed with ❤️ for professional app deployment

## 🔗 Faydalı Linkler

- [Mapbox Documentation](https://docs.mapbox.com/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [BLoC Pattern](https://bloclibrary.dev/)

