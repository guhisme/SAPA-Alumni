import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/alumni_profile.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Menangani login, register, logout, dan pembacaan dokumen user.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _googleServerClientId =
      '725664611084-0ulajjnit5ttqir6cctj3f7lkpoacdsv.apps.googleusercontent.com';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: _googleServerClientId,
  );

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;
  Stream<User?> get authState => _auth.authStateChanges();

  /// Stream dokumen user yang sedang login (dipakai untuk routing role).
  Stream<UserModel?> userStream(String uid) {
    return _db.collection(Col.users).doc(uid).snapshots().map(
          (doc) => doc.exists ? UserModel.fromDoc(doc) : null,
        );
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection(Col.users).doc(uid).get();
    return doc.exists ? UserModel.fromDoc(doc) : null;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential?> loginWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'google-signin-failed',
        message: 'Google Sign-In gagal menghasilkan token autentikasi.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user != null) await ensureUserDocument(user);
    return result;
  }

  Future<void> ensureUserDocument(User user) async {
    final ref = _db.collection(Col.users).doc(user.uid);
    final snapshot = await ref.get();
    if (snapshot.exists) return;

    await ref.set({
      'uid': user.uid,
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'role': Roles.alumni,
      'phone': '',
      'photoUrl': user.photoURL ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Register alumni. Dokumen users + alumni_profiles langsung dibuat.
  Future<UserCredential> registerAlumni({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final newUid = cred.user!.uid;

    await _db.collection(Col.users).doc(newUid).set({
      'uid': newUid,
      'name': '',
      'email': email.trim(),
      'role': Roles.alumni,
      'phone': '',
      'photoUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db
        .collection(Col.alumniProfiles)
        .doc(newUid)
        .set(AlumniProfile.empty(newUid).toMap());

    return cred;
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Navigasi ke login tetap ditangani oleh pemanggil.
    }
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Sesi Firebase sudah diproses; Google Sign-In tidak menghalangi logout.
    }
  }

  /// Mengubah kode error FirebaseAuth menjadi pesan berbahasa Indonesia.
  static String messageFromError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Format email tidak valid.';
        case 'user-disabled':
          return 'Akun ini dinonaktifkan. Hubungi admin.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email atau password salah.';
        case 'email-already-in-use':
          return 'Email sudah terdaftar. Silakan login.';
        case 'weak-password':
          return 'Password terlalu lemah, minimal 6 karakter.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Coba lagi beberapa saat lagi.';
        case 'network-request-failed':
          return 'Tidak ada koneksi internet.';
        case 'operation-not-allowed':
          return 'Login Google belum diaktifkan di Firebase Authentication.';
        case 'google-signin-failed':
          return error.message ?? 'Google Sign-In gagal menghasilkan token.';
      }
    }
    if (error is PlatformException) {
      switch (error.code) {
        case 'sign_in_canceled':
          return 'Login Google dibatalkan.';
        case 'network_error':
          return 'Tidak ada koneksi internet.';
        case 'sign_in_failed':
          return 'Google Sign-In ditolak. Periksa SHA-1/SHA-256 dan OAuth client di Firebase.';
      }
      return 'Google Sign-In gagal (${error.code}).';
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
