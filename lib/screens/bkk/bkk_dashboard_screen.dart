import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../models/bkk_profile.dart';
import '../../models/job_model.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import '../../services/bkk_service.dart';
import '../../services/job_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_badge.dart';
import 'bkk_applicant_detail_screen.dart';
import 'bkk_job_form_screen.dart';
import 'bkk_main_screen.dart';

class BkkDashboardScreen extends StatelessWidget {
  const BkkDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard BKK'),
        actions: [
          IconButton(
            tooltip: 'Tambah lowongan',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BkkJobFormScreen()),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<BkkProfile>(
          stream: BkkService.instance.watchProfile(uid),
          builder: (context, profileSnap) {
            final profile = profileSnap.data ?? BkkProfile.empty(uid);

            return StreamBuilder<List<JobModel>>(
              stream: JobService.instance.watchJobsByBkk(uid),
              builder: (context, jobSnap) {
                if (jobSnap.connectionState == ConnectionState.waiting) {
                  return const LoadingView();
                }
                final jobs = jobSnap.data ?? [];
                final openJobs =
                    jobs.where((j) => j.status == AppStatus.jobOpen).length;

                return StreamBuilder<List<ApplicationModel>>(
                  stream: ApplicationService.instance.watchApplicantsOfBkk(uid),
                  builder: (context, appSnap) {
                    final apps = appSnap.data ?? [];
                    int count(String s) =>
                        apps.where((a) => a.status == s).length;

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
                      children: [
                        if (!profile.verified)
                          Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.5)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.pending_outlined,
                                    color: AppColors.warning, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Akun BKK Anda menunggu verifikasi admin. '
                                    'Lengkapi profil BKK agar lebih cepat diverifikasi.',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textDark,
                                        height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          profile.name.isEmpty ? 'BKK' : profile.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _StatCard(
                              label: 'Lowongan aktif',
                              value: '$openJobs',
                              icon: Icons.work_rounded,
                              color: AppColors.primary,
                              onTap: () => goToBkkTab(context, 1),
                            ),
                            const SizedBox(width: 12),
                            _StatCard(
                              label: 'Total pelamar',
                              value: '${apps.length}',
                              icon: Icons.people_rounded,
                              color: AppColors.info,
                              onTap: () => goToBkkTab(context, 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatCard(
                              label: 'Perlu ditinjau',
                              value: '${count(AppStatus.menunggu)}',
                              icon: Icons.hourglass_empty_rounded,
                              color: AppColors.warning,
                              onTap: () => goToBkkTab(context, 2),
                            ),
                            const SizedBox(width: 12),
                            _StatCard(
                              label: 'Diterima',
                              value: '${count(AppStatus.diterima)}',
                              icon: Icons.verified_rounded,
                              color: AppColors.success,
                              onTap: () => goToBkkTab(context, 2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        SectionHeader(
                          title: 'Pelamar terbaru',
                          actionLabel: 'Lihat semua',
                          onAction: () => goToBkkTab(context, 2),
                        ),
                        const SizedBox(height: 8),
                        if (apps.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Text(
                              'Belum ada pelamar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.textGrey, fontSize: 13),
                            ),
                          )
                        else
                          ...apps.take(5).map(
                                (a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Card(
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: Text(
                                        a.jobTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        Fmt.relative(a.appliedAt),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      trailing:
                                          StatusBadge(a.status, small: true),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              BkkApplicantDetailScreen(
                                            applicationId: a.id,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ],
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
