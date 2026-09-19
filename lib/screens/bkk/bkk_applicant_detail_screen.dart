import 'package:flutter/material.dart';

import '../../models/alumni_profile.dart';
import '../../models/application_model.dart';
import '../../models/user_model.dart';
import '../../services/application_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/info_tile.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_badge.dart';
import '../shared/whatsapp_compose_screen.dart';

/// Detail pelamar + ubah status lamaran.
class BkkApplicantDetailScreen extends StatelessWidget {
  final String applicationId;
  const BkkApplicantDetailScreen({super.key, required this.applicationId});

  Future<void> _changeStatus(
    BuildContext context,
    ApplicationModel app,
  ) async {
    String selected = app.status;
    final noteC = TextEditingController(text: app.note);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Ubah status lamaran'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...AppStatus.all.map(
                (s) => RadioListTile<String>(
                  value: s,
                  groupValue: selected,
                  onChanged: (v) => setLocal(() => selected = v ?? selected),
                  title: Text(Fmt.statusLabel(s)),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: noteC,
                maxLength: 150,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Catatan untuk alumni (opsional)',
                ),
              ),
            ],
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

    if (result != true) return;
    try {
      await ApplicationService.instance.updateStatus(
        application: app,
        status: selected,
        note: noteC.text,
      );
      if (context.mounted) {
        AppSnackbar.show(
          context,
          'Status diubah menjadi ${Fmt.statusLabel(selected)}.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Gagal mengubah status lamaran.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Pelamar')),
      body: StreamBuilder<ApplicationModel?>(
        stream: ApplicationService.instance.watchApplication(applicationId),
        builder: (context, appSnap) {
          if (appSnap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final app = appSnap.data;
          if (app == null) {
            return const ErrorView(message: 'Data lamaran tidak ditemukan.');
          }

          return StreamBuilder<UserModel?>(
            stream: UserService.instance.watchUser(app.alumniId),
            builder: (context, userSnap) {
              final user = userSnap.data;

              return StreamBuilder<AlumniProfile>(
                stream:
                    UserService.instance.watchAlumniProfile(app.alumniId),
                builder: (context, profileSnap) {
                  final profile =
                      profileSnap.data ?? AlumniProfile.empty(app.alumniId);

                  return ListView(
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
                            Row(
                              children: [
                                Container(
                                  height: 54,
                                  width: 54,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    user == null
                                        ? '?'
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.name ?? 'Memuat...',
                                        style: const TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user?.email ?? '',
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          color: AppColors.textGrey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 26),
                            DetailRow(
                              icon: Icons.chat_outlined,
                              label: 'WhatsApp',
                              value: user?.phone ?? '',
                            ),
                            DetailRow(
                              icon: Icons.calendar_today_outlined,
                              label: 'Tahun lulus',
                              value:
                                  profile.graduationYear?.toString() ?? '',
                            ),
                            DetailRow(
                              icon: Icons.menu_book_outlined,
                              label: 'Jurusan',
                              value: profile.major,
                            ),
                            if (profile.bio.trim().isNotEmpty)
                              SectionBlock(
                                  title: 'Tentang', content: profile.bio),
                            const SizedBox(height: 14),
                            const Text(
                              'Keahlian',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (profile.skills.isEmpty)
                              const Text(
                                'Belum diisi.',
                                style: TextStyle(
                                    color: AppColors.textGrey, fontSize: 13),
                              )
                            else
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: profile.skills
                                    .map((s) => Chip(label: Text(s)))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
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
                            const Text(
                              'Lamaran',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            DetailRow(
                              icon: Icons.work_outline,
                              label: 'Posisi',
                              value: app.jobTitle,
                            ),
                            DetailRow(
                              icon: Icons.apartment_outlined,
                              label: 'Perusahaan',
                              value: app.company,
                            ),
                            DetailRow(
                              icon: Icons.event_available_outlined,
                              label: 'Dikirim',
                              value: Fmt.dateTime(app.appliedAt),
                            ),
                            if (app.note.isNotEmpty)
                              DetailRow(
                                icon: Icons.sticky_note_2_outlined,
                                label: 'Catatan',
                                value: app.note,
                              ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text(
                                  'Status: ',
                                  style: TextStyle(
                                      color: AppColors.textGrey,
                                      fontSize: 13),
                                ),
                                StatusBadge(app.status),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _changeStatus(context, app),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: const Text('Ubah status lamaran'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: (user == null || user.phone.trim().isEmpty)
                            ? null
                            : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WhatsappComposeScreen(
                                      targets: [
                                        WaTarget(
                                          name: user.name,
                                          phone: user.phone,
                                        ),
                                      ],
                                      infoTitle: app.jobTitle,
                                    ),
                                  ),
                                ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text('Kirim WhatsApp'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
