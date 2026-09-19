import 'package:flutter/material.dart';

import '../../models/alumni_profile.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/app_snackbar.dart';
import 'login_screen.dart';

/// Isi data diri setelah registrasi. Tidak ada field email di sini.
class CompleteProfileScreen extends StatefulWidget {
  final UserModel user;
  const CompleteProfileScreen({super.key, required this.user});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameC =
      TextEditingController(text: widget.user.name);
  late final TextEditingController _phoneC =
      TextEditingController(text: widget.user.phone);
  final _yearC = TextEditingController();
  final _majorC = TextEditingController();
  final _skillC = TextEditingController();

  final List<String> _skills = [];
  bool _loading = false;

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _yearC.dispose();
    _majorC.dispose();
    _skillC.dispose();
    super.dispose();
  }

  void _addSkill() {
    final value = _skillC.text.trim();
    if (value.isEmpty) return;
    if (_skills.length >= 15) {
      AppSnackbar.error(context, 'Maksimal 15 keahlian.');
      return;
    }
    if (_skills.any((s) => s.toLowerCase() == value.toLowerCase())) {
      _skillC.clear();
      return;
    }
    setState(() {
      _skills.add(value);
      _skillC.clear();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final uid = widget.user.uid;
      await UserService.instance.saveBasicData(
        uid: uid,
        name: _nameC.text,
        phone: _phoneC.text,
      );
      await UserService.instance.saveAlumniProfile(
        AlumniProfile(
          uid: uid,
          graduationYear: int.tryParse(_yearC.text.trim()),
          major: _majorC.text.trim(),
          skills: _skills,
        ),
      );
      // AuthGate mendeteksi data lengkap dan membuka halaman utama.
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Gagal menyimpan data. Coba lagi.');
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
        title: const Text('Lengkapi Data Diri'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
              await AuthService.instance.logout();
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Data ini dipakai BKK saat memproses lamaran Anda.',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13.5),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _nameC,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Nama lengkap',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => Validators.required(v, field: 'Nama'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneC,
                  keyboardType: TextInputType.phone,
                  maxLength: 15,
                  decoration: const InputDecoration(
                    labelText: 'Nomor WhatsApp',
                    hintText: '08xxxxxxxxxx',
                    prefixIcon: Icon(Icons.chat_outlined),
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _yearC,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Tahun lulus',
                    hintText: '2023',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  validator: Validators.graduationYear,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _majorC,
                  textCapitalization: TextCapitalization.words,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Jurusan',
                    hintText: 'Rekayasa Perangkat Lunak',
                    prefixIcon: Icon(Icons.menu_book_outlined),
                  ),
                  validator: (v) => Validators.required(v, field: 'Jurusan'),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Keahlian',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skillC,
                        maxLength: 25,
                        onFieldSubmitted: (_) => _addSkill(),
                        decoration: const InputDecoration(
                          hintText: 'Contoh: Microsoft Excel',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _addSkill,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(56, 50),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.add),
                      ),
                    ),
                  ],
                ),
                if (_skills.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _skills
                        .map((s) => Chip(
                              label: Text(s),
                              onDeleted: () =>
                                  setState(() => _skills.remove(s)),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 28),
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
                      : const Text('Simpan dan lanjutkan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
