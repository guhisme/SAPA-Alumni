import 'package:flutter/material.dart';

import '../../models/announcement_model.dart';
import '../../services/admin_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/app_snackbar.dart';

class AdminAnnouncementFormScreen extends StatefulWidget {
  final AnnouncementModel? item;
  const AdminAnnouncementFormScreen({super.key, this.item});

  bool get isEdit => item != null;

  @override
  State<AdminAnnouncementFormScreen> createState() =>
      _AdminAnnouncementFormScreenState();
}

class _AdminAnnouncementFormScreenState
    extends State<AdminAnnouncementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleC = TextEditingController(text: widget.item?.title ?? '');
  late final _contentC =
      TextEditingController(text: widget.item?.content ?? '');
  bool _loading = false;

  @override
  void dispose() {
    _titleC.dispose();
    _contentC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await AdminService.instance.saveAnnouncement(
        AnnouncementModel(
          id: widget.item?.id ?? '',
          title: _titleC.text.trim(),
          content: _contentC.text.trim(),
          createdAt: widget.item?.createdAt,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      AppSnackbar.show(
        context,
        widget.isEdit ? 'Pengumuman diperbarui.' : 'Pengumuman dibuat.',
      );
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'Gagal menyimpan pengumuman.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Pengumuman' : 'Tambah Pengumuman'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _titleC,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Judul pengumuman',
                    hintText: 'Pengambilan ijazah angkatan 2024',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (v) => Validators.required(v, field: 'Judul'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contentC,
                  maxLength: 1500,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'Isi pengumuman',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => Validators.required(v, field: 'Isi'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
