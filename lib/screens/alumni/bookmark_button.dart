import 'package:flutter/material.dart';

import '../../services/bookmark_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_snackbar.dart';

/// Tombol simpan/hapus bookmark yang dipakai di semua halaman detail.
class BookmarkButton extends StatelessWidget {
  final String userId;
  final String contentType;
  final String contentId;

  const BookmarkButton({
    super.key,
    required this.userId,
    required this.contentType,
    required this.contentId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: BookmarkService.instance.watchIsBookmarked(
        userId: userId,
        contentType: contentType,
        contentId: contentId,
      ),
      builder: (context, snap) {
        final saved = snap.data ?? false;
        return IconButton(
          tooltip: saved ? 'Hapus dari bookmark' : 'Simpan ke bookmark',
          icon: Icon(
            saved ? Icons.bookmark_rounded : Icons.bookmark_outline,
            color: saved ? AppColors.primary : null,
          ),
          onPressed: () async {
            try {
              final nowSaved = await BookmarkService.instance.toggle(
                userId: userId,
                contentType: contentType,
                contentId: contentId,
              );
              if (context.mounted) {
                AppSnackbar.show(
                  context,
                  nowSaved ? 'Disimpan ke bookmark.' : 'Dihapus dari bookmark.',
                );
              }
            } catch (error) {
              if (context.mounted) {
                AppSnackbar.error(
                  context,
                  'Gagal memperbarui bookmark: ${error.toString()}',
                );
              }
            }
          },
        );
      },
    );
  }
}
