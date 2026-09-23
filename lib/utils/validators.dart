import 'package:cloud_firestore/cloud_firestore.dart';

/// Kumpulan validator form.
class Validators {
  static String? required(String? value, {String field = 'Field ini'}) {
    if (value == null || value.trim().isEmpty) return '$field wajib diisi';
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email wajib diisi';
    final regex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$');
    if (!regex.hasMatch(value.trim())) return 'Format email tidak valid';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password wajib diisi';
    if (value.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }
    if (value != password) return 'Password tidak sama';
    return null;
  }

  /// Nomor WhatsApp Indonesia: 08xxxx / 628xxxx / +628xxxx (10-15 digit).
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nomor WhatsApp wajib diisi';
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 11 || digits.length > 13) {
      return 'Nomor WhatsApp harus 11-13 digit';
    }
    if (!(digits.startsWith('08') || digits.startsWith('628'))) {
      return 'Gunakan format 08xxx atau 628xxx';
    }
    return null;
  }

  static String? graduationYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Tahun lulus wajib diisi';
    }
    final year = int.tryParse(value.trim());
    if (year == null) return 'Tahun lulus harus berupa angka';
    final now = Timestamp.now().toDate().year;
    if (year < 1980 || year > now + 1) {
      return 'Tahun lulus antara 1980 - ${now + 1}';
    }
    return null;
  }

  /// Normalisasi nomor ke format 62xxxxxxxxx (dipakai backend Fonnte).
  static String normalizePhone(String value) {
    var digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('0')) digits = '62${digits.substring(1)}';
    return digits;
  }
}
