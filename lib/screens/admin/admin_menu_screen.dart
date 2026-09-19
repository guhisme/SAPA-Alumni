import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/admin_service.dart';
import '../../services/fcm_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import 'admin_bkk_verification_screen.dart';
import 'admin_whatsapp_screen.dart';
import '../auth/login_screen.dart';

/// Menu tambahan admin: verifikasi BKK, WhatsApp massal, keluar.
class AdminMenuScreen extends StatelessWidget {
  const AdminMenuScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(100, 42),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final uid = AuthService.instance.uid;
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    try {
      await AuthService.instance.logout();
      if (uid != null) await FcmService.instance.clearForUser(uid);
    } catch (_) {
      // Logout tetap harus berjalan bila token FCM gagal dibersihkan.
    }
  }

  Future<void> _seedDemo(BuildContext context) async {
    try {
      await AdminService.instance.seedDemoContent();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Data dummy berhasil disiapkan.')),
          );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Gagal menyiapkan data dummy.')),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Menu Admin')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            if (uid != null)
              StreamBuilder<UserModel?>(
                stream: UserService.instance.watchUser(uid),
                builder: (context, snap) {
                  final user = snap.data;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          height: 52,
                          width: 52,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            user == null || user.name.isEmpty
                                ? 'A'
                                : Fmt.initials(user.name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.name.isEmpty ?? true
                                    ? 'Administrator'
                                    : user!.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user?.email ?? '',
                                style: const TextStyle(
                                    fontSize: 12.5, color: AppColors.textGrey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),
            Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.verified_outlined,
                        color: AppColors.primary),
                    title: const Text('Verifikasi BKK',
                        style: TextStyle(fontSize: 14)),
                    subtitle: const Text(
                      'Setujui akun BKK sebelum bisa membuat lowongan',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminBkkVerificationScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.chat_bubble_outline,
                        color: AppColors.success),
                    title: const Text('Kirim WhatsApp',
                        style: TextStyle(fontSize: 14)),
                    subtitle: const Text(
                      'Broadcast informasi penting ke alumni',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AdminWhatsappScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.dataset_outlined,
                        color: AppColors.primary),
                    title: const Text('Isi data dummy',
                        style: TextStyle(fontSize: 14)),
                    subtitle: const Text(
                      'Tambahkan contoh pengumuman, beasiswa, pelatihan, dan lowongan',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _seedDemo(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Material(
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.border),
              ),
              child: ListTile(
                leading:
                    const Icon(Icons.logout_rounded, color: AppColors.danger),
                title: const Text(
                  'Keluar',
                  style: TextStyle(fontSize: 14, color: AppColors.danger),
                ),
                onTap: () => _logout(context),
              ),
            ),
            const SizedBox(height: 18),
            const Center(
              child: Text(
                'SAPA Alumni v1.0.0',
                style: TextStyle(color: AppColors.textGrey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
