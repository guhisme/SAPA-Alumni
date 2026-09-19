import 'package:flutter/material.dart';

import '../../models/alumni_profile.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/info_tile.dart';
import '../../widgets/loading_view.dart';
import 'whatsapp_compose_screen.dart';

/// Profil alumni yang dilihat oleh BKK atau Admin.
class AlumniDetailScreen extends StatelessWidget {
  final String uid;
  final String title;

  const AlumniDetailScreen({
    super.key,
    required this.uid,
    this.title = 'Profil Alumni',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<UserModel?>(
        stream: UserService.instance.watchUser(uid),
        builder: (context, userSnap) {
          if (userSnap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final user = userSnap.data;
          if (user == null) {
            return const ErrorView(message: 'Data alumni tidak ditemukan.');
          }

          return StreamBuilder<AlumniProfile>(
            stream: UserService.instance.watchAlumniProfile(uid),
            builder: (context, profileSnap) {
              final profile = profileSnap.data ?? AlumniProfile.empty(uid);

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
                              height: 56,
                              width: 56,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                Fmt.initials(user.name),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 19,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name.isEmpty ? 'Alumni' : user.name,
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.email,
                                    style: const TextStyle(
                                        color: AppColors.textGrey,
                                        fontSize: 12.5),
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
                        DetailRow(
                          icon: Icons.event_outlined,
                          label: 'Terdaftar',
                          value: Fmt.date(user.createdAt),
                        ),
                        if (profile.bio.trim().isNotEmpty)
                          SectionBlock(
                              title: 'Tentang', content: profile.bio),
                        const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: user.phone.trim().isEmpty
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WhatsappComposeScreen(
                                  targets: [
                                    WaTarget(
                                        name: user.name, phone: user.phone),
                                  ],
                                ),
                              ),
                            ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text(user.phone.trim().isEmpty
                        ? 'Nomor WhatsApp belum diisi'
                        : 'Kirim pesan WhatsApp'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
