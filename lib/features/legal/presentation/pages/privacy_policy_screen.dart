import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Gizlilik Politikası',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.privacy_tip,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Gizliliğiniz Bizim İçin Önemli',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Son güncelleme: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            _buildModernSection(
              icon: Icons.inventory_2_outlined,
              title: 'Toplanan Bilgiler',
              color: const Color(0xFF3498DB),
              content: '''Rotonomi uygulaması, size daha iyi hizmet sunabilmek için aşağıdaki bilgileri toplar:

• Konum Bilgileri: Harita üzerinde konumunuzu göstermek ve rota planlaması yapmak için GPS verilerinize erişim sağlarız.
• Hesap Bilgileri: E-posta adresiniz ve profil bilgileriniz.
• Araç Bilgileri: Kaydettiğiniz araç model ve özellikleri.
• Kullanım Verileri: Uygulama içi gezinme ve özellik kullanımı.''',
            ),

            _buildModernSection(
              icon: Icons.settings_applications,
              title: 'Bilgilerin Kullanımı',
              color: const Color(0xFF2ECC71),
              content: '''Toplanan bilgiler şu amaçlarla kullanılır:

• Rota planlama ve navigasyon hizmeti sunmak
• Yakıt maliyeti ve gişe ücretlerini hesaplamak
• Kullanıcı deneyimini iyileştirmek
• Uygulama performansını analiz etmek
• Teknik destek sağlamak''',
            ),

            _buildModernSection(
              icon: Icons.security,
              title: 'Veri Güvenliği',
              color: const Color(0xFF9B59B6),
              content: '''Verilerinizin güvenliği bizim için önceliklidir:

• Tüm veriler Firebase güvenlik kurallarıyla korunur
• Konum verileri sadece uygulama kullanımı sırasında toplanır
• Kişisel bilgileriniz üçüncü taraflarla paylaşılmaz
• Verileriniz şifreli bağlantılar üzerinden iletilir''',
            ),

            _buildModernSection(
              icon: Icons.location_on,
              title: 'Konum İzinleri',
              color: const Color(0xFFF39C12),
              content: '''Uygulamamız aşağıdaki konum izinlerini kullanır:

• "Kullanım Sırasında": Harita ve navigasyon özellikleri için
• Konum verileriniz sadece size hizmet sunmak için kullanılır
• Arkaplan konum takibi yapılmaz
• İstediğiniz zaman izinleri geri çekebilirsiniz''',
            ),

            _buildModernSection(
              icon: Icons.cloud_outlined,
              title: 'Üçüncü Taraf Hizmetler',
              color: const Color(0xFF1ABC9C),
              content: '''Uygulamada kullanılan üçüncü taraf hizmetler:

• Firebase (Google): Kimlik doğrulama ve veri depolama
• Mapbox: Harita ve rota hizmetleri

Bu hizmetlerin kendi gizlilik politikaları geçerlidir.''',
            ),

            _buildModernSection(
              icon: Icons.delete_outline,
              title: 'Veri Saklama ve Silme',
              color: const Color(0xFFE74C3C),
              content: '''• Hesap verileriniz aktif olduğunuz sürece saklanır
• Hesabınızı sildiğinizde tüm verileriniz kalıcı olarak silinir
• Geçmiş rota kayıtları istediğiniz zaman silinebilir
• İletişim: iletisim@batuhanakcan.com''',
            ),

            _buildModernSection(
              icon: Icons.child_care,
              title: 'Çocukların Gizliliği',
              color: const Color(0xFFFF6B6B),
              content:
                  'Uygulamamız 13 yaş altı çocuklara yönelik değildir. 13 yaş altı kullanıcılardan bilerek veri toplamıyoruz.',
            ),

            _buildModernSection(
              icon: Icons.update,
              title: 'Politika Güncellemeleri',
              color: const Color(0xFF4ECDC4),
              content:
                  'Bu gizlilik politikası zaman zaman güncellenebilir. Önemli değişiklikler olduğunda sizi bilgilendireceğiz.',
            ),

            _buildModernSection(
              icon: Icons.contact_mail,
              title: 'Bize Ulaşın',
              color: const Color(0xFF95A5A6),
              content: '''Gizlilik politikamız hakkında sorularınız için:

E-posta: iletisim@batuhanakcan.com
Website: batuhanakcan.com''',
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSection({
    required IconData icon,
    required String title,
    required Color color,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[700],
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
