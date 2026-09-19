import 'package:flutter/material.dart';

import '../../models/bookmark_model.dart';
import '../../services/auth_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/info_service.dart';
import '../../services/job_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/info_card.dart';
import '../../widgets/loading_view.dart';
import 'alumni_announcement_detail_screen.dart';
import 'alumni_job_detail_screen.dart';
import 'alumni_main_screen.dart';
import 'alumni_scholarship_detail_screen.dart';
import 'alumni_training_detail_screen.dart';

/// Data ringkas hasil pencarian konten yang dibookmark.
class _BookmarkContent {
  final String title;
  final String subtitle;
  final bool exists;
  const _BookmarkContent(this.title, this.subtitle, {this.exists = true});
}

class AlumniBookmarkScreen extends StatelessWidget {
  const AlumniBookmarkScreen({super.key});

  Future<Map<String, _BookmarkContent>> _loadContents(
    List<BookmarkModel> bookmarks,
  ) async {
    final result = <String, _BookmarkContent>{};
    final jobs = await JobService.instance.getJobsByIds(bookmarks
        .where((b) => b.contentType == ContentType.job)
        .map((b) => b.contentId));
    final scholarships = await InfoService.instance.getScholarshipsByIds(
        bookmarks
            .where((b) => b.contentType == ContentType.scholarship)
            .map((b) => b.contentId));
    final trainings = await InfoService.instance.getTrainingsByIds(bookmarks
        .where((b) => b.contentType == ContentType.training)
        .map((b) => b.contentId));
    final announcements = await InfoService.instance.getAnnouncementsByIds(
        bookmarks
            .where((b) => b.contentType == ContentType.announcement)
            .map((b) => b.contentId));

    for (final b in bookmarks) {
      final content = switch (b.contentType) {
        ContentType.job => jobs[b.contentId] == null
            ? const _BookmarkContent('Lowongan sudah dihapus', '',
                exists: false)
            : _BookmarkContent(
                jobs[b.contentId]!.title, jobs[b.contentId]!.company),
        ContentType.scholarship => scholarships[b.contentId] == null
            ? const _BookmarkContent('Beasiswa sudah dihapus', '',
                exists: false)
            : _BookmarkContent(scholarships[b.contentId]!.title,
                scholarships[b.contentId]!.provider),
        ContentType.training => trainings[b.contentId] == null
            ? const _BookmarkContent('Pelatihan sudah dihapus', '',
                exists: false)
            : _BookmarkContent(trainings[b.contentId]!.title,
                trainings[b.contentId]!.provider),
        ContentType.announcement => announcements[b.contentId] == null
            ? const _BookmarkContent('Pengumuman sudah dihapus', '',
                exists: false)
            : _BookmarkContent(announcements[b.contentId]!.title,
                announcements[b.contentId]!.content),
        _ => const _BookmarkContent('Konten tidak dikenal', '', exists: false),
      };
      result[b.id] = content;
    }
    return result;
  }

  IconData _iconOf(String type) {
    switch (type) {
      case ContentType.job:
        return Icons.work_rounded;
      case ContentType.scholarship:
        return Icons.school_rounded;
      case ContentType.training:
        return Icons.model_training_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  Color _colorOf(String type) {
    switch (type) {
      case ContentType.job:
        return AppColors.primary;
      case ContentType.scholarship:
        return AppColors.success;
      case ContentType.training:
        return AppColors.info;
      default:
        return AppColors.warning;
    }
  }

  void _open(BuildContext context, BookmarkModel b) {
    Widget? page;
    switch (b.contentType) {
      case ContentType.job:
        page = AlumniJobDetailScreen(jobId: b.contentId);
        break;
      case ContentType.scholarship:
        page = AlumniScholarshipDetailScreen(id: b.contentId);
        break;
      case ContentType.training:
        page = AlumniTrainingDetailScreen(id: b.contentId);
        break;
      case ContentType.announcement:
        page = AlumniAnnouncementDetailScreen(id: b.contentId);
        break;
    }
    if (page == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bookmark')),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<BookmarkModel>>(
          stream: BookmarkService.instance.watchBookmarks(uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Memuat bookmark...');
            }
            if (snap.hasError) {
              return const ErrorView(message: 'Gagal memuat bookmark.');
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return EmptyState(
                icon: Icons.bookmark_outline,
                title: 'Belum ada bookmark',
                subtitle:
                    'Tekan ikon bookmark pada lowongan atau informasi untuk menyimpannya di sini.',
                action: SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () => goToAlumniTab(context, 2),
                    child: const Text('Lihat informasi'),
                  ),
                ),
              );
            }

            return FutureBuilder<Map<String, _BookmarkContent>>(
              future: _loadContents(items),
              builder: (context, contentSnap) {
                if (contentSnap.connectionState == ConnectionState.waiting) {
                  return const LoadingView(message: 'Memuat isi bookmark...');
                }
                final contents = contentSnap.data ?? {};
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final b = items[i];
                    final content = contents[b.id];
                    return InfoCard(
                      icon: _iconOf(b.contentType),
                      iconColor: _colorOf(b.contentType),
                      title: content?.title ?? 'Memuat...',
                      subtitle: content?.subtitle ?? '',
                      onTap: () {
                        if (content != null && !content.exists) {
                          AppSnackbar.error(
                            context,
                            'Konten sudah tidak tersedia.',
                          );
                          return;
                        }
                        _open(context, b);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.bookmark_remove_outlined,
                            size: 20, color: AppColors.textGrey),
                        onPressed: () async {
                          await BookmarkService.instance.remove(b.id);
                          if (context.mounted) {
                            AppSnackbar.show(context, 'Bookmark dihapus.');
                          }
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
