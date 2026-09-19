import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/formatters.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // admin | bkk | alumni
  final String phone;
  final String photoUrl;
  final Timestamp? createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.photoUrl = '',
    this.createdAt,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String? ?? uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'alumni',
      phone: map['phone'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      createdAt: Fmt.toTimestamp(map['createdAt']),
    );
  }

  factory UserModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      UserModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'photoUrl': photoUrl,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };

  /// Data diri minimal sudah terisi (nama + nomor telepon).
  bool get isProfileComplete =>
      name.trim().isNotEmpty && phone.trim().isNotEmpty;
}
