import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/training_model.dart';
import '../../services/admin_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/app_snackbar.dart';

class AdminTrainingFormScreen extends StatefulWidget {
  final TrainingModel? item;
  const AdminTrainingFormScreen({super.key, this.item});

  bool get isEdit => item != null;

  @override
  State<AdminTrainingFormScreen> createState() =>
      _AdminTrainingFormScreenState();
}

class _AdminTrainingFormScreenState extends State<AdminTrainingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _titleC = TextEditingController(text: widget.item?.title ?? '');
  late final _providerC =
      TextEditingController(text: widget.item?.provider ?? '');
  late final _descC =
      TextEditingController(text: widget.item?.description ?? '');
  late final _scheduleC =
      TextEditingController(text: widget.item?.schedule ?? '');
  late final _durationC =
      TextEditingController(text: widget.item?.duration ?? '');
  late final _linkC = TextEditingController(text: widget.item?.link ?? '');

  late String _mode =
      widget.item?.mode.isNotEmpty == true ? widget.item!.mode : 'online';
  late Timestamp? _deadline = widget.item?.deadline;
  bool _loading = false;

  @override
  void dispose() {
    _titleC.dispose();
    _providerC.dispose();
    _descC.dispose();
    _scheduleC.dispose();
    _durationC.dispose();
    _linkC.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final now = Timestamp.now().toDate();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline?.toDate() ?? now.add(const Duration(days: 21)),
      firstDate: Timestamp.fromDate(now).toDate(),
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _deadline = Timestamp.fromDate(picked));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await AdminService.instance.saveTraining(
        TrainingModel(
          id: widget.item?.id ?? '',
          title: _titleC.text.trim(),
          provider: _providerC.text.trim(),
          description: _descC.text.trim(),
          schedule: _scheduleC.text.trim(),
          duration: _durationC.text.trim(),
          mode: _mode,
          deadline: _deadline,
          link: _linkC.text.trim(),
          createdAt: widget.item?.createdAt,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
      AppSnackbar.show(context,
          widget.isEdit ? 'Pelatihan diperbarui.' : 'Pelatihan ditambahkan.');
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'Gagal menyimpan pelatihan.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Pelatihan' : 'Tambah Pelatihan'),
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
                    labelText: 'Nama pelatihan',
                    prefixIcon: Icon(Icons.model_training_outlined),
                  ),
                  validator: (v) => Validators.required(v, field: 'Nama'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _providerC,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Penyelenggara',
                    prefixIcon: Icon(Icons.apartment_outlined),
                  ),
                  validator: (v) =>
                      Validators.required(v, field: 'Penyelenggara'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descC,
                  maxLength: 1000,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => Validators.required(v, field: 'Deskripsi'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _scheduleC,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Jadwal',
                    hintText: 'Setiap Sabtu, 09.00 - 12.00',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _durationC,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Durasi',
                    hintText: '4 pertemuan',
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _mode,
                  decoration: const InputDecoration(
                    labelText: 'Metode',
                    prefixIcon: Icon(Icons.laptop_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'online', child: Text('Online')),
                    DropdownMenuItem(value: 'offline', child: Text('Offline')),
                    DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                  ],
                  onChanged: (v) => setState(() => _mode = v ?? 'online'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _linkC,
                  maxLength: 200,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Tautan pendaftaran (opsional)',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDeadline,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Batas pendaftaran',
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
                const SizedBox(height: 22),
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
