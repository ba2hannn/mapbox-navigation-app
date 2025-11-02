import 'package:flutter/material.dart';
import '../../../../core/theme/app_design.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gizlilik Politikası'),
        backgroundColor: AppDesign.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Gizlilik Politikası',
              'Son güncelleme: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
              isTitle: true,
            ),
            const SizedBox(height: 20),
            
            _buildSection(
              '1. Toplanan Bilgiler',
              '''
Rotonomi uygulaması, size daha iyi hizmet sunabilmek için aşağıdaki bilgileri toplar:

• Konum Bilgileri: Harita üzerinde konumunuzu göstermek ve rota planlaması yapmak için GPS verilerinize erişim sağlarız.
• Hesap Bilgileri: E-posta adresiniz ve profil bilgileriniz.
• Araç Bilgileri: Kaydettiğiniz araç model ve özellikleri.
• Kullanım Verileri: Uygulama içi gezinme ve özellik kullanımı.
''',
            ),
            
            _buildSection(
              '2. Bilgilerin Kullanımı',
              '''
Toplanan bilgiler şu amaçlarla kullanılır:

• Rota planlama ve navigasyon hizmeti sunmak
• Yakıt maliyeti ve gişe ücretlerini hesaplamak
• Kullanıcı deneyimini iyileştirmek
• Uygulama performansını analiz etmek
• Teknik destek sağlamak
''',
            ),
            
            _buildSection(
              '3. Veri Güvenliği',
              '''
Verilerinizin güvenliği bizim için önceliklidir:

• Tüm veriler Firebase güvenlik kurallarıyla korunur
• Konum verileri sadece uygulama kullanımı sırasında toplanır
• Kişisel bilgileriniz üçüncü taraflarla paylaşılmaz
• Verileriniz şifreli bağlantılar üzerinden iletilir
''',
            ),
            
            _buildSection(
              '4. Konum İzinleri',
              '''
Uygulamamız aşağıdaki konum izinlerini kullanır:

• "Kullanım Sırasında": Harita ve navigasyon özellikleri için
• Konum verileriniz sadece size hizmet sunmak için kullanılır
• Arkaplan konum takibi yapılmaz
• İstediğiniz zaman izinleri geri çekebilirsiniz
''',
            ),
            
            _buildSection(
              '5. Üçüncü Taraf Hizmetler',
              '''
Uygulamada kullanılan üçüncü taraf hizmetler:

• Firebase (Google): Kimlik doğrulama ve veri depolama
• Mapbox: Harita ve rota hizmetleri

Bu hizmetlerin kendi gizlilik politikaları geçerlidir.
''',
            ),
            
            _buildSection(
              '6. Veri Saklama ve Silme',
              '''
• Hesap verileriniz aktif olduğunuz sürece saklanır
• Hesabınızı sildiğinizde tüm verileriniz kalıcı olarak silinir
• Geçmiş rota kayıtları istediğiniz zaman silinebilir
• İletişim: rotonomi.app@gmail.com
''',
            ),
            
            _buildSection(
              '7. Çocukların Gizliliği',
              '''
Uygulamamız 13 yaş altı çocuklara yönelik değildir. 13 yaş altı kullanıcılardan bilerek veri toplamıyoruz.
''',
            ),
            
            _buildSection(
              '8. Politika Değişiklikleri',
              '''
Bu gizlilik politikası zaman zaman güncellenebilir. Önemli değişiklikler uygulama içinde bildirilecektir.
''',
            ),
            
            _buildSection(
              '9. İletişim',
              '''
Gizlilik politikamız hakkında sorularınız için:
E-posta: rotonomi.app@gmail.com
Uygulama: Profil > Ayarlar > Gizlilik Politikası
''',
            ),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, {bool isTitle = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isTitle ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: AppDesign.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: isTitle ? 14 : 16,
            color: isTitle ? Colors.grey[600] : Colors.grey[800],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
