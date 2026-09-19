import 'package:cloud_functions/cloud_functions.dart';

/// Pemanggilan pengiriman WhatsApp lewat Cloud Functions.
///
/// PENTING: token Fonnte TIDAK BOLEH ada di aplikasi Flutter.
/// Flutter hanya memanggil function `sendWhatsapp`; token disimpan sebagai
/// environment variable di Cloud Functions (lihat SETUP.md).
///
/// Dipakai oleh halaman Admin/BKK pada tahap berikutnya.
class WhatsappService {
  WhatsappService._();
  static final WhatsappService instance = WhatsappService._();

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-southeast2');

  /// [targets] berisi daftar { 'name': ..., 'phone': ... }.
  /// [message] boleh memakai placeholder {nama} dan {judul_informasi}.
  Future<Map<String, dynamic>> sendMessage({
    required List<Map<String, String>> targets,
    required String message,
    String infoTitle = '',
  }) async {
    final callable = _functions.httpsCallable('sendWhatsapp');
    final result = await callable.call<Map<String, dynamic>>({
      'targets': targets,
      'message': message,
      'infoTitle': infoTitle,
    });
    return Map<String, dynamic>.from(result.data);
  }
}
