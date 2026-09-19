import 'package:flutter/material.dart';

import '../../models/banner_model.dart';
import '../../services/info_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/loading_view.dart';

class AlumniBannerDetailScreen extends StatelessWidget {
  final String id;
  const AlumniBannerDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Informasi')),
      body: StreamBuilder<BannerModel?>(
        stream: InfoService.instance.watchBanner(id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return const ErrorView(message: 'Gagal memuat informasi.');
          }

          final item = snap.data;
          if (item == null || !item.isActive) {
            return const ErrorView(message: 'Informasi tidak ditemukan.');
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              if (item.imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 7,
                    child: Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surface,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 42,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  ),
                ),
              if (item.imageUrl.isNotEmpty) const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(18),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 14, color: AppColors.textGrey),
                        const SizedBox(width: 5),
                        Text(
                          Fmt.dateTime(item.createdAt),
                          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                        ),
                      ],
                    ),
                    if (item.content.isNotEmpty) ...[
                      const Divider(height: 26),
                      Text(
                        item.content,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
