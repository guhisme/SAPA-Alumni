import 'package:flutter/material.dart';

import '../../models/announcement_model.dart';
import '../../services/auth_service.dart';
import '../../services/info_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_view.dart';
import 'bookmark_button.dart';

class AlumniAnnouncementDetailScreen extends StatelessWidget {
  final String id;
  const AlumniAnnouncementDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengumuman'),
        actions: [
          if (uid != null)
            BookmarkButton(
              userId: uid,
              contentType: ContentType.announcement,
              contentId: id,
            ),
        ],
      ),
      body: StreamBuilder<AnnouncementModel?>(
        stream: InfoService.instance.watchAnnouncement(id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return const ErrorView(message: 'Gagal memuat pengumuman.');
          }
          final item = snap.data;
          if (item == null) {
            return const ErrorView(message: 'Pengumuman tidak ditemukan.');
          }

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
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 14, color: AppColors.textGrey),
                        const SizedBox(width: 5),
                        Text(
                          Fmt.dateTime(item.createdAt),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      item.content,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.7,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
