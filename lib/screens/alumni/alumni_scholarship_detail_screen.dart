import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/scholarship_model.dart';
import '../../services/auth_service.dart';
import '../../services/info_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/info_tile.dart';
import '../../widgets/loading_view.dart';
import 'bookmark_button.dart';

class AlumniScholarshipDetailScreen extends StatelessWidget {
  final String id;
  const AlumniScholarshipDetailScreen({super.key, required this.id});

  Future<void> _openLink(BuildContext context, String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) {
      AppSnackbar.error(context, 'Tautan tidak valid.');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppSnackbar.error(context, 'Tidak bisa membuka tautan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detail Beasiswa'),
        actions: [
          if (uid != null)
            BookmarkButton(
              userId: uid,
              contentType: ContentType.scholarship,
              contentId: id,
            ),
        ],
      ),
      body: StreamBuilder<ScholarshipModel?>(
        stream: InfoService.instance.watchScholarship(id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return const ErrorView(message: 'Gagal memuat detail beasiswa.');
          }
          final item = snap.data;
          if (item == null) {
            return const ErrorView(message: 'Informasi tidak ditemukan.');
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DetailRow(
                      icon: Icons.apartment_outlined,
                      label: 'Penyelenggara',
                      value: item.provider,
                    ),
                    DetailRow(
                      icon: Icons.event_outlined,
                      label: 'Batas daftar',
                      value: Fmt.date(item.deadline),
                    ),
                    DetailRow(
                      icon: Icons.timelapse_outlined,
                      label: 'Sisa waktu',
                      value: Fmt.deadlineLabel(item.deadline),
                    ),
                    SectionBlock(title: 'Deskripsi', content: item.description),
                    SectionBlock(
                        title: 'Persyaratan', content: item.requirements),
                    SectionBlock(title: 'Manfaat', content: item.benefits),
                  ],
                ),
              ),
              if (item.link.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _openLink(context, item.link.trim()),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Buka tautan pendaftaran'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
