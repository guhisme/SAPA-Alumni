import 'package:flutter/material.dart';

import '../../models/bkk_profile.dart';
import '../../services/bkk_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_view.dart';

class AdminBkkVerificationScreen extends StatelessWidget {
  const AdminBkkVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Verifikasi BKK'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textGrey,
            indicatorColor: AppColors.primary,
            tabs: [
              Tab(text: 'Menunggu'),
              Tab(text: 'Terverifikasi'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _BkkList(verified: false),
            _BkkList(verified: true),
          ],
        ),
      ),
    );
  }
}

class _BkkList extends StatelessWidget {
  final bool verified;
  const _BkkList({required this.verified});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BkkProfile>>(
      stream: BkkService.instance.watchAll(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const LoadingView();
        }
        if (snap.hasError) {
          return const ErrorView(message: 'Gagal memuat daftar BKK.');
        }
        final items =
            (snap.data ?? []).where((b) => b.verified == verified).toList();
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.store_outlined,
            title: verified
                ? 'Belum ada BKK terverifikasi'
                : 'Tidak ada permintaan verifikasi',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final b = items[i];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.name.isEmpty ? '(Nama BKK belum diisi)' : b.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.address.isEmpty ? 'Alamat belum diisi' : b.address,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textGrey),
                    ),
                    if (b.phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        b.phone,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textGrey),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(42),
                          backgroundColor:
                              verified ? AppColors.danger : AppColors.success,
                        ),
                        onPressed: () async {
                          try {
                            await BkkService.instance
                                .setVerified(b.uid, !verified);
                            if (context.mounted) {
                              AppSnackbar.show(
                                context,
                                verified
                                    ? 'Verifikasi dicabut.'
                                    : 'BKK diverifikasi.',
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              AppSnackbar.error(
                                  context, 'Gagal memperbarui verifikasi.');
                            }
                          }
                        },
                        icon: Icon(
                          verified
                              ? Icons.remove_circle_outline
                              : Icons.verified_rounded,
                          size: 18,
                        ),
                        label: Text(
                            verified ? 'Cabut verifikasi' : 'Verifikasi'),
                      ),
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
