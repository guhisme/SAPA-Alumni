import 'package:flutter/material.dart';

import '../../models/job_model.dart';
import '../../services/job_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/job_card.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/search_field.dart';
import 'alumni_job_detail_screen.dart';

class AlumniJobsScreen extends StatefulWidget {
  const AlumniJobsScreen({super.key});

  @override
  State<AlumniJobsScreen> createState() => _AlumniJobsScreenState();
}

class _AlumniJobsScreenState extends State<AlumniJobsScreen> {
  final _searchC = TextEditingController();
  late final Stream<List<JobModel>> _jobsStream =
      JobService.instance.watchOpenJobs();
  String _query = '';
  String _location = '';

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Lowongan Kerja')),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<JobModel>>(
          stream: _jobsStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Memuat lowongan...');
            }
            if (snap.hasError) {
              return ErrorView(
                message:
                    'Gagal memuat lowongan. Periksa koneksi internet Anda.',
                onRetry: () => setState(() {}),
              );
            }

            final all = snap.data ?? [];
            final locations = JobService.locationsOf(all);
            final jobs = JobService.filter(
              all,
              query: _query,
              location: _location,
            );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: SearchField(
                    controller: _searchC,
                    hint: 'Cari posisi atau perusahaan',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                if (locations.isNotEmpty)
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _FilterChipItem(
                          label: 'Semua lokasi',
                          selected: _location.isEmpty,
                          onTap: () => setState(() => _location = ''),
                        ),
                        ...locations.map(
                          (loc) => _FilterChipItem(
                            label: loc,
                            selected: _location == loc,
                            onTap: () => setState(
                              () => _location = _location == loc ? '' : loc,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 4),
                Expanded(
                  child: jobs.isEmpty
                      ? EmptyState(
                          icon: Icons.work_off_outlined,
                          title: all.isEmpty
                              ? 'Belum ada lowongan'
                              : 'Tidak ada hasil pencarian',
                          subtitle: all.isEmpty
                              ? 'Lowongan baru dari BKK akan muncul di sini.'
                              : 'Coba kata kunci atau filter lokasi yang lain.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: jobs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) => JobCard(
                            job: jobs[i],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AlumniJobDetailScreen(jobId: jobs[i].id),
                              ),
                            ),
                          ),
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

class _FilterChipItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChipItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary,
        side: const BorderSide(color: AppColors.border),
        labelStyle: TextStyle(
          fontSize: 12.5,
          color: selected ? Colors.white : AppColors.textDark,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
