import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../../core/widgets/animated_notification.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;
  String _cacheSize = 'Hesaplanıyor...';

  // İzinler
  bool _locationPermission = false;
  bool _notificationPermission = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _calculateCacheSize(),
      _checkPermissions(),
    ]);
  }

  Future<void> _calculateCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = await getApplicationCacheDirectory();
      
      int totalSize = 0;
      if (await tempDir.exists()) {
        totalSize += await _getDirectorySize(tempDir);
      }
      if (await cacheDir.exists()) {
        totalSize += await _getDirectorySize(cacheDir);
      }

      setState(() {
        _cacheSize = '${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB';
      });
    } catch (e) {
      setState(() {
        _cacheSize = 'Hesaplanamadı';
      });
    }
  }

  Future<int> _getDirectorySize(Directory directory) async {
    int size = 0;
    try {
      if (await directory.exists()) {
        await for (var entity in directory.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (e) {
      debugPrint('Dizin boyutu hesaplama hatası: $e');
    }
    return size;
  }

  Future<void> _checkPermissions() async {
    final location = await Permission.location.status;
    final notification = await Permission.notification.status;

    setState(() {
      _locationPermission = location.isGranted;
      _notificationPermission = notification.isGranted;
    });
  }

  Future<void> _clearCache() async {
    setState(() => _isLoading = true);
    
    try {
      final tempDir = await getTemporaryDirectory();
      final cacheDir = await getApplicationCacheDirectory();
      
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
        await tempDir.create();
      }
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }

      await _calculateCacheSize();
      
      if (mounted) {
        NotificationHelper.show(
          context,
          'Önbellek başarıyla temizlendi',
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.show(
          context,
          'Önbellek temizlenirken hata oluştu',
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changeEmail() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('E-posta Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Yeni E-posta',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'Mevcut Şifre',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'Güvenlik nedeniyle mevcut şifrenizi girmeniz gerekiyor.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() => _isLoading = true);
      
      try {
        // Önce kullanıcıyı yeniden doğrula
        final credential = EmailAuthProvider.credential(
          email: _currentUser!.email!,
          password: passwordController.text,
        );
        await _currentUser.reauthenticateWithCredential(credential);
        
        // E-postayı değiştir
        await _currentUser.verifyBeforeUpdateEmail(emailController.text);
        
        if (mounted) {
          NotificationHelper.show(
            context,
            'Doğrulama e-postası gönderildi. Lütfen e-postanızı kontrol edin.',
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          String message = 'E-posta değiştirilemedi';
          if (e.code == 'wrong-password') {
            message = 'Şifre hatalı';
          } else if (e.code == 'email-already-in-use') {
            message = 'Bu e-posta zaten kullanılıyor';
          }
          NotificationHelper.show(context, message);
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              decoration: const InputDecoration(
                labelText: 'Mevcut Şifre',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre (Tekrar)',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      if (newPasswordController.text != confirmPasswordController.text) {
        NotificationHelper.show(context, 'Şifreler eşleşmiyor');
        return;
      }

      if (newPasswordController.text.length < 6) {
        NotificationHelper.show(
            context, 'Şifre en az 6 karakter olmalıdır');
        return;
      }

      setState(() => _isLoading = true);
      
      try {
        final credential = EmailAuthProvider.credential(
          email: _currentUser!.email!,
          password: oldPasswordController.text,
        );
        await _currentUser.reauthenticateWithCredential(credential);
        await _currentUser.updatePassword(newPasswordController.text);
        
        if (mounted) {
          NotificationHelper.show(context, 'Şifre başarıyla değiştirildi');
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          String message = 'Şifre değiştirilemedi';
          if (e.code == 'wrong-password') {
            message = 'Mevcut şifre hatalı';
          }
          NotificationHelper.show(context, message);
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _togglePermission(Permission permission, bool currentValue) async {
    if (currentValue) {
      // İzin zaten verilmiş, ayarlara yönlendir
      await openAppSettings();
    } else {
      // İzin iste
      final status = await permission.request();
      await _checkPermissions();
      
      if (status.isGranted && mounted) {
        NotificationHelper.show(context, 'İzin verildi');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Ayarlar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Header Card
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3498DB), Color(0xFF2980B9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3498DB).withOpacity(0.3),
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
                            Icons.settings,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentUser?.email ?? 'Kullanıcı',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hesap Ayarları
                  _buildSectionTitle('Hesap Ayarları'),
                  _buildSettingCard(
                    icon: Icons.email_outlined,
                    title: 'E-posta Değiştir',
                    subtitle: _currentUser?.email ?? '',
                    color: const Color(0xFF3498DB),
                    onTap: _changeEmail,
                  ),
                  _buildSettingCard(
                    icon: Icons.lock_outline,
                    title: 'Şifre Değiştir',
                    subtitle: 'Son değişiklik: Bilinmiyor',
                    color: const Color(0xFF9B59B6),
                    onTap: _changePassword,
                  ),

                  // İzinler
                  _buildSectionTitle('Uygulama İzinleri'),
                  _buildPermissionCard(
                    icon: Icons.location_on,
                    title: 'Konum',
                    subtitle: 'Navigasyon ve harita özellikleri için gerekli',
                    color: const Color(0xFF2ECC71),
                    value: _locationPermission,
                    onChanged: (value) =>
                        _togglePermission(Permission.location, _locationPermission),
                  ),
                  _buildPermissionCard(
                    icon: Icons.notifications,
                    title: 'Bildirimler',
                    subtitle: 'Önemli güncellemeler için gerekli',
                    color: const Color(0xFFF39C12),
                    value: _notificationPermission,
                    onChanged: (value) => _togglePermission(
                        Permission.notification, _notificationPermission),
                  ),

                  // Depolama
                  _buildSectionTitle('Depolama'),
                  _buildInfoCard(
                    icon: Icons.sd_storage,
                    title: 'Önbellek Boyutu',
                    value: _cacheSize,
                    color: const Color(0xFFE74C3C),
                  ),
                  _buildActionCard(
                    icon: Icons.cleaning_services,
                    title: 'Önbelleği Temizle',
                    subtitle: 'Geçici dosyaları sil ve alan aç',
                    color: const Color(0xFFE74C3C),
                    onTap: _clearCache,
                  ),

                  // Offline Haritalar (Gelecek özellik)
                  _buildSectionTitle('Offline Haritalar'),
                  _buildComingSoonCard(
                    icon: Icons.download,
                    title: 'Bölge İndir',
                    subtitle: 'Haritaları offline kullanım için indir',
                    color: const Color(0xFF1ABC9C),
                  ),
                  _buildComingSoonCard(
                    icon: Icons.map,
                    title: 'İndirilen Bölgeler',
                    subtitle: 'Henüz indirilmiş bölge yok',
                    color: const Color(0xFF16A085),
                  ),

                  // Hakkında
                  _buildSectionTitle('Uygulama Bilgileri'),
                  _buildInfoCard(
                    icon: Icons.info_outline,
                    title: 'Versiyon',
                    value: '1.0.0',
                    color: const Color(0xFF95A5A6),
                  ),
                  _buildInfoCard(
                    icon: Icons.developer_mode,
                    title: 'Build Numarası',
                    value: '1',
                    color: const Color(0xFF7F8C8D),
                  ),

                  const SizedBox(height: 24),
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
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
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
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool value,
    required ValueChanged<bool> onChanged,
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
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: color,
              ),
            ],
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
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
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
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
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

  Widget _buildComingSoonCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Opacity(
          opacity: 0.6,
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
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Yakında',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
