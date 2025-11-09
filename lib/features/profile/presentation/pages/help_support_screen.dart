import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Rotonomi Uygulama Desteği',
    );
    if (!await launchUrl(uri)) {
      throw Exception('Could not launch email');
    }
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label kopyalandı'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Yardım & Destek',
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
                      Icons.support_agent,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Size Nasıl Yardımcı Olabiliriz?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Her türlü soru ve destek talepleriniz için buradayız',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // İletişim Bilgileri
            _buildSectionTitle('İletişim Bilgileri'),
            _buildContactCard(
              context,
              icon: Icons.email_outlined,
              title: 'E-posta',
              subtitle: 'iletisim@batuhanakcan.com',
              color: const Color(0xFF3498DB),
              onTap: () => _launchEmail('iletisim@batuhanakcan.com'),
              onLongPress: () => _copyToClipboard(
                context,
                'iletisim@batuhanakcan.com',
                'E-posta',
              ),
            ),
            _buildContactCard(
              context,
              icon: Icons.language,
              title: 'Website',
              subtitle: 'batuhanakcan.com',
              color: const Color(0xFF9B59B6),
              onTap: () => _launchUrl('https://batuhanakcan.com'),
              onLongPress: () => _copyToClipboard(
                context,
                'batuhanakcan.com',
                'Website',
              ),
            ),
            _buildContactCard(
              context,
              icon: Icons.phone_outlined,
              title: 'Telefon',
              subtitle: '+90 555 123 45 67',
              color: const Color(0xFF2ECC71),
              onTap: () => _launchUrl('tel:+905551234567'),
              onLongPress: () => _copyToClipboard(
                context,
                '+90 555 123 45 67',
                'Telefon',
              ),
            ),

            // Uygulama Bilgileri
            _buildSectionTitle('Uygulama Hakkında'),
            _buildInfoCard(
              icon: Icons.info_outline,
              title: 'Versiyon',
              value: '1.0.0',
              color: const Color(0xFFF39C12),
            ),
            _buildInfoCard(
              icon: Icons.calendar_today,
              title: 'Yayın Tarihi',
              value: 'Kasım 2025',
              color: const Color(0xFF1ABC9C),
            ),
            _buildInfoCard(
              icon: Icons.code,
              title: 'Platform',
              value: 'iOS & Android',
              color: const Color(0xFFE74C3C),
            ),

            // Sık Sorulan Sorular
            _buildSectionTitle('Sık Sorulan Sorular'),
            _buildFAQCard(
              question: 'Rotonomi nedir?',
              answer:
                  'Rotonomi, akıllı navigasyon ve geçiş ücreti takibi sunan modern bir mobil uygulamadır. Seyahatlerinizi planlamanıza ve geçiş ücretlerinizi kolayca yönetmenize yardımcı olur.',
            ),
            _buildFAQCard(
              question: 'Uygulama ücretsiz mi?',
              answer:
                  'Evet, Rotonomi tamamen ücretsiz kullanılabilir. Premium özellikler gelecekte eklenebilir.',
            ),
            _buildFAQCard(
              question: 'Konum verilerim güvende mi?',
              answer:
                  'Evet, konum verileriniz güvenli bir şekilde saklanır ve üçüncü taraflarla paylaşılmaz. Verileriniz sadece uygulama özelliklerini sağlamak için kullanılır.',
            ),
            _buildFAQCard(
              question: 'Hangi haritalar destekleniyor?',
              answer:
                  'Rotonomi, yüksek kaliteli harita deneyimi için Mapbox altyapısını kullanmaktadır.',
            ),
            _buildFAQCard(
              question: 'Hesabımı nasıl silebilirim?',
              answer:
                  'Hesabınızı silmek için Profil > Ayarlar bölümünden "Hesabı Sil" seçeneğini kullanabilirsiniz. Bu işlem geri alınamaz.',
            ),

            // Sosyal Medya
            _buildSectionTitle('Bizi Takip Edin'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSocialButton(
                        context,
                        icon: Icons.facebook,
                        color: const Color(0xFF1877F2),
                        label: 'Facebook',
                        onTap: () => _launchUrl('https://facebook.com/rotonomi'),
                      ),
                      _buildSocialButton(
                        context,
                        icon: Icons.alternate_email,
                        color: const Color(0xFF1DA1F2),
                        label: 'Twitter',
                        onTap: () => _launchUrl('https://twitter.com/rotonomi'),
                      ),
                      _buildSocialButton(
                        context,
                        icon: Icons.camera_alt,
                        color: const Color(0xFFE4405F),
                        label: 'Instagram',
                        onTap: () => _launchUrl('https://instagram.com/rotonomi'),
                      ),
                      _buildSocialButton(
                        context,
                        icon: Icons.link,
                        color: const Color(0xFF0A66C2),
                        label: 'LinkedIn',
                        onTap: () => _launchUrl('https://linkedin.com/company/rotonomi'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Footer
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '© 2025 Rotonomi. Tüm hakları saklıdır.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQCard({
    required String question,
    required String answer,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Theme(
          data: ThemeData(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.help_outline,
                color: Color(0xFF667EEA),
                size: 24,
              ),
            ),
            title: Text(
              question,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            children: [
              Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
