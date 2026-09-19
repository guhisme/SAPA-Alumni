import 'package:flutter/material.dart';

import '../../models/job_model.dart';
import '../../services/auth_service.dart';
import '../../services/job_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/search_field.dart';
import '../../widgets/status_badge.dart';
import 'bkk_job_detail_screen.dart';
import 'bkk_job_form_screen.dart';

/// Daftar lowongan milik BKK yang sedang login.
class BkkJobsScreen extends StatefulWidget {
  const BkkJobsScreen({super.key});

  @override
  State<BkkJobsScreen> createState() => _BkkJobsScreenState();
}

class _BkkJobsScreenState extends State<BkkJobsScreen> {
  final _searchC = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Lowongan Saya')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BkkJobFormScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<JobModel>>(
          stream: JobService.instance.watchJobsByBkk(uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Memuat lowongan...');
            }
            if (snap.hasError) {
              return ErrorView(
                message: 'Gagal memuat lowongan.',
                onRetry: () => setState(() {}),
              );
            }
            final all = snap.data ?? [];
            final jobs = JobService.filter(all, query: _query);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: SearchField(
                    controller: _searchC,
                    hint: 'Cari lowongan saya',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: jobs.isEmpty
                      ? EmptyState(
                          icon: Icons.work_outline,
                          title: all.isEmpty
                              ? 'Belum ada lowongan'
                              : 'Tidak ada hasil',
                          subtitle: all.isEmpty
                              ? 'Tekan tombol Tambah untuk membuat lowongan pertama.'
                              : null,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                          itemCount: jobs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final job = jobs[i];
                            return Card(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        BkkJobDetailScreen(jobId: job.id),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              job.title,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 14.5,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textDark,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          StatusBadge(
                                            job.isExpired
                                                ? AppStatus.jobClosed
                                                : job.status,
                                            small: true,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        job.company,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textGrey),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(Icons.place_outlined,
                                              size: 14,
                                              color: AppColors.textGrey),
                                          const SizedBox(width: 4),
                                          Text(
                                            job.location.isEmpty
                                                ? '-'
                                                : job.location,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textGrey),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.event_outlined,
                                              size: 14,
                                              color: AppColors.textGrey),
                                          const SizedBox(width: 4),
                                          Text(
                                            Fmt.date(job.deadline),
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textGrey),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
