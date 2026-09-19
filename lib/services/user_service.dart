import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/alumni_profile.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// CRUD dokumen users dan alumni_profiles.
class UserService {
  UserService._();
  static final UserService instance = UserService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection(Col.users).doc(uid);

  DocumentReference<Map<String, dynamic>> _profileDoc(String uid) =>
      _db.collection(Col.alumniProfiles).doc(uid);

  Stream<UserModel?> watchUser(String uid) => _userDoc(uid)
      .snapshots()
      .map((d) => d.exists ? UserModel.fromDoc(d) : null);

  Stream<AlumniProfile> watchAlumniProfile(String uid) =>
      _profileDoc(uid).snapshots().map(
            (d) =>
                d.exists ? AlumniProfile.fromDoc(d) : AlumniProfile.empty(uid),
          );

  Future<AlumniProfile> getAlumniProfile(String uid) async {
    final doc = await _profileDoc(uid).get();
    return doc.exists ? AlumniProfile.fromDoc(doc) : AlumniProfile.empty(uid);
  }

  Future<Map<String, UserModel>> getUsersByIds(Iterable<String> ids) async {
    final uniqueIds = ids.toSet().toList();
    final result = <String, UserModel>{};
    for (var i = 0; i < uniqueIds.length; i += 30) {
      final chunk = uniqueIds.skip(i).take(30).toList();
      final snapshot = await _db
          .collection(Col.users)
          .where('role', isEqualTo: Roles.alumni)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        result[doc.id] = UserModel.fromDoc(doc);
      }
    }
    return result;
  }

  /// Dipakai pada halaman "Isi Data Diri" (tanpa email).
  Future<void> saveBasicData({
    required String uid,
    required String name,
    required String phone,
  }) async {
    await _userDoc(uid).set({
      'uid': uid,
      'name': name.trim(),
      'phone': phone.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUser({
    required String uid,
    String? name,
    String? phone,
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name.trim();
    if (phone != null) data['phone'] = phone.trim();
    if (photoUrl != null) data['photoUrl'] = photoUrl;
    if (data.isEmpty) return;
    await _userDoc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> saveAlumniProfile(AlumniProfile profile) async {
    await _profileDoc(profile.uid)
        .set(profile.toMap(), SetOptions(merge: true));
  }

  /// Menyimpan token FCM perangkat pada dokumen user.
  Future<void> saveFcmToken(String uid, String token) async {
    await _userDoc(uid).set({
      'fcmToken': token,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeFcmToken(String uid) async {
    await _userDoc(uid)
        .set({'fcmToken': FieldValue.delete()}, SetOptions(merge: true));
  }
}
