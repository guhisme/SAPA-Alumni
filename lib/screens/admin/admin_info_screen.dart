import 'package:flutter/material.dart';

import '../../models/announcement_model.dart';
import '../../models/scholarship_model.dart';
import '../../models/training_model.dart';
import '../../services/admin_service.dart';
import '../../services/info_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/info_card.dart';
import '../../widgets/loading_view.dart';
import 'admin_announcement_form_screen.dart';
import 'admin_scholarship_form_screen.dart';
import 'admin_training_form_screen.dart';

/// Kelola pengumuman, beasiswa, dan pelatihan.
class AdminInfoScreen extends StatefulWidget {
  const AdminInfoScreen({super.key});

  @override
  State<AdminInfoScreen> createState() => _AdminInfoScreenState();
}

class _AdminInfoScreenState extends State<AdminInfoScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _add() {
    Widget page;
    switch (_tab.index) {
      case 1:
        page = const AdminScholarshipFormScreen();
        break;
      case 2:
        page = const AdminTrainingFormScreen();
        break;
      default:
        page = const AdminAnnouncementFormScreen();
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Kelola Informasi'),
        bottom: TabBar(
          controller: _tab,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textGrey,
          indicatorColor: AppColors.primary,
          labelStyle:
              const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Pengumuman'),
            Tab(text: 'Beasiswa'),
            Tab(text: 'Pelatihan'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _add,
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: SafeArea(
        top: false,
        child: TabBarView(
          controller: _tab,
          children: const [
            _AnnouncementManage(),
            _ScholarshipManage(),
            _TrainingManage(),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, String name) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Hapus data?'),
      content: Text('"$name" akan dihapus permanen.'),
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
  return result == true;
}

class _AnnouncementManage extends StatelessWidget {
  const _AnnouncementManage();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AnnouncementModel>>(
      stream: InfoService.instance.watchAnnouncements(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.campaign_outlined,
            title: 'Belum ada pengumuman',
            subtitle: 'Tekan Tambah untuk membuat pengumuman baru.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
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
                  builder: (_) => AdminAnnouncementFormScreen(item: a),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.danger),
                onPressed: () async {
                  if (!await _confirmDelete(context, a.title)) return;
                  await AdminService.instance.deleteAnnouncement(a.id);
                  if (context.mounted) {
                    AppSnackbar.show(context, 'Pengumuman dihapus.');
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _ScholarshipManage extends StatelessWidget {
  const _ScholarshipManage();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScholarshipModel>>(
      stream: InfoService.instance.watchScholarships(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.school_outlined,
            title: 'Belum ada beasiswa',
            subtitle: 'Tekan Tambah untuk membuat informasi beasiswa.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final s = items[i];
            return InfoCard(
              icon: Icons.school_rounded,
              title: s.title,
              subtitle: s.provider,
              trailingText: Fmt.deadlineLabel(s.deadline),
              trailingDanger: s.isExpired,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminScholarshipFormScreen(item: s),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.danger),
                onPressed: () async {
                  if (!await _confirmDelete(context, s.title)) return;
                  await AdminService.instance.deleteScholarship(s.id);
                  if (context.mounted) {
                    AppSnackbar.show(context, 'Beasiswa dihapus.');
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _TrainingManage extends StatelessWidget {
  const _TrainingManage();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TrainingModel>>(
      stream: InfoService.instance.watchTrainings(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.model_training_outlined,
            title: 'Belum ada pelatihan',
            subtitle: 'Tekan Tambah untuk membuat informasi pelatihan.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final t = items[i];
            return InfoCard(
              icon: Icons.model_training_rounded,
              iconColor: AppColors.info,
              title: t.title,
              subtitle: t.provider,
              trailingText: Fmt.deadlineLabel(t.deadline),
              trailingDanger: t.isExpired,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminTrainingFormScreen(item: t),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppColors.danger),
                onPressed: () async {
                  if (!await _confirmDelete(context, t.title)) return;
                  await AdminService.instance.deleteTraining(t.id);
                  if (context.mounted) {
                    AppSnackbar.show(context, 'Pelatihan dihapus.');
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
