import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/bkk_profile.dart';
import '../../models/job_model.dart';
import '../../services/auth_service.dart';
import '../../services/bkk_service.dart';
import '../../services/job_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/app_snackbar.dart';

/// Formulir tambah dan edit lowongan.
class BkkJobFormScreen extends StatefulWidget {
  final JobModel? job;
  const BkkJobFormScreen({super.key, this.job});

  bool get isEdit => job != null;

  @override
  State<BkkJobFormScreen> createState() => _BkkJobFormScreenState();
}

class _BkkJobFormScreenState extends State<BkkJobFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleC = TextEditingController(text: widget.job?.title ?? '');
  late final _companyC = TextEditingController(text: widget.job?.company ?? '');
  late final _descC =
      TextEditingController(text: widget.job?.description ?? '');
  late final _reqC =
      TextEditingController(text: widget.job?.requirements ?? '');
  late final _locC = TextEditingController(text: widget.job?.location ?? '');

  late Timestamp? _deadline = widget.job?.deadline;
  late String _status = widget.job?.status ?? AppStatus.jobOpen;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Nama perusahaan default diisi nama BKK saat membuat lowongan baru.
    if (!widget.isEdit) {
      final uid = AuthService.instance.uid;
      if (uid != null) {
        BkkService.instance.getProfile(uid).then((BkkProfile p) {
          if (mounted && _companyC.text.isEmpty && p.name.isNotEmpty) {
            _companyC.text = p.name;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _titleC.dispose();
    _companyC.dispose();
    _descC.dispose();
    _reqC.dispose();
    _locC.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = Timestamp.now().toDate();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline?.toDate() ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: 'Pilih batas akhir lamaran',
    );
    if (picked != null) {
      setState(() => _deadline = Timestamp.fromDate(picked));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline == null) {
      AppSnackbar.error(context, 'Batas akhir lamaran wajib dipilih.');
      return;
    }
    final uid = AuthService.instance.uid;
    if (uid == null) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final job = JobModel(
        id: widget.job?.id ?? '',
        title: _titleC.text.trim(),
        company: _companyC.text.trim(),
        description: _descC.text.trim(),
        requirements: _reqC.text.trim(),
        location: _locC.text.trim(),
        deadline: _deadline,
        bkkId: uid,
        status: _status,
        createdAt: widget.job?.createdAt,
      );

      if (widget.isEdit) {
        await JobService.instance.update(job);
      } else {
        await JobService.instance.create(job);
      }

      if (!mounted) return;
      Navigator.pop(context);
      AppSnackbar.show(
        context,
        widget.isEdit ? 'Lowongan diperbarui.' : 'Lowongan berhasil dibuat.',
      );
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(
          context,
          'Gagal menyimpan lowongan. Pastikan akun BKK Anda sudah diverifikasi.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Lowongan' : 'Tambah Lowongan'),
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
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Posisi / judul lowongan',
                    hintText: 'Staff Administrasi',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  validator: (v) => Validators.required(v, field: 'Judul'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _companyC,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Perusahaan',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                  validator: (v) => Validators.required(v, field: 'Perusahaan'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _locC,
                  maxLength: 40,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi',
                    hintText: 'Bandung',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                  validator: (v) => Validators.required(v, field: 'Lokasi'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descC,
                  maxLength: 1000,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi pekerjaan',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => Validators.required(v, field: 'Deskripsi'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reqC,
                  maxLength: 1000,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Persyaratan',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) =>
                      Validators.required(v, field: 'Persyaratan'),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDeadline,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Batas akhir lamaran',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(
                      _deadline == null ? 'Pilih tanggal' : Fmt.date(_deadline),
                      style: TextStyle(
                        fontSize: 14,
                        color: _deadline == null
                            ? AppColors.textGrey
                            : AppColors.textDark,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status lowongan',
                    prefixIcon: Icon(Icons.toggle_on_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: AppStatus.jobOpen, child: Text('Dibuka')),
                    DropdownMenuItem(
                        value: AppStatus.jobClosed, child: Text('Ditutup')),
                  ],
                  onChanged: (v) =>
                      setState(() => _status = v ?? AppStatus.jobOpen),
                ),
                const SizedBox(height: 24),
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
                      : Text(widget.isEdit
                          ? 'Simpan perubahan'
                          : 'Simpan lowongan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
