import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Fmt {
  static final DateFormat _date = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

  static Timestamp? toTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value;
    return null;
  }

  static String date(Timestamp? value, {String fallback = '-'}) {
    if (value == null) return fallback;
    return _date.format(value.toDate());
  }

  static String dateTime(Timestamp? value, {String fallback = '-'}) {
    if (value == null) return fallback;
    return _dateTime.format(value.toDate());
  }

  /// "2 jam lalu", "3 hari lalu", dst.
  static String relative(Timestamp? value) {
    if (value == null) return '-';
    final diff = Timestamp.now().toDate().difference(value.toDate());
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 30) return '${diff.inDays} hari lalu';
    return date(value);
  }

  /// Sisa waktu menuju deadline.
  static String deadlineLabel(Timestamp? deadline) {
    if (deadline == null) return 'Tanpa deadline';
    final end = deadline.toDate().add(const Duration(hours: 23, minutes: 59));
    final diff = end.difference(Timestamp.now().toDate());
    if (diff.isNegative) return 'Sudah ditutup';
    if (diff.inDays == 0) return 'Ditutup hari ini';
    return 'Sisa ${diff.inDays} hari';
  }

  static bool isExpired(Timestamp? deadline) {
    if (deadline == null) return false;
    final end = deadline.toDate().add(const Duration(hours: 23, minutes: 59));
    return end.isBefore(Timestamp.now().toDate());
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'menunggu':
        return 'Menunggu';
      case 'diproses':
        return 'Diproses';
      case 'diterima':
        return 'Diterima';
      case 'ditolak':
        return 'Ditolak';
      case 'open':
        return 'Dibuka';
      case 'closed':
        return 'Ditutup';
      default:
        return status;
    }
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
