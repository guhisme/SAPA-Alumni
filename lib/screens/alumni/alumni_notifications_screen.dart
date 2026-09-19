import 'package:flutter/material.dart';

import '../../models/notification_model.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import 'alumni_announcement_detail_screen.dart';
import 'alumni_application_detail_screen.dart';
import 'alumni_job_detail_screen.dart';
import 'alumni_scholarship_detail_screen.dart';
import 'alumni_training_detail_screen.dart';

class AlumniNotificationsScreen extends StatelessWidget {
  const AlumniNotificationsScreen({super.key});

  void _open(BuildContext context, NotificationModel n) {
    NotificationService.instance.markAsRead(n.id);
    if (n.referenceId.isEmpty) return;

    Widget? page;
    switch (n.type) {
      case 'job':
        page = AlumniJobDetailScreen(jobId: n.referenceId);
        break;
      case 'application':
        page = AlumniApplicationDetailScreen(applicationId: n.referenceId);
        break;
      case 'scholarship':
        page = AlumniScholarshipDetailScreen(id: n.referenceId);
        break;
      case 'training':
        page = AlumniTrainingDetailScreen(id: n.referenceId);
        break;
      case 'announcement':
        page = AlumniAnnouncementDetailScreen(id: n.referenceId);
        break;
    }
    if (page == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
  }

  IconData _iconOf(String type) {
    switch (type) {
      case 'job':
        return Icons.work_rounded;
      case 'application':
        return Icons.assignment_turned_in_rounded;
      case 'scholarship':
        return Icons.school_rounded;
      case 'training':
        return Icons.model_training_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          TextButton(
            onPressed: () => NotificationService.instance.markAllAsRead(uid),
            child: const Text('Tandai dibaca'),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: NotificationService.instance.watchMyNotifications(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return const ErrorView(message: 'Gagal memuat notifikasi.');
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Belum ada notifikasi',
              subtitle:
                  'Pemberitahuan lowongan baru dan perubahan status lamaran akan muncul di sini.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final n = items[i];
              return Dismissible(
                key: ValueKey(n.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 18),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                onDismissed: (_) =>
                    NotificationService.instance.delete(n.id),
                child: Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _open(context, n),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 38,
                            width: 38,
                            decoration: BoxDecoration(
                              color: n.isRead
                                  ? AppColors.background
                                  : AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(
                              _iconOf(n.type),
                              size: 19,
                              color: n.isRead
                                  ? AppColors.textGrey
                                  : AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: n.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  n.body,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textGrey,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  Fmt.relative(n.createdAt),
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              margin: const EdgeInsets.only(top: 6, left: 6),
                              height: 8,
                              width: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
