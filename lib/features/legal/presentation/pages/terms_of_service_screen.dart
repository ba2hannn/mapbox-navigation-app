import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Kullanım Koşulları',
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
                  colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF11998E).withOpacity(0.3),
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
                      Icons.description,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Kullanım Koşulları',
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
              icon: Icons.info_outline,
              title: 'Hizmet Tanımı',
              color: const Color(0xFF3498DB),
              content:
                  'Rotonomi, kullanıcılara rota planlama, navigasyon, yakıt maliyeti hesaplama ve gişe ücreti bilgisi sunan bir mobil uygulamadır.',
            ),

            _buildModernSection(
              icon: Icons.check_circle_outline,
              title: 'Kullanım Şartları',
              color: const Color(0xFF2ECC71),
              content: '''Uygulamayı kullanarak aşağıdaki şartları kabul etmiş olursunuz:

• 18 yaşından büyük olduğunuzu veya ebeveyn iznine sahip olduğunuzu
• Verdiğiniz bilgilerin doğru ve güncel olduğunu
• Hesap güvenliğinden sorumlu olduğunuzu
• Uygulamayı yasalara uygun şekilde kullanacağınızı
• Başkalarının haklarına saygı göstereceğinizi''',
            ),

            _buildModernSection(
              icon: Icons.account_circle_outlined,
              title: 'Hesap Sorumluluğu',
              color: const Color(0xFF9B59B6),
              content: '''• Hesap bilgilerinizi güvenli tutmaktan siz sorumlusunuz
• Hesabınızda gerçekleşen tüm aktivitelerden siz sorumlusunuz
• Şüpheli aktivite fark ederseniz hemen bildirin
• Hesabınızı başkalarıyla paylaşmayın''',
            ),

            _buildModernSection(
              icon: Icons.block,
              title: 'Yasak Davranışlar',
              color: const Color(0xFFE74C3C),
              content: '''Aşağıdaki davranışlar yasaktır:

• Uygulamayı yasa dışı amaçlarla kullanmak
• Sisteme zarar verecek yazılımlar kullanmak
• Diğer kullanıcıları rahatsız etmek
• Sahte bilgi veya içerik paylaşmak
• Uygulamanın güvenliğini tehdit etmek
• Otomatik sistemler (botlar) kullanmak''',
            ),

            _buildModernSection(
              icon: Icons.navigation,
              title: 'Rota ve Navigasyon',
              color: const Color(0xFFF39C12),
              content: '''• Rota bilgileri yalnızca bilgilendirme amaçlıdır
• Trafikte her zaman trafik kurallarına uyun
• Navigasyon sırasında dikkatinizi yoldan ayırmayın
• Rota önerileri garanti değildir
• Hava koşulları ve trafik rotayı etkileyebilir
• Son kararı siz verirsiniz, uygulama sadece yardımcıdır''',
            ),

            _buildModernSection(
              icon: Icons.attach_money,
              title: 'Fiyat Bilgileri',
              color: const Color(0xFF1ABC9C),
              content: '''• Gişe ve yakıt fiyatları tahminidir
• Gerçek fiyatlar değişiklik gösterebilir
• Fiyat güncellemeleri düzenli yapılır ancak garanti edilmez
• Resmi fiyatlar için ilgili kurumlara başvurun''',
            ),

            _buildModernSection(
              icon: Icons.copyright,
              title: 'Fikri Mülkiyet',
              color: const Color(0xFF34495E),
              content: '''• Uygulama içeriği telif haklarıyla korunmaktadır
• Mapbox harita verileri Mapbox'a aittir
• İzinsiz kopyalama veya dağıtım yasaktır
• Logo ve markalar sahibine aittir''',
            ),

            _buildModernSection(
              icon: Icons.shield_outlined,
              title: 'Sorumluluk Reddi',
              color: const Color(0xFF95A5A6),
              content: '''• Uygulama "olduğu gibi" sunulmaktadır
• Kesinti veya hatalardan sorumlu değiliz
• Navigasyon bilgilerinin doğruluğunu garanti etmeyiz
• Uygulama kullanımından kaynaklanan zararlardan sorumlu tutulamayız
• Üçüncü taraf hizmetlerden sorumlu değiliz''',
            ),

            _buildModernSection(
              icon: Icons.update,
              title: 'Koşulların Güncellenmesi',
              color: const Color(0xFF4ECDC4),
              content:
                  'Bu kullanım koşulları zaman zaman güncellenebilir. Önemli değişiklikler uygulama içinde bildirilecektir. Güncellemelerden sonra uygulamayı kullanmaya devam etmeniz, yeni koşulları kabul ettiğiniz anlamına gelir.',
            ),

            _buildModernSection(
              icon: Icons.gavel,
              title: 'Hesap İptali',
              color: const Color(0xFFE67E22),
              content: '''Aşağıdaki durumlarda hesabınız iptal edilebilir:

• Kullanım koşullarını ihlal etmeniz
• Sahte bilgi sağlamanız
• Diğer kullanıcılara zarar vermeniz
• Uygulamanın güvenliğini tehdit etmeniz''',
            ),

            _buildModernSection(
              icon: Icons.contact_mail,
              title: 'İletişim',
              color: const Color(0xFF667EEA),
              content: '''Kullanım koşulları hakkında sorularınız için:

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
