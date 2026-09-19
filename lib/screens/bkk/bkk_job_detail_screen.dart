import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../models/job_model.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import '../../services/job_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/info_tile.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_badge.dart';
import 'bkk_applicants_screen.dart';
import 'bkk_job_form_screen.dart';

class BkkJobDetailScreen extends StatelessWidget {
  final String jobId;
  const BkkJobDetailScreen({super.key, required this.jobId});

  Future<void> _delete(BuildContext context, JobModel job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus lowongan?'),
        content: const Text(
          'Lowongan beserta seluruh lamaran yang masuk akan dihapus permanen.',
        ),
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
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApplicationService.instance.deleteByJob(
        job.id,
        AuthService.instance.uid!,
      );
      await JobService.instance.delete(job.id);
      if (context.mounted) {
        Navigator.pop(context);
        AppSnackbar.show(context, 'Lowongan dihapus.');
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Gagal menghapus lowongan.');
      }
    }
  }

  Future<void> _toggleStatus(BuildContext context, JobModel job) async {
    final newStatus = job.status == AppStatus.jobOpen
        ? AppStatus.jobClosed
        : AppStatus.jobOpen;
    try {
      await JobService.instance.setStatus(job.id, newStatus);
      if (context.mounted) {
        AppSnackbar.show(
          context,
          newStatus == AppStatus.jobOpen
              ? 'Lowongan dibuka kembali.'
              : 'Lowongan ditutup.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Gagal mengubah status lowongan.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<JobModel?>(
        stream: JobService.instance.watchJob(jobId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: LoadingView());
          }
          final job = snap.data;
          if (job == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Detail Lowongan')),
              body: const ErrorView(message: 'Lowongan tidak ditemukan.'),
            );
          }

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Detail Lowongan'),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BkkJobFormScreen(job: job),
                          ),
                        );
                        break;
                      case 'status':
                        _toggleStatus(context, job);
                        break;
                      case 'delete':
                        _delete(context, job);
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'status',
                      child: Text(job.status == AppStatus.jobOpen
                          ? 'Tutup lowongan'
                          : 'Buka kembali'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Hapus',
                          style: TextStyle(color: AppColors.danger)),
                    ),
                  ],
                ),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.company,
                        style: const TextStyle(
                            color: AppColors.textGrey, fontSize: 13.5),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          StatusBadge(job.status),
                          if (job.isExpired) ...[
                            const SizedBox(width: 8),
                            const Text(
                              'Deadline terlewat',
                              style: TextStyle(
                                  color: AppColors.danger, fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                      const Divider(height: 26),
                      DetailRow(
                        icon: Icons.place_outlined,
                        label: 'Lokasi',
                        value: job.location,
                      ),
                      DetailRow(
                        icon: Icons.event_outlined,
                        label: 'Batas lamar',
                        value: Fmt.date(job.deadline),
                      ),
                      DetailRow(
                        icon: Icons.upload_file_outlined,
                        label: 'Dibuat',
                        value: Fmt.date(job.createdAt),
                      ),
                      SectionBlock(
                          title: 'Deskripsi pekerjaan',
                          content: job.description),
                      SectionBlock(
                          title: 'Persyaratan', content: job.requirements),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<ApplicationModel>>(
                  stream: ApplicationService.instance.watchApplicantsOfJob(
                    job.id,
                    AuthService.instance.uid!,
                  ),
                  builder: (context, appSnap) {
                    final total = (appSnap.data ?? []).length;
                    return ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BkkApplicantsScreen(
                            jobId: job.id,
                            jobTitle: job.title,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.people_outline, size: 18),
                      label: Text('Lihat pelamar ($total)'),
                    );
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BkkJobFormScreen(job: job),
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit lowongan'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
