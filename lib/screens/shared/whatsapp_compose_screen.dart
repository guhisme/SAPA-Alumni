import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/app_snackbar.dart';

/// Penerima pesan WhatsApp.
class WaTarget {
  final String name;
  final String phone;
  const WaTarget({required this.name, required this.phone});
}

/// Layar tulis dan kirim pesan WhatsApp lewat backend (Fonnte).
/// Token Fonnte tidak pernah ada di sisi Flutter.
class WhatsappComposeScreen extends StatefulWidget {
  final List<WaTarget> targets;
  final String infoTitle;
  final String initialMessage;

  const WhatsappComposeScreen({
    super.key,
    required this.targets,
    this.infoTitle = '',
    this.initialMessage = '',
  });

  @override
  State<WhatsappComposeScreen> createState() => _WhatsappComposeScreenState();
}

class _WhatsappComposeScreenState extends State<WhatsappComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _messageC = TextEditingController(
    text: widget.initialMessage.isNotEmpty
        ? widget.initialMessage
        : 'Halo {nama}, terdapat informasi baru dari SAPA Alumni mengenai '
            '{judul_informasi}. Silakan buka aplikasi SAPA Alumni untuk melihat '
            'informasi lengkap.',
  );
  late final _titleC = TextEditingController(text: widget.infoTitle);

  @override
  void dispose() {
    _messageC.dispose();
    _titleC.dispose();
    super.dispose();
  }

  List<WaTarget> get _validTargets => widget.targets
      .where((t) => Validators.phone(t.phone) == null)
      .toList();

  Future<void> _openWhatsApp(WaTarget target) async {
    final phone = Validators.normalizePhone(target.phone);
    final message = _messageC.text.trim().replaceAll('{nama}', target.name);
    final uri = Uri.https('wa.me', '/$phone', {'text': message});
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      AppSnackbar.error(context, 'WhatsApp tidak dapat dibuka.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final invalid = widget.targets.length - _validTargets.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Tulis Pesan WhatsApp')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Penerima: ${_validTargets.length} orang',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _validTargets.isEmpty
                            ? 'Belum ada nomor yang bisa dikirimi pesan.'
                            : _validTargets.map((t) => t.name).take(6).join(', ') +
                                (_validTargets.length > 6
                                    ? ', dan ${_validTargets.length - 6} lainnya'
                                    : ''),
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textDark, height: 1.4),
                      ),
                      if (invalid > 0) ...[
                        const SizedBox(height: 6),
                        Text(
                          '$invalid penerima dilewati karena nomornya tidak valid.',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.danger),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleC,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Judul informasi (opsional)',
                    helperText: 'Mengisi placeholder {judul_informasi}',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageC,
                  maxLines: 7,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Isi pesan',
                    alignLabelWithHint: true,
                    helperText: 'Gunakan {nama} dan {judul_informasi} bila perlu',
                  ),
                  validator: (v) => Validators.required(v, field: 'Pesan'),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Kirim tanpa Fonnte',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Buka chat WhatsApp admin satu per satu tanpa membutuhkan Firebase Blaze.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textGrey),
                ),
                const SizedBox(height: 8),
                ..._validTargets.map(
                  (target) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: () => _openWhatsApp(target),
                      icon: const Icon(Icons.chat_rounded, size: 18),
                      label: Text('Chat ${target.name.isEmpty ? target.phone : target.name}'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
