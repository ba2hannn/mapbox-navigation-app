# Beta Test Hazırlık Raporu - Rotonomi

## ✅ Tamamlanan İşler

### 1. Yasal Belgeler ✅
- ✅ Gizlilik Politikası sayfası oluşturuldu
- ✅ Kullanım Koşulları sayfası oluşturuldu
- ✅ Register ekranında bu sayfalara bağlantılar eklendi
- ✅ Tıklanabilir linkler ile entegrasyon tamamlandı

### 2. Android Güvenlik ✅
- ✅ ProGuard rules dosyası oluşturuldu
- ✅ Firebase, Mapbox, Geolocator için rules eklendi
- ✅ build.gradle.kts'ye ProGuard entegrasyonu yapıldı
- ✅ Release build optimizasyonu aktif

### 3. Test Altyapısı ✅
- ✅ Test klasörü oluşturuldu
- ✅ Örnek unit test hazırlandı (FuelCalculationService)

---

## ⚠️ ÖNEMLİ: Senin Yapman Gerekenler

### 1. 🔴 ZORUNLU - Uygulama İkonları (Logo)
**Ne yapmalısın:**
```bash
# 1. Logo tasarımını yap
# 2. Flutter launcher icons paketi ile ikon oluştur

# Yükle:
flutter pub add --dev flutter_launcher_icons

# pubspec.yaml'a ekle:
flutter_icons:
  android: true
  ios: true
  image_path: "assets/logo.png"  # 1024x1024 PNG

# Çalıştır:
flutter pub get
flutter pub run flutter_launcher_icons
```

**Gerekli dosyalar:**
- `assets/logo.png` - 1024x1024 px, şeffaf arka plan
- Android adaptive icon için `assets/logo_foreground.png` ve `assets/logo_background.png`

---

### 2. 🟠 ÖNEMLİ - Release Signing (Android)
**Ne yapmalısın:**
```bash
# 1. Keystore oluştur
keytool -genkey -v -keystore ~/rotonomi-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias rotonomi

# 2. android/key.properties dosyası oluştur:
storePassword=<keystore-şifren>
keyPassword=<key-şifren>
keyAlias=rotonomi
storeFile=/home/ba2hann/rotonomi-release-key.jks

# 3. android/app/build.gradle.kts'yi güncelle:
# signingConfigs kısmını ekle (detay aşağıda)
```

**build.gradle.kts değişikliği:**
```kotlin
// build.gradle.kts'nin başına ekle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... mevcut kod
    
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release  // Bunu değiştir
            // ... diğer ayarlar
        }
    }
}
```

---

### 3. 🟠 ÖNEMLİ - Firebase Security Rules
**Ne yapmalısın:**

Firebase Console'da:
1. Firestore Rules'u güvenli hale getir
2. Storage Rules'u güvenli hale getir

**Firestore Rules (önerilen):**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users - Sadece kendi verisi
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Vehicles
      match /vehicles/{vehicleId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Routes
      match /routes/{routeId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Gates - Herkes okuyabilir
    match /gates/{gateId} {
      allow read: if true;
      allow write: if false;  // Admin only
    }
    
    // Tolls - Herkes okuyabilir
    match /tolls/{tollId} {
      allow read: if true;
      allow write: if false;  // Admin only
    }
  }
}
```

**Storage Rules (önerilen):**
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null 
                   && request.auth.uid == userId
                   && request.resource.size < 5 * 1024 * 1024  // 5MB limit
                   && request.resource.contentType.matches('image/.*');
    }
  }
}
```

---

### 4. 🟡 TAVSİYE EDİLEN - Mapbox Token Güvenliği
**Ne yapmalısın:**

Token'ı kod içinde tutmak yerine environment variable kullan:

```dart
// .env dosyası oluştur (git'e ekleme!)
MAPBOX_ACCESS_TOKEN=pk.eyJ1IjoiYmEyaGFubiIsImEiOiJjbGt0bGNvZjMwYW9kM2Zxb242ZHNjOXJlIn0.ChzsBNO4d7chTkTO5t5whA

// flutter_dotenv paketi ekle
flutter pub add flutter_dotenv

// pubspec.yaml
assets:
  - .env

// app_config.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get mapboxAccessToken => dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
}

// main.dart
Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

---

### 5. 🟡 TAVSİYE EDİLEN - Gişe ve Gişe Ücreti Verileri
**Ne yapmalısın:**

Firebase Console'a gir ve verileri yükle:

**gates koleksiyonu:**
```json
{
  "id": "gate_001",
  "name": "İstanbul Gişesi",
  "highway": "O-3",
  "lat": 41.0082,
  "lon": 28.9784
}
```

**tolls koleksiyonu:**
```json
{
  "id": "toll_001",
  "highway": "O-3",
  "entryGateName": "İstanbul Gişesi",
  "exitGateName": "Ankara Gişesi",
  "prices": {
    "class1": 25.50,
    "class2": 38.25,
    "class3": 51.00,
    "class4": 76.50,
    "class5": 102.00
  }
}
```

---

### 6. 🟢 İSTEĞE BAĞLI - Test Coverage
**Ne yapmalısın:**

Daha fazla test ekle:
```bash
# Test çalıştır
flutter test

# Coverage raporu oluştur
flutter test --coverage
```

---

### 7. 🟢 İSTEĞE BAĞLI - Crashlytics Ekle
**Ne yapmalısın:**

Hata raporlama için:
```bash
flutter pub add firebase_crashlytics

# main.dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
```

---

## 📋 Store Yayınlama Checklist

### Google Play Store
- [ ] Logo ve ikonlar hazır
- [ ] Keystore oluşturuldu ve güvende saklandı
- [ ] ProGuard aktif
- [ ] Gizlilik Politikası ve Kullanım Koşulları linki
- [ ] Uygulama açıklaması (4000 karakter)
- [ ] Kısa açıklama (80 karakter)
- [ ] En az 2 ekran görüntüsü (telefon)
- [ ] Banner grafik (1024x500 px)
- [ ] Feature grafik (1024x500 px)
- [ ] Uygulama kategorisi: Haritalar & Navigasyon
- [ ] İçerik derecelendirmesi tamamlandı
- [ ] APK veya AAB yüklendi
- [ ] Beta test grubu oluşturuldu

### Apple App Store
- [ ] Logo ve ikonlar hazır
- [ ] Development/Distribution sertifikaları
- [ ] App ID oluşturuldu
- [ ] Provisioning profiles
- [ ] Gizlilik Politikası URL
- [ ] Uygulama açıklaması
- [ ] Anahtar kelimeler
- [ ] En az 3 ekran görüntüsü (her cihaz boyutu için)
- [ ] App Preview videosu (opsiyonel)
- [ ] App Store Connect'te metadata
- [ ] TestFlight beta test

---

## 🎯 Beta Test Öncesi Kontrol Listesi

### Teknik
- [ ] Uygulama stabil ve crash olmuyor
- [ ] GPS izinleri doğru çalışıyor
- [ ] Harita yükleniyor ve kullanılabiliyor
- [ ] Rota hesaplaması çalışıyor
- [ ] Firebase auth çalışıyor
- [ ] Araç ekleme/düzenleme çalışıyor
- [ ] Offline durum yönetimi test edildi
- [ ] Farklı ekran boyutlarında test edildi

### Kullanıcı Deneyimi
- [ ] Bildirimler doğru görünüyor
- [ ] Hata mesajları anlaşılır
- [ ] Loading göstergeleri uygun
- [ ] Butonlar tıklanabilir ve responsive
- [ ] Formlar validation yapıyor

### Güvenlik ve Gizlilik
- [ ] Firebase rules aktif
- [ ] Token'lar güvende
- [ ] Kullanıcı verileri izole
- [ ] Gizlilik politikası erişilebilir

---

## 🚀 Build Komutları

### Android
```bash
# Debug APK
flutter build apk --debug

# Release APK (test için)
flutter build apk --release

# Release AAB (Play Store için)
flutter build appbundle --release

# Build boyutunu kontrol et
flutter build apk --release --analyze-size
```

### iOS
```bash
# Debug
flutter build ios --debug

# Release
flutter build ios --release

# Xcode'da Archive
open ios/Runner.xcworkspace
# Product > Archive
```

---

## 📊 Mevcut Durum

### ✅ Hazır Olanlar
- Clean Architecture implementasyonu
- Firebase entegrasyonu (Auth, Firestore, Storage)
- Mapbox entegrasyonu
- Rota planlama
- Araç yönetimi
- Kullanıcı profili
- Bildirim sistemi
- Gizlilik Politikası ve Kullanım Koşulları sayfaları
- ProGuard rules

### ⚠️ Bekleyen İşler
- Uygulama logosu ve ikonları
- Release signing yapılandırması
- Firebase Security Rules production-ready
- Gişe ve gişe ücreti verileri
- Test coverage artırımı
- Store metadata ve ekran görüntüleri

---

## 💡 Öneriler

1. **Beta Test Grubu Oluştur**: En az 10-20 kişi ile test et
2. **Feedback Toplama**: Google Forms veya Firebase In-App Messaging kullan
3. **Analytics Ekle**: Firebase Analytics ile kullanım verilerini topla
4. **Crash Raporlama**: Crashlytics mutlaka ekle
5. **Performance Monitoring**: Firebase Performance kullan
6. **A/B Testing**: Farklı UI versiyonlarını test et

---

## 🔗 Faydalı Linkler

- [Flutter Launcher Icons](https://pub.dev/packages/flutter_launcher_icons)
- [Android App Signing](https://developer.android.com/studio/publish/app-signing)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [Play Console](https://play.google.com/console)
- [App Store Connect](https://appstoreconnect.apple.com/)

---

**Hazırlayan:** AI Assistant  
**Tarih:** 2 Kasım 2025  
**Versiyon:** 1.0.0
