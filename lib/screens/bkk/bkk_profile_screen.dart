import 'package:flutter/material.dart';

import '../../models/bkk_profile.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/bkk_service.dart';
import '../../services/fcm_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/info_tile.dart';
import '../../widgets/loading_view.dart';
import 'bkk_edit_profile_screen.dart';
import '../auth/login_screen.dart';

class BkkProfileScreen extends StatelessWidget {
  const BkkProfileScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profil BKK')),
      body: SafeArea(
        top: false,
        child: StreamBuilder<UserModel?>(
          stream: UserService.instance.watchUser(uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            final user = userSnap.data;

            return StreamBuilder<BkkProfile>(
              stream: BkkService.instance.watchProfile(uid),
              builder: (context, snap) {
                final profile = snap.data ?? BkkProfile.empty(uid);

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
                            height: 72,
                            width: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              profile.name.isEmpty
                                  ? 'B'
                                  : Fmt.initials(profile.name),
                              style: const TextStyle(
                                color: AppColors.primaryDark,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            profile.name.isEmpty
                                ? 'Nama BKK belum diisi'
                                : profile.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: const TextStyle(
                                color: AppColors.textGrey, fontSize: 13),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: (profile.verified
                                      ? AppColors.success
                                      : AppColors.warning)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  profile.verified
                                      ? Icons.verified_rounded
                                      : Icons.hourglass_empty_rounded,
                                  size: 15,
                                  color: profile.verified
                                      ? AppColors.success
                                      : AppColors.warning,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  profile.verified
                                      ? 'Terverifikasi'
                                      : 'Menunggu verifikasi admin',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: profile.verified
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: 200,
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      BkkEditProfileScreen(profile: profile),
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
                            'Data BKK',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          DetailRow(
                            icon: Icons.chat_outlined,
                            label: 'Telepon',
                            value: profile.phone,
                          ),
                          DetailRow(
                            icon: Icons.place_outlined,
                            label: 'Alamat',
                            value: profile.address,
                          ),
                          if (profile.description.trim().isNotEmpty)
                            SectionBlock(
                                title: 'Deskripsi',
                                content: profile.description),
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
                        leading: const Icon(Icons.logout_rounded,
                            color: AppColors.danger),
                        title: const Text(
                          'Keluar',
                          style:
                              TextStyle(fontSize: 14, color: AppColors.danger),
                        ),
                        onTap: () => _logout(context),
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
