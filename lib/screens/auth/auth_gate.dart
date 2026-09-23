import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';
import '../../utils/constants.dart';
import '../../widgets/loading_view.dart';
import '../admin/admin_main_screen.dart';
import '../alumni/alumni_main_screen.dart';
import '../bkk/bkk_main_screen.dart';
import 'complete_profile_screen.dart';
import 'login_screen.dart';

/// Penjaga rute: menentukan layar berdasarkan status login, kelengkapan
/// data diri, dan role pengguna.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _authStream = AuthService.instance.authState;
  String? _streamUid;
  Stream<UserModel?>? _userStream;

  Stream<UserModel?> _streamForUser(String uid) {
    if (_streamUid != uid || _userStream == null) {
      _streamUid = uid;
      _userStream = AuthService.instance.userStream(uid);
    }
    return _userStream!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }

        final user = authSnap.data;
        if (user == null) return const LoginScreen();

        return StreamBuilder<UserModel?>(
          stream: _streamForUser(user.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: LoadingView(message: 'Memuat akun...'));
            }
            if (userSnap.hasError) {
              return Scaffold(
                body: ErrorView(
                  message:
                      'Gagal memuat data akun. Periksa koneksi internet Anda.',
                  onRetry: () => AuthService.instance.logout(),
                ),
              );
            }

            final profile = userSnap.data;
            if (profile == null) {
              return FutureBuilder<void>(
                future: AuthService.instance.ensureUserDocument(user),
                builder: (context, repairSnap) {
                  if (repairSnap.connectionState != ConnectionState.done) {
                    return const Scaffold(
                        body: LoadingView(message: 'Menyiapkan akun...'));
                  }
                  if (repairSnap.hasError) {
                    return const Scaffold(
                      body: ErrorView(
                        message:
                            'Akun berhasil login, tetapi data akun belum dapat dimuat.',
                      ),
                    );
                  }
                  return const Scaffold(
                      body: LoadingView(message: 'Memuat akun...'));
                },
              );
            }

            // Daftarkan token FCM setelah data user tersedia.
            FcmService.instance.initForUser(profile.uid);

            switch (profile.role) {
              case Roles.admin:
                return const AdminMainScreen();
              case Roles.bkk:
                return const BkkMainScreen();
              default:
                if (!profile.isProfileComplete) {
                  return CompleteProfileScreen(user: profile);
                }
                return const AlumniMainScreen();
            }
          },
        );
      },
    );
  }
}
