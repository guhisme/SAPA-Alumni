import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/application_model.dart';
import '../../models/job_model.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import '../../services/bookmark_service.dart';
import '../../services/job_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/info_tile.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_badge.dart';

class AlumniJobDetailScreen extends StatefulWidget {
  final String jobId;
  const AlumniJobDetailScreen({super.key, required this.jobId});

  @override
  State<AlumniJobDetailScreen> createState() => _AlumniJobDetailScreenState();
}

class _AlumniJobDetailScreenState extends State<AlumniJobDetailScreen> {
  bool _applying = false;

  Future<void> _apply(JobModel job) async {
    final uid = AuthService.instance.uid;
    if (uid == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kirim lamaran?'),
        content: Text(
          'Lamaran untuk ${job.title} di ${job.company} akan dikirim ke BKK. '
          'Lamaran hanya bisa dikirim sekali untuk tiap lowongan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: const Size(90, 42)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _applying = true);
    try {
      await ApplicationService.instance.apply(job: job, alumniId: uid);
      if (mounted) AppSnackbar.show(context, 'Lamaran berhasil dikirim.');
    } on ApplyException catch (e) {
      if (mounted) AppSnackbar.error(context, e.message);
    } on FirebaseException catch (e) {
      if (mounted) {
        final message = switch (e.code) {
          'permission-denied' =>
            'Akses lamaran ditolak. Pastikan role akun Anda adalah alumni dan lowongan memiliki pemilik BKK yang valid.',
          'failed-precondition' =>
            'Data lowongan belum lengkap atau konfigurasi Firestore belum siap.',
          'unavailable' || 'network-request-failed' =>
            'Koneksi internet diperlukan untuk mengirim lamaran.',
          _ => 'Gagal mengirim lamaran (${e.code}).',
        };
        AppSnackbar.error(context, message);
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, 'Gagal mengirim lamaran. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Lowongan'),
        actions: [
          if (uid != null)
            StreamBuilder<bool>(
              stream: BookmarkService.instance.watchIsBookmarked(
                userId: uid,
                contentType: ContentType.job,
                contentId: widget.jobId,
              ),
              builder: (context, snap) {
                final saved = snap.data ?? false;
                return IconButton(
                  tooltip: saved ? 'Hapus dari bookmark' : 'Simpan ke bookmark',
                  icon: Icon(
                    saved ? Icons.bookmark_rounded : Icons.bookmark_outline,
                    color: saved ? AppColors.primary : null,
                  ),
                  onPressed: () async {
                    try {
                      final nowSaved = await BookmarkService.instance.toggle(
                        userId: uid,
                        contentType: ContentType.job,
                        contentId: widget.jobId,
                      );
                      if (context.mounted) {
                        AppSnackbar.show(
                          context,
                          nowSaved
                              ? 'Lowongan disimpan ke bookmark.'
                              : 'Lowongan dihapus dari bookmark.',
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        AppSnackbar.error(
                          context,
                          'Gagal memperbarui bookmark: ${error.toString()}',
                        );
                      }
                    }
                  },
                );
              },
            ),
        ],
      ),
      body: StreamBuilder<JobModel?>(
        stream: JobService.instance.watchJob(widget.jobId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return const ErrorView(message: 'Gagal memuat detail lowongan.');
          }
          final job = snap.data;
          if (job == null) {
            return const ErrorView(
              message: 'Lowongan tidak ditemukan atau sudah dihapus.',
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
                                height: 52,
                                width: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  Fmt.initials(job.company.isEmpty
                                      ? job.title
                                      : job.company),
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      job.title,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textDark,
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      job.company,
                                      style: const TextStyle(
                                        color: AppColors.textGrey,
                                        fontSize: 13.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              StatusBadge(job.status),
                              const SizedBox(width: 8),
                              if (job.isExpired)
                                const StatusBadge(AppStatus.jobClosed),
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
                            icon: Icons.timelapse_outlined,
                            label: 'Sisa waktu',
                            value: Fmt.deadlineLabel(job.deadline),
                          ),
                          DetailRow(
                            icon: Icons.upload_file_outlined,
                            label: 'Diposting',
                            value: Fmt.date(job.createdAt),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionBlock(
                            title: 'Deskripsi pekerjaan',
                            content: job.description,
                          ),
                          SectionBlock(
                            title: 'Persyaratan',
                            content: job.requirements,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (uid != null)
                _ApplyBar(
                    job: job, uid: uid, onApply: _apply, applying: _applying),
            ],
          );
        },
      ),
    );
  }
}

/// Tombol lamar beserta seluruh kondisi yang menonaktifkannya.
class _ApplyBar extends StatelessWidget {
  final JobModel job;
  final String uid;
  final bool applying;
  final Future<void> Function(JobModel job) onApply;

  const _ApplyBar({
    required this.job,
    required this.uid,
    required this.onApply,
    required this.applying,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ApplicationModel?>(
      stream: ApplicationService.instance
          .watchApplicationForJob(alumniId: uid, jobId: job.id),
      builder: (context, appSnap) {
        final existing = appSnap.data;

        return StreamBuilder<bool>(
          stream: ApplicationService.instance.watchHasAccepted(uid),
          builder: (context, acceptedSnap) {
            final hasAccepted = acceptedSnap.data ?? false;

            String? blockedReason;
            if (existing != null) {
              blockedReason = 'Anda sudah melamar lowongan ini';
            } else if (hasAccepted) {
              blockedReason =
                  'Anda sudah diterima di sebuah perusahaan, jadi tidak bisa melamar lagi';
            } else if (job.isClosed) {
              blockedReason = 'Lowongan ini sudah ditutup';
            } else if (job.isExpired) {
              blockedReason = 'Batas waktu lamaran sudah lewat';
            }

            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (existing != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Status lamaran Anda: ',
                            style: TextStyle(
                                color: AppColors.textGrey, fontSize: 13),
                          ),
                          StatusBadge(existing.status, small: true),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ] else if (blockedReason != null) ...[
                      Text(
                        blockedReason,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 12.5),
                      ),
                      const SizedBox(height: 10),
                    ],
                    ElevatedButton(
                      onPressed: (blockedReason != null || applying)
                          ? null
                          : () => onApply(job),
                      child: applying
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          : Text(existing != null
                              ? 'Sudah dilamar'
                              : 'Lamar sekarang'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
