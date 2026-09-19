import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../models/user_model.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/status_badge.dart';
import '../shared/whatsapp_compose_screen.dart';
import 'bkk_applicant_detail_screen.dart';

/// Daftar pelamar. Tanpa [jobId] menampilkan seluruh pelamar milik BKK.
class BkkApplicantsScreen extends StatefulWidget {
  final String? jobId;
  final String? jobTitle;

  const BkkApplicantsScreen({super.key, this.jobId, this.jobTitle});

  @override
  State<BkkApplicantsScreen> createState() => _BkkApplicantsScreenState();
}

class _BkkApplicantsScreenState extends State<BkkApplicantsScreen> {
  String _filter = '';
  late final Stream<List<ApplicationModel>> _applicationsStream;

  @override
  void initState() {
    super.initState();
    final uid = AuthService.instance.uid;
    _applicationsStream = widget.jobId == null
        ? ApplicationService.instance.watchApplicantsOfBkk(uid ?? '')
        : ApplicationService.instance.watchApplicantsOfJob(
            widget.jobId!,
            uid ?? '',
          );
  }

  Future<void> _broadcast(
    List<ApplicationModel> apps,
    Map<String, UserModel> users,
  ) async {
    final targets = <WaTarget>[];
    for (final a in apps) {
      final user = users[a.alumniId];
      if (user != null && user.phone.trim().isNotEmpty) {
        targets.add(WaTarget(name: user.name, phone: user.phone));
      }
    }
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WhatsappComposeScreen(
          targets: targets,
          infoTitle: widget.jobTitle ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.uid;
    if (uid == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.jobTitle == null ? 'Pelamar' : 'Pelamar Lowongan'),
        automaticallyImplyLeading: widget.jobId != null,
      ),
      body: SafeArea(
        top: false,
        child: StreamBuilder<List<ApplicationModel>>(
          stream: _applicationsStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const LoadingView(message: 'Memuat pelamar...');
            }
            if (snap.hasError) {
              return ErrorView(
                message: 'Gagal memuat data pelamar.',
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
                      _Chip(
                        label: 'Semua (${all.length})',
                        selected: _filter.isEmpty,
                        onTap: () => setState(() => _filter = ''),
                      ),
                      ...AppStatus.all.map((s) {
                        final count = all.where((a) => a.status == s).length;
                        return _Chip(
                          label: '${Fmt.statusLabel(s)} ($count)',
                          selected: _filter == s,
                          onTap: () =>
                              setState(() => _filter = _filter == s ? '' : s),
                        );
                      }),
                    ],
                  ),
                ),
                if (items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final users = await UserService.instance
                            .getUsersByIds(items.map((a) => a.alumniId));
                        if (mounted) await _broadcast(items, users);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(42),
                      ),
                      icon: const Icon(Icons.chat_bubble_outline, size: 17),
                      label: Text(
                          'Kirim WhatsApp ke ${items.length} pelamar terpilih'),
                    ),
                  ),
                Expanded(
                  child: items.isEmpty
                      ? EmptyState(
                          icon: Icons.people_outline,
                          title: all.isEmpty
                              ? 'Belum ada pelamar'
                              : 'Tidak ada pelamar berstatus ini',
                          subtitle: all.isEmpty
                              ? 'Lamaran yang masuk akan tampil di sini.'
                              : null,
                        )
                      : FutureBuilder<Map<String, UserModel>>(
                          future: UserService.instance.getUsersByIds(
                            items.map((a) => a.alumniId),
                          ),
                          builder: (context, userSnap) {
                            final users = userSnap.data ?? const {};
                            if (userSnap.connectionState ==
                                ConnectionState.waiting) {
                              return const LoadingView(
                                  message: 'Memuat data pelamar...');
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (context, i) => _ApplicantTile(
                                application: items[i],
                                user: users[items[i].alumniId],
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

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
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

class _ApplicantTile extends StatelessWidget {
  final ApplicationModel application;
  final UserModel? user;
  const _ApplicantTile({required this.application, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                BkkApplicantDetailScreen(applicationId: application.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Builder(
            builder: (context) {
              final name = user?.name ?? 'Data alumni tidak ditemukan';
              return Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user == null ? '?' : Fmt.initials(user!.name),
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          application.jobTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textGrey),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          Fmt.relative(application.appliedAt),
                          style: const TextStyle(
                              fontSize: 11.5, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(application.status, small: true),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
