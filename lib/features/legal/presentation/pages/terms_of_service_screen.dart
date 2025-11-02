import 'package:flutter/material.dart';
import '../../../../core/theme/app_design.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kullanım Koşulları'),
        backgroundColor: AppDesign.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Kullanım Koşulları',
              'Son güncelleme: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
              isTitle: true,
            ),
            const SizedBox(height: 20),
            
            _buildSection(
              '1. Hizmet Tanımı',
              '''
Rotonomi, kullanıcılara rota planlama, navigasyon, yakıt maliyeti hesaplama ve gişe ücreti bilgisi sunan bir mobil uygulamadır.
''',
            ),
            
            _buildSection(
              '2. Kullanım Şartları',
              '''
Uygulamayı kullanarak aşağıdaki şartları kabul etmiş olursunuz:

• 18 yaşından büyük olduğunuzu veya ebeveyn iznine sahip olduğunuzu
• Verdiğiniz bilgilerin doğru ve güncel olduğunu
• Hesap güvenliğinden sorumlu olduğunuzu
• Uygulamayı yasalara uygun şekilde kullanacağınızı
• Başkalarının haklarına saygı göstereceğinizi
''',
            ),
            
            _buildSection(
              '3. Hesap Sorumluluğu',
              '''
• Hesap bilgilerinizi güvenli tutmaktan siz sorumlusunuz
• Hesabınızda gerçekleşen tüm aktivitelerden siz sorumlusunuz
• Şüpheli aktivite fark ederseniz hemen bildirin
• Hesabınızı başkalarıyla paylaşmayın
''',
            ),
            
            _buildSection(
              '4. Hizmet Kullanımı',
              '''
Aşağıdaki davranışlar yasaktır:

• Uygulamayı yasa dışı amaçlarla kullanmak
• Sisteme zarar verecek yazılımlar kullanmak
• Diğer kullanıcıları rahatsız etmek
• Sahte bilgi veya içerik paylaşmak
• Uygulamanın güvenliğini tehdit etmek
• Otomatik sistemler (botlar) kullanmak
''',
            ),
            
            _buildSection(
              '5. Rota ve Navigasyon',
              '''
• Rota bilgileri yalnızca bilgilendirme amaçlıdır
• Trafikte her zaman trafik kurallarına uyun
• Navigasyon sırasında dikkatinizi yoldan ayırmayın
• Rota önerileri garanti değildir
• Hava koşulları ve trafik rotayı etkileyebilir
• Son kararı siz verirsiniz, uygulama sadece yardımcıdır
''',
            ),
            
            _buildSection(
              '6. Fiyat Bilgileri',
              '''
• Gişe ve yakıt fiyatları tahminidir
• Gerçek fiyatlar değişiklik gösterebilir
• Fiyat güncellemeleri düzenli yapılır ancak garanti edilmez
• Resmi fiyatlar için ilgili kurumlara başvurun
''',
            ),
            
            _buildSection(
              '7. Fikri Mülkiyet',
              '''
• Uygulama içeriği telif haklarıyla korunmaktadır
• Mapbox harita verileri Mapbox'a aittir
• İzinsiz kopyalama veya dağıtım yasaktır
• Logo ve markalar sahibine aittir
''',
            ),
            
            _buildSection(
              '8. Sorumluluk Reddi',
              '''
Rotonomi aşağıdakilerden sorumlu değildir:

• Yanlış veya güncel olmayan bilgilerden kaynaklanan zararlar
• Navigasyon sırasında meydana gelen kazalar
• İnternet bağlantısı sorunları
• Üçüncü taraf hizmetlerdeki aksaklıklar
• Cihaz uyumluluğu sorunları
• Veri kaybı veya hizmet kesintileri
''',
            ),
            
            _buildSection(
              '9. Hizmet Değişiklikleri',
              '''
• Özellikler eklenebilir veya kaldırılabilir
• Fiyatlandırma modeli değişebilir (şu an ücretsiz)
• Hizmet geçici veya kalıcı olarak sonlandırılabilir
• Önemli değişiklikler size bildirilecektir
''',
            ),
            
            _buildSection(
              '10. Hesap Askıya Alma/Kapatma',
              '''
Aşağıdaki durumlarda hesabınız askıya alınabilir veya kapatılabilir:

• Kullanım koşullarını ihlal etmeniz
• Yasa dışı aktivite şüphesi
• Uzun süre inaktif kalma
• Teknik güvenlik gerekçeleri
''',
            ),
            
            _buildSection(
              '11. İletişim ve Destek',
              '''
Sorularınız veya sorunlarınız için:
E-posta: rotonomi.app@gmail.com
Yanıt süresi: 1-3 iş günü
''',
            ),
            
            _buildSection(
              '12. Yasal Uyuşmazlıklar',
              '''
• Bu koşullar Türkiye Cumhuriyeti yasalarına tabidir
• Uyuşmazlıklar Ankara mahkemelerinde çözülür
• İhlal durumunda yasal işlem başlatılabilir
''',
            ),
            
            _buildSection(
              '13. Koşulların Kabulü',
              '''
Bu uygulamayı kullanarak bu kullanım koşullarını kabul etmiş sayılırsınız. Kabul etmiyorsanız lütfen uygulamayı kullanmayın.
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
