import 'package:flutter/material.dart';

import '../../models/bkk_profile.dart';
import '../../services/auth_service.dart';
import '../../services/bkk_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/app_snackbar.dart';

class BkkEditProfileScreen extends StatefulWidget {
  final BkkProfile profile;
  const BkkEditProfileScreen({super.key, required this.profile});

  @override
  State<BkkEditProfileScreen> createState() => _BkkEditProfileScreenState();
}

class _BkkEditProfileScreenState extends State<BkkEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameC = TextEditingController(text: widget.profile.name);
  late final _phoneC = TextEditingController(text: widget.profile.phone);
  late final _addressC = TextEditingController(text: widget.profile.address);
  late final _descC = TextEditingController(text: widget.profile.description);

  bool _loading = false;

  @override
  void dispose() {
    _nameC.dispose();
    _phoneC.dispose();
    _addressC.dispose();
    _descC.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = AuthService.instance.uid;
    if (uid == null) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await BkkService.instance.saveProfile(
        uid: uid,
        name: _nameC.text,
        description: _descC.text,
        address: _addressC.text,
        phone: _phoneC.text,
      );
      // Nama dan telepon disamakan pada dokumen users agar mudah dicari admin.
      await UserService.instance.updateUser(
        uid: uid,
        name: _nameC.text,
        phone: _phoneC.text,
      );
      if (!mounted) return;
      Navigator.pop(context);
      AppSnackbar.show(context, 'Profil BKK diperbarui.');
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'Gagal menyimpan profil.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Edit Profil BKK')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameC,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama BKK / perusahaan',
                    prefixIcon: Icon(Icons.store_outlined),
                  ),
                  validator: (v) => Validators.required(v, field: 'Nama'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneC,
                  keyboardType: TextInputType.phone,
                  maxLength: 15,
                  decoration: const InputDecoration(
                    labelText: 'Nomor telepon / WhatsApp',
                    hintText: '08xxxxxxxxxx',
                    prefixIcon: Icon(Icons.chat_outlined),
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressC,
                  maxLength: 120,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Alamat',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => Validators.required(v, field: 'Alamat'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descC,
                  maxLength: 300,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    alignLabelWithHint: true,
                  ),
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
                      : const Text('Simpan perubahan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
