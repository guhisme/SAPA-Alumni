import 'package:flutter/material.dart';

import '../../models/alumni_profile.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/info_tile.dart';
import '../../widgets/loading_view.dart';
import 'alumni_edit_profile_screen.dart';
import 'alumni_notifications_screen.dart';
import '../auth/login_screen.dart';

class AlumniProfileScreen extends StatelessWidget {
  const AlumniProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda perlu masuk lagi untuk membuka aplikasi.'),
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

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        top: false,
        child: StreamBuilder<UserModel?>(
          stream: UserService.instance.watchUser(uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            final user = userSnap.data;
            if (user == null) {
              return const ErrorView(message: 'Data profil tidak ditemukan.');
            }

            return StreamBuilder<AlumniProfile>(
              stream: UserService.instance.watchAlumniProfile(uid),
              builder: (context, profileSnap) {
                final profile = profileSnap.data ?? AlumniProfile.empty(uid);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Container(
                            height: 76,
                            width: 76,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              Fmt.initials(user.name),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            user.name.isEmpty ? 'Alumni' : user.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user.email,
                            style: const TextStyle(
                                color: AppColors.textGrey, fontSize: 13),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: 200,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AlumniEditProfileScreen(
                                    user: user,
                                    profile: profile,
                                  ),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(42),
                              ),
                              icon: const Icon(Icons.edit_outlined, size: 17),
                              label: const Text('Edit profil'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data alumni',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DetailRow(
                            icon: Icons.chat_outlined,
                            label: 'WhatsApp',
                            value: user.phone,
                          ),
                          DetailRow(
                            icon: Icons.calendar_today_outlined,
                            label: 'Tahun lulus',
                            value: profile.graduationYear?.toString() ?? '',
                          ),
                          DetailRow(
                            icon: Icons.menu_book_outlined,
                            label: 'Jurusan',
                            value: profile.major,
                          ),
                          if (profile.bio.trim().isNotEmpty)
                            DetailRow(
                              icon: Icons.info_outline,
                              label: 'Tentang saya',
                              value: profile.bio,
                            ),
                          const SizedBox(height: 12),
                          const Text(
                            'Keahlian',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (profile.skills.isEmpty)
                            const Text(
                              'Belum ada keahlian yang diisi.',
                              style: TextStyle(
                                  color: AppColors.textGrey, fontSize: 13),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: profile.skills
                                  .map((s) => Chip(
                                        label: Text(s),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ))
                                  .toList(),
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
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(
                                Icons.notifications_none_rounded,
                                color: AppColors.textGrey),
                            title: const Text('Notifikasi',
                                style: TextStyle(fontSize: 14)),
                            trailing: const Icon(Icons.chevron_right,
                                color: AppColors.textGrey),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AlumniNotificationsScreen(),
                              ),
                            ),
                          ),
                          const Divider(height: 1, indent: 16, endIndent: 16),
                          ListTile(
                            leading: const Icon(Icons.logout_rounded,
                                color: AppColors.danger),
                            title: const Text(
                              'Keluar',
                              style: TextStyle(
                                  fontSize: 14, color: AppColors.danger),
                            ),
                            onTap: () => _logout(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Center(
                      child: Text(
                        'SAPA Alumni v1.0.0',
                        style:
                            TextStyle(color: AppColors.textGrey, fontSize: 12),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
