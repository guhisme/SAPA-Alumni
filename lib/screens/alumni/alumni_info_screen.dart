import 'package:flutter/material.dart';

import '../../models/announcement_model.dart';
import '../../models/scholarship_model.dart';
import '../../models/training_model.dart';
import '../../services/info_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/info_card.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/search_field.dart';
import 'alumni_announcement_detail_screen.dart';
import 'alumni_scholarship_detail_screen.dart';
import 'alumni_training_detail_screen.dart';

/// Tiga jenis informasi: pengumuman, beasiswa, pelatihan.
class AlumniInfoScreen extends StatelessWidget {
  const AlumniInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Informasi'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textGrey,
            indicatorColor: AppColors.primary,
            labelStyle: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            tabs: [
              Tab(text: 'Pengumuman'),
              Tab(text: 'Beasiswa'),
              Tab(text: 'Pelatihan'),
            ],
          ),
        ),
        body: const SafeArea(
          top: false,
          child: TabBarView(
            children: [
              _AnnouncementTab(),
              _ScholarshipTab(),
              _TrainingTab(),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementTab extends StatelessWidget {
  const _AnnouncementTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AnnouncementModel>>(
      stream: InfoService.instance.watchAnnouncements(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'Memuat pengumuman...');
        }
        if (snap.hasError) {
          return const ErrorView(message: 'Gagal memuat pengumuman.');
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.campaign_outlined,
            title: 'Belum ada pengumuman',
            subtitle:
                'Pengumuman dari sekolah, termasuk pengambilan ijazah, akan tampil di sini.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final a = items[i];
            return InfoCard(
              icon: Icons.campaign_rounded,
              iconColor: AppColors.warning,
              title: a.title,
              subtitle: a.content,
              trailingText: Fmt.relative(a.createdAt),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AlumniAnnouncementDetailScreen(id: a.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ScholarshipTab extends StatefulWidget {
  const _ScholarshipTab();

  @override
  State<_ScholarshipTab> createState() => _ScholarshipTabState();
}

class _ScholarshipTabState extends State<_ScholarshipTab> {
  final _searchC = TextEditingController();
  late final Stream<List<ScholarshipModel>> _scholarshipStream =
      InfoService.instance.watchScholarships();
  String _query = '';

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScholarshipModel>>(
      stream: _scholarshipStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'Memuat beasiswa...');
        }
        if (snap.hasError) {
          return const ErrorView(message: 'Gagal memuat informasi beasiswa.');
        }
        final all = snap.data ?? [];
        final q = _query.trim().toLowerCase();
        final items = q.isEmpty
            ? all
            : all.where((s) => s.searchText.contains(q)).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SearchField(
                controller: _searchC,
                hint: 'Cari beasiswa',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? EmptyState(
                      icon: Icons.school_outlined,
                      title: all.isEmpty
                          ? 'Belum ada informasi beasiswa'
                          : 'Beasiswa tidak ditemukan',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final s = items[i];
                        return InfoCard(
                          icon: Icons.school_rounded,
                          iconColor: AppColors.primary,
                          title: s.title,
                          subtitle:
                              s.provider.isEmpty ? s.description : s.provider,
                          trailingText: s.deadline == null
                              ? ''
                              : Fmt.deadlineLabel(s.deadline),
                          trailingDanger: s.isExpired,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AlumniScholarshipDetailScreen(id: s.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _TrainingTab extends StatefulWidget {
  const _TrainingTab();

  @override
  State<_TrainingTab> createState() => _TrainingTabState();
}

class _TrainingTabState extends State<_TrainingTab> {
  final _searchC = TextEditingController();
  late final Stream<List<TrainingModel>> _trainingStream =
      InfoService.instance.watchTrainings();
  String _query = '';

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TrainingModel>>(
      stream: _trainingStream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingView(message: 'Memuat pelatihan...');
        }
        if (snap.hasError) {
          return const ErrorView(message: 'Gagal memuat informasi pelatihan.');
        }
        final all = snap.data ?? [];
        final q = _query.trim().toLowerCase();
        final items = q.isEmpty
            ? all
            : all.where((t) => t.searchText.contains(q)).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SearchField(
                controller: _searchC,
                hint: 'Cari pelatihan',
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? EmptyState(
                      icon: Icons.model_training_outlined,
                      title: all.isEmpty
                          ? 'Belum ada informasi pelatihan'
                          : 'Pelatihan tidak ditemukan',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final t = items[i];
                        return InfoCard(
                          icon: Icons.model_training_rounded,
                          iconColor: AppColors.info,
                          title: t.title,
                          subtitle: t.provider.isEmpty
                              ? t.description
                              : '${t.provider}${t.mode.isEmpty ? '' : ' - ${t.mode}'}',
                          trailingText: t.deadline == null
                              ? ''
                              : Fmt.deadlineLabel(t.deadline),
                          trailingDanger: t.isExpired,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AlumniTrainingDetailScreen(id: t.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
