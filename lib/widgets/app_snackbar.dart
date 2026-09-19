import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Pemberitahuan singkat yang konsisten di seluruh aplikasi.
class AppSnackbar {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.danger : AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
  }

  static void error(BuildContext context, String message) =>
      show(context, message, isError: true);
}
