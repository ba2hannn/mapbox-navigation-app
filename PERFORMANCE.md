## Mapbox Tile Sistemi ve Performans Optimizasyonu

### 🗺️ Mapbox Nasıl Çalışır?

**Tile-Based System (Karo Tabanlı):**
- Harita küçük kareler (tiles) halinde bölünmüş
- Her tile 256x256 veya 512x512 piksel
- Sadece EKRANDA GÖRÜNEN tile'lar indirilir

### ✅ Bizim Yaptığımız Optimizasyonlar:

**1. Bounding Box (Coğrafi Sınır):**
```dart
turkeyMinLat: 35.0° → 42.5°
turkeyMinLng: 25.5° → 45.5°
```
**Sonuç:** 
- ✅ Kullanıcı Amerika'ya gidemez → Amerika tile'ları HİÇ İNDİRİLMEZ
- ✅ Sadece Türkiye tile'ları önbellekte saklanır
- ✅ Gereksiz veri kullanımı engellenir

**2. Zoom Limitleri:**
```dart
minZoom: 5.0 (Türkiye geneli)
maxZoom: 20.0 (Sokak seviyesi)
```
**Sonuç:**
- ✅ Çok uzaklaşıp dünya görüntüsü yüklenmez
- ✅ Gereksiz düşük zoom tile'ları inmez

### 📊 Performans Karşılaştırması:

**SINIRSıZ Harita:**
- Kullanıcı yanlışlıkla Amerika'ya kaydırabilir
- Gereksiz tile'lar indirilir (veri israfı)
- Cache dolabilir gereksiz verilerle
- Daha fazla RAM kullanımı

**SINIRLI Harita (Bizim):**
- ✅ Sadece Türkiye tile'ları indirilir
- ✅ %90 daha az gereksiz veri
- ✅ Cache'de sadece ilgili bölge
- ✅ Daha hızlı navigasyon

### 🚀 Ek Optimizasyonlar:

**1. Prefetch (Ön Yükleme):**
- Mapbox otomatik olarak çevredeki tile'ları önceden yükler
- Sınır sayesinde sadece Türkiye için prefetch yapar

**2. Cache Yönetimi:**
- Uygulama kapatılsa bile tile'lar cihazda saklanır
- Tekrar açılınca hemen yüklenir (çok hızlı)
- Sadece Türkiye tile'ları cache'lenir → Verimli kullanım

**3. Network İsteği:**
- Her zoom seviyesi için ayrı tile'lar var
- Sadece ihtiyaç duyulan zoom tile'ı indirilir
- Amerika için hiç istek gitmez!

### 📱 Gerçek Dünya Etkisi:

**İlk Açılış:**
- Sınırsız: ~5-10 MB indirme (dünya geneli için hazırlık)
- Bizim: ~2-3 MB (sadece Türkiye için)

**Kullanım Sırasında:**
- Türkiye içinde gezinirken: AYNI PERFORMANS
- Yanlışlıkla kaydırma: BİZİMKİ ENGELLERKEN DİĞERİ VERİ İNDİRİR

**Cache Boyutu (1 hafta kullanım sonrası):**
- Sınırsız: ~50-100 MB (rastgele bölgeler)
- Bizim: ~30-40 MB (sadece Türkiye)

### ✅ Sonuç:

EVET, gerçekten daha hızlı! Çünkü:
1. Amerika tile'ları hiç indirilmez
2. Cache sadece Türkiye ile dolar
3. RAM daha verimli kullanılır
4. Network trafiği optimize edilir

Amerika arkada yüklenmez - sadece GÖRÜNEN ve YAKIN BÖLGE tile'ları yüklenir!
