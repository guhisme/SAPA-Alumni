import 'package:flutter/material.dart';

import '../utils/app_colors.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Badge status lamaran / lowongan.
class StatusBadge extends StatelessWidget {
  final String status;
  final bool small;

  const StatusBadge(this.status, {super.key, this.small = false});

  Color get _color {
    switch (status) {
      case AppStatus.diterima:
      case AppStatus.jobOpen:
        return AppColors.success;
      case AppStatus.ditolak:
      case AppStatus.jobClosed:
        return AppColors.danger;
      case AppStatus.diproses:
        return AppColors.info;
      case AppStatus.menunggu:
        return AppColors.warning;
      default:
        return AppColors.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        Fmt.statusLabel(status),
        style: TextStyle(
          color: _color,
          fontSize: small ? 11 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
