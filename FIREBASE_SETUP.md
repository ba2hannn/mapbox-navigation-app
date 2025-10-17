# Firebase Kurulum Adımları

## 1. Firebase Console Kurulumu

### Firebase Projesi Oluşturma:
1. https://console.firebase.google.com/ adresine gidin
2. "Proje Ekle" butonuna tıklayın
3. Proje adı: `oguz-rota-app` (veya istediğiniz isim)
4. Google Analytics'i etkinleştirin (önerilir)
5. Projeyi oluşturun

### Firestore Database Oluşturma:
1. Sol menüden "Firestore Database" seçin
2. "Veritabanı oluştur" butonuna tıklayın
3. **Test modunda başlat** seçin (geliştirme için)
4. Konum: `europe-west1` (Avrupa - Belçika) seçin
5. Etkinleştir

### Authentication Etkinleştirme:
1. Sol menüden "Authentication" seçin
2. "Başlayın" butonuna tıklayın
3. "Sign-in method" sekmesine gidin
4. "Email/Password" etkinleştirin
5. Kaydet

### Storage Oluşturma:
1. Sol menüden "Storage" seçin
2. "Başlayın" butonuna tıklayın
3. **Test modunda başlat** seçin
4. Konum: `europe-west1` seçin
5. Bitti

## 2. Flutter Uygulaması Yapılandırması

### Firebase CLI Kurulumu:
Terminal'de şu komutları çalıştırın:

```bash
# Firebase CLI'yı yükleyin (eğer yoksa)
npm install -g firebase-tools

# Firebase'e giriş yapın
firebase login

# FlutterFire CLI'yı yükleyin
dart pub global activate flutterfire_cli

# Flutter projesinde Firebase'i yapılandırın
cd /home/ba2hann/Masaüstü/oguz_rotaapp/flutter_app
flutterfire configure
```

**flutterfire configure** komutu:
- Firebase projenizi seçecek (oguz-rota-app)
- Android ve iOS için otomatik yapılandırma yapacak
- `firebase_options.dart` dosyasını oluşturacak

## 3. Firestore Veritabanı Yapısı

### Collections:

#### users (Kullanıcılar)
```
users/
  {userId}/
    - email: string
    - displayName: string
    - photoURL: string
    - createdAt: timestamp
    
    vehicles/ (subcollection)
      {vehicleId}/
        - brand: string
        - model: string
        - year: number
        - vehicleClass: string
        - fuelType: string
        - color: string
        - plateNumber: string
        - imageUrl: string
        - createdAt: timestamp
        - updatedAt: timestamp
    
    routes/ (subcollection)
      {routeId}/
        - name: string
        - startPoint: geopoint
        - endPoint: geopoint
        - distance: number
        - estimatedTime: number
        - tollCost: number
        - createdAt: timestamp
    
    favorites/ (subcollection)
      {favoriteId}/
        - type: string (route, place)
        - referenceId: string
        - createdAt: timestamp
```

#### toll_booths (Gişeler - Global)
```
toll_booths/
  {boothId}/
    - name: string
    - location: geopoint
    - highwayName: string
    - class1Price: number
    - class2Price: number
    - class3Price: number
    - class4Price: number
    - class5Price: number
    - isActive: boolean
```

## 4. Firestore Güvenlik Kuralları

Firebase Console'da Firestore Database > Rules'a gidin:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Kullanıcılar sadece kendi verilerini okuyup yazabilir
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Alt koleksiyonlar
      match /vehicles/{vehicleId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /routes/{routeId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      match /favorites/{favoriteId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Gişeler herkes okuyabilir, sadece admin yazabilir
    match /toll_booths/{boothId} {
      allow read: if true;
      allow write: if false; // Admin panel'den yönetilecek
    }
  }
}
```

## 5. Test Verileri Ekleme

Firebase Console'da Firestore Database'e manuel test verisi ekleyin:

### Örnek Gişe Verisi:
Collection: `toll_booths`
Document ID: `auto-generate`
```json
{
  "name": "İstanbul Gişesi",
  "location": {
    "_lat": 41.0082,
    "_long": 28.9784
  },
  "highwayName": "TEM Otoyolu",
  "class1Price": 15.50,
  "class2Price": 23.25,
  "class3Price": 31.00,
  "class4Price": 46.50,
  "class5Price": 77.50,
  "isActive": true
}
```

## 6. Ana Dosyayı Güncelleme

`lib/main.dart` dosyasını şu şekilde güncelleyin:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}
```

## 7. Test Etme

Uygulamayı çalıştırın:
```bash
flutter run
```

- Profil ekranına gidin
- "Araçlarım" butonuna tıklayın
- Sahibinden.com tarzı adım adım araç ekleme ekranı açılacak
- 7 adımı tamamlayın ve kaydedin

## Notlar:

- **Test Modu**: Şu an güvenlik kuralları test modunda. Production'da mutlaka güncelleyin!
- **Authentication**: Şu an demo mod. Gerçek kullanıcı girişi ekleyeceğiz.
- **Storage**: Profil fotoğrafları ve araç resimleri için kullanılacak.
- **Indexes**: Firestore otomatik index oluşturacak. Hata alırsanız, Firebase Console'daki linke tıklayın.

## Sorun Giderme:

1. **"Firebase not initialized" hatası**: `main.dart`'ta Firebase.initializeApp() çağrıldığından emin olun
2. **Permission denied**: Firestore kurallarını kontrol edin
3. **Platform hatası**: `flutterfire configure` komutunu tekrar çalıştırın
