import 'package:flutter/material.dart';

import '../../models/bkk_profile.dart';
import '../../models/user_model.dart';
import '../../services/admin_service.dart';
import '../../services/bkk_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/info_tile.dart';
import '../shared/whatsapp_compose_screen.dart';

/// Detail pengguna BKK atau admin, termasuk verifikasi dan ubah role.
class AdminUserDetailScreen extends StatelessWidget {
  final UserModel user;
  const AdminUserDetailScreen({super.key, required this.user});

  Future<void> _changeRole(BuildContext context) async {
    String selected = user.role;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Ubah role pengguna'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Roles.alumni, Roles.bkk, Roles.admin]
                .map(
                  (r) => RadioListTile<String>(
                    value: r,
                    groupValue: selected,
                    onChanged: (v) => setLocal(() => selected = v ?? selected),
                    title: Text(r),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                )
                .toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(90, 42)),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      await AdminService.instance.setRole(user.uid, selected);
      if (context.mounted) {
        AppSnackbar.show(context, 'Role diubah menjadi $selected.');
      }
    } catch (_) {
      if (context.mounted) AppSnackbar.error(context, 'Gagal mengubah role.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Pengguna')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name.isEmpty ? '(Tanpa nama)' : user.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(
                      color: AppColors.textGrey, fontSize: 13),
                ),
                const Divider(height: 26),
                DetailRow(
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: user.role,
                ),
                DetailRow(
                  icon: Icons.chat_outlined,
                  label: 'Telepon',
                  value: user.phone,
                ),
                DetailRow(
                  icon: Icons.event_outlined,
                  label: 'Terdaftar',
                  value: Fmt.date(user.createdAt),
                ),
              ],
            ),
          ),
          if (user.role == Roles.bkk) ...[
            const SizedBox(height: 14),
            StreamBuilder<BkkProfile>(
              stream: BkkService.instance.watchProfile(user.uid),
              builder: (context, snap) {
                final p = snap.data ?? BkkProfile.empty(user.uid);
                return Container(
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
                        'Profil BKK',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DetailRow(
                        icon: Icons.store_outlined,
                        label: 'Nama BKK',
                        value: p.name,
                      ),
                      DetailRow(
                        icon: Icons.place_outlined,
                        label: 'Alamat',
                        value: p.address,
                      ),
                      DetailRow(
                        icon: Icons.verified_outlined,
                        label: 'Verifikasi',
                        value: p.verified ? 'Terverifikasi' : 'Belum',
                      ),
                      if (p.description.trim().isNotEmpty)
                        SectionBlock(
                            title: 'Deskripsi', content: p.description),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: p.verified
                              ? AppColors.danger
                              : AppColors.success,
                        ),
                        onPressed: () async {
                          try {
                            await BkkService.instance
                                .setVerified(user.uid, !p.verified);
                            if (context.mounted) {
                              AppSnackbar.show(
                                context,
                                p.verified
                                    ? 'Verifikasi dicabut.'
                                    : 'BKK berhasil diverifikasi.',
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              AppSnackbar.error(
                                  context, 'Gagal mengubah verifikasi.');
                            }
                          }
                        },
                        icon: Icon(
                          p.verified
                              ? Icons.remove_circle_outline
                              : Icons.verified_rounded,
                          size: 18,
                        ),
                        label: Text(
                            p.verified ? 'Cabut verifikasi' : 'Verifikasi BKK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _changeRole(context),
            icon: const Icon(Icons.manage_accounts_outlined, size: 18),
            label: const Text('Ubah role'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: user.phone.trim().isEmpty
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WhatsappComposeScreen(
                          targets: [
                            WaTarget(name: user.name, phone: user.phone),
                          ],
                        ),
                      ),
                    ),
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Kirim WhatsApp'),
          ),
        ],
      ),
    );
  }
}
