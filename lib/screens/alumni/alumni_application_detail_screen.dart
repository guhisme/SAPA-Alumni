import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../models/job_model.dart';
import '../../services/application_service.dart';
import '../../services/job_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/info_tile.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_badge.dart';
import 'alumni_job_detail_screen.dart';

class AlumniApplicationDetailScreen extends StatelessWidget {
  final String applicationId;
  const AlumniApplicationDetailScreen({super.key, required this.applicationId});

  Future<void> _cancel(BuildContext context, ApplicationModel app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan lamaran?'),
        content: const Text(
          'Lamaran akan dihapus. Anda masih bisa melamar lagi selama lowongan terbuka.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(110, 42),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApplicationService.instance.cancel(app);
      if (context.mounted) {
        Navigator.pop(context);
        AppSnackbar.show(context, 'Lamaran dibatalkan.');
      }
    } on ApplyException catch (e) {
      if (context.mounted) AppSnackbar.error(context, e.message);
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Gagal membatalkan lamaran.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Detail Lamaran')),
      body: StreamBuilder<ApplicationModel?>(
        stream: ApplicationService.instance.watchApplication(applicationId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return const ErrorView(message: 'Gagal memuat detail lamaran.');
          }
          final app = snap.data;
          if (app == null) {
            return const ErrorView(message: 'Lamaran tidak ditemukan.');
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
                      app.jobTitle.isEmpty ? 'Lowongan' : app.jobTitle,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.company,
                      style: const TextStyle(
                          color: AppColors.textGrey, fontSize: 13.5),
                    ),
                    const SizedBox(height: 12),
                    StatusBadge(app.status),
                    const Divider(height: 26),
                    DetailRow(
                      icon: Icons.event_available_outlined,
                      label: 'Dikirim',
                      value: Fmt.dateTime(app.appliedAt),
                    ),
                    DetailRow(
                      icon: Icons.tag,
                      label: 'Kode lamaran',
                      value: app.id.substring(0, app.id.length.clamp(0, 8)),
                    ),
                    if (app.note.isNotEmpty)
                      DetailRow(
                        icon: Icons.sticky_note_2_outlined,
                        label: 'Catatan BKK',
                        value: app.note,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _StatusTimeline(status: app.status),
              const SizedBox(height: 18),
              StreamBuilder<JobModel?>(
                stream: JobService.instance.watchJob(app.jobId),
                builder: (context, jobSnap) {
                  final job = jobSnap.data;
                  return OutlinedButton.icon(
                    onPressed: job == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AlumniJobDetailScreen(jobId: job.id),
                              ),
                            ),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: Text(job == null
                        ? 'Lowongan sudah dihapus'
                        : 'Lihat detail lowongan'),
                  );
                },
              ),
              if (app.status == AppStatus.menunggu) ...[
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: () => _cancel(context, app),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    minimumSize: const Size.fromHeight(46),
                  ),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Batalkan lamaran'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Garis waktu status: Menunggu -> Diproses -> Diterima/Ditolak.
class _StatusTimeline extends StatelessWidget {
  final String status;
  const _StatusTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = <_Step>[
      const _Step('Lamaran terkirim', 'Lamaran sudah masuk ke BKK.'),
      const _Step('Sedang diproses', 'BKK sedang meninjau berkas Anda.'),
      _Step(
        status == AppStatus.ditolak ? 'Ditolak' : 'Diterima',
        status == AppStatus.ditolak
            ? 'Lamaran belum sesuai kebutuhan perusahaan.'
            : 'Selamat, Anda diterima di perusahaan ini.',
      ),
    ];

    int activeIndex;
    switch (status) {
      case AppStatus.diproses:
        activeIndex = 1;
        break;
      case AppStatus.diterima:
      case AppStatus.ditolak:
        activeIndex = 2;
        break;
      default:
        activeIndex = 0;
    }

    final endColor =
        status == AppStatus.ditolak ? AppColors.danger : AppColors.success;

    return Container(
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
            'Perkembangan lamaran',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          ...List.generate(steps.length, (i) {
            final done = i <= activeIndex;
            final color = !done
                ? AppColors.border
                : (i == 2 ? endColor : AppColors.primary);
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      height: 18,
                      width: 18,
                      decoration: BoxDecoration(
                        color: done ? color : AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: done
                          ? const Icon(Icons.check,
                              size: 11, color: Colors.white)
                          : null,
                    ),
                    if (i != steps.length - 1)
                      Container(
                        width: 2,
                        height: 34,
                        color: i < activeIndex ? color : AppColors.border,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          steps[i].title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: done
                                ? AppColors.textDark
                                : AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          steps[i].subtitle,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textGrey,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _Step {
  final String title;
  final String subtitle;
  const _Step(this.title, this.subtitle);
}
