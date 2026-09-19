import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/validators.dart';
import '../../widgets/app_snackbar.dart';

/// Pendaftaran akun alumni (email + password).
/// Data diri diisi pada layar berikutnya.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  final _confirmC = TextEditingController();

  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    _confirmC.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      await AuthService.instance.registerAlumni(
        email: _emailC.text,
        password: _passC.text,
      );
      if (!mounted) return;
      // AuthGate akan membuka layar isi data diri.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, AuthService.messageFromError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Daftar Alumni')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Buat akun baru',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Setelah mendaftar, Anda akan diminta melengkapi data diri.',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 13.5),
                ),
                const SizedBox(height: 26),
                TextFormField(
                  controller: _emailC,
                  keyboardType: TextInputType.emailAddress,
                  maxLength: 60,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'nama@email.com',
                    counterText: '',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passC,
                  obscureText: _obscure,
                  maxLength: 32,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    helperText: 'Minimal 6 karakter',
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: Validators.password,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirmC,
                  obscureText: _obscure,
                  maxLength: 32,
                  decoration: const InputDecoration(
                    labelText: 'Ulangi password',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: (v) => Validators.confirmPassword(v, _passC.text),
                ),
                const SizedBox(height: 26),
                ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Daftar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
