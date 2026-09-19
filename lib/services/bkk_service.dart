import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bkk_profile.dart';
import '../utils/constants.dart';

/// Profil BKK: dibaca BKK sendiri dan admin.
class BkkService {
  BkkService._();
  static final BkkService instance = BkkService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _db.collection(Col.bkkProfiles).doc(uid);

  Stream<BkkProfile> watchProfile(String uid) =>
      Stream.fromFuture(_doc(uid).get()).map(
        (d) => d.exists ? BkkProfile.fromDoc(d) : BkkProfile.empty(uid),
      );

  Future<BkkProfile> getProfile(String uid) async {
    final doc = await _doc(uid).get();
    return doc.exists ? BkkProfile.fromDoc(doc) : BkkProfile.empty(uid);
  }

  /// Menyimpan profil tanpa menyentuh field `verified`
  /// (verifikasi hanya boleh diubah admin).
  Future<void> saveProfile({
    required String uid,
    required String name,
    required String description,
    required String address,
    required String phone,
  }) async {
    final existing = await _doc(uid).get();
    final data = <String, dynamic>{
      'uid': uid,
      'name': name.trim(),
      'description': description.trim(),
      'address': address.trim(),
      'phone': phone.trim(),
    };
    if (!existing.exists) data['verified'] = false;
    await _doc(uid).set({
      ...data,
    }, SetOptions(merge: true));
  }

  Stream<List<BkkProfile>> watchAll() =>
      Stream.fromFuture(_db.collection(Col.bkkProfiles).get())
          .map((s) => s.docs.map(BkkProfile.fromDoc).toList());

  Stream<List<BkkProfile>> watchPending() => Stream.fromFuture(_db
          .collection(Col.bkkProfiles)
          .where('verified', isEqualTo: false)
          .get())
      .map((s) => s.docs.map(BkkProfile.fromDoc).toList());

  Future<void> setVerified(String uid, bool verified) =>
      _doc(uid).set({'verified': verified}, SetOptions(merge: true));
}
