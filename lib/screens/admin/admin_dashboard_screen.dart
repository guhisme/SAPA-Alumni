import 'package:flutter/material.dart';

import '../../models/bkk_profile.dart';
import '../../services/admin_service.dart';
import '../../services/bkk_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/section_header.dart';
import 'admin_bkk_verification_screen.dart';
import 'admin_main_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Dashboard Admin')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
          children: [
            const Text(
              'Ringkasan sistem',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _CountCard(
                  label: 'Alumni',
                  icon: Icons.school_rounded,
                  color: AppColors.primary,
                  stream:
                      AdminService.instance.watchUserCountByRole(Roles.alumni),
                  onTap: () => goToAdminTab(context, 1),
                ),
                const SizedBox(width: 12),
                _CountCard(
                  label: 'BKK',
                  icon: Icons.store_rounded,
                  color: AppColors.info,
                  stream: AdminService.instance.watchUserCountByRole(Roles.bkk),
                  onTap: () => goToAdminTab(context, 1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _CountCard(
                  label: 'Lowongan',
                  icon: Icons.work_rounded,
                  color: AppColors.success,
                  stream: AdminService.instance.watchCount(Col.jobs),
                ),
                const SizedBox(width: 12),
                _CountCard(
                  label: 'Lamaran',
                  icon: Icons.assignment_rounded,
                  color: AppColors.warning,
                  stream: AdminService.instance.watchCount(Col.applications),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _CountCard(
                  label: 'Beasiswa',
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.primaryDark,
                  stream: AdminService.instance.watchCount(Col.scholarships),
                  onTap: () => goToAdminTab(context, 2),
                ),
                const SizedBox(width: 12),
                _CountCard(
                  label: 'Pelatihan',
                  icon: Icons.model_training_rounded,
                  color: AppColors.info,
                  stream: AdminService.instance.watchCount(Col.trainings),
                  onTap: () => goToAdminTab(context, 2),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'BKK menunggu verifikasi'),
            const SizedBox(height: 8),
            StreamBuilder<List<BkkProfile>>(
              stream: BkkService.instance.watchPending(),
              builder: (context, snap) {
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 22),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'Tidak ada BKK yang menunggu verifikasi.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: AppColors.textGrey, fontSize: 13),
                    ),
                  );
                }
                return Column(
                  children: [
                    ...items.take(3).map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              child: ListTile(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                leading: const Icon(Icons.store_outlined,
                                    color: AppColors.warning),
                                title: Text(
                                  b.name.isEmpty ? 'BKK tanpa nama' : b.name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text(
                                  b.address.isEmpty ? '-' : b.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminBkkVerificationScreen(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminBkkVerificationScreen(),
                        ),
                      ),
                      child: Text('Kelola verifikasi (${items.length})'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Stream<int> stream;
  final VoidCallback? onTap;

  const _CountCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.stream,
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
              StreamBuilder<int>(
                stream: stream,
                builder: (context, snap) => Text(
                  snap.hasData ? '${snap.data}' : '-',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
