import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_badge.dart';
import 'alumni_application_detail_screen.dart';
import 'alumni_main_screen.dart';

class AlumniApplicationsScreen extends StatefulWidget {
  const AlumniApplicationsScreen({super.key});

  @override
  State<AlumniApplicationsScreen> createState() =>
      _AlumniApplicationsScreenState();
}

class _AlumniApplicationsScreenState extends State<AlumniApplicationsScreen> {
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Lamaran Saya')),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<ApplicationModel>>(
          stream: ApplicationService.instance.watchMyApplications(uid),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Memuat lamaran...');
            }
            if (snap.hasError) {
              return ErrorView(
                message: 'Gagal memuat lamaran. Periksa koneksi internet Anda.',
                onRetry: () => setState(() {}),
              );
            }

            final all = snap.data ?? [];
            final items = _filter.isEmpty
                ? all
                : all.where((a) => a.status == _filter).toList();

            return Column(
              children: [
                SizedBox(
                  height: 46,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _StatusFilter(
                        label: 'Semua',
                        selected: _filter.isEmpty,
                        onTap: () => setState(() => _filter = ''),
                      ),
                      ...AppStatus.all.map(
                        (s) => _StatusFilter(
                          label: Fmt.statusLabel(s),
                          selected: _filter == s,
                          onTap: () => setState(
                            () => _filter = _filter == s ? '' : s,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: items.isEmpty
                      ? EmptyState(
                          icon: Icons.assignment_outlined,
                          title: all.isEmpty
                              ? 'Belum ada lamaran'
                              : 'Tidak ada lamaran berstatus ini',
                          subtitle: all.isEmpty
                              ? 'Lamaran yang Anda kirim akan tampil di sini.'
                              : null,
                          action: all.isEmpty
                              ? SizedBox(
                                  width: 200,
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        goToAlumniTab(context, 1),
                                    child: const Text('Cari lowongan'),
                                  ),
                                )
                              : null,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) =>
                              _ApplicationCard(application: items[i]),
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

class _StatusFilter extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusFilter({
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
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final ApplicationModel application;
  const _ApplicationCard({required this.application});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AlumniApplicationDetailScreen(applicationId: application.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      application.jobTitle.isEmpty
                          ? 'Lowongan'
                          : application.jobTitle,
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
                  StatusBadge(application.status, small: true),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                application.company,
                style: const TextStyle(
                    color: AppColors.textGrey, fontSize: 13),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.schedule,
                      size: 14, color: AppColors.textGrey),
                  const SizedBox(width: 4),
                  Text(
                    'Dilamar ${Fmt.relative(application.appliedAt)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
