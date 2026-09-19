import 'package:cloud_firestore/cloud_firestore.dart';

class BkkProfile {
  final String uid;
  final String name;
  final String description;
  final String address;
  final String phone;
  final bool verified;

  const BkkProfile({
    required this.uid,
    this.name = '',
    this.description = '',
    this.address = '',
    this.phone = '',
    this.verified = false,
  });

  factory BkkProfile.empty(String uid) => BkkProfile(uid: uid);

  factory BkkProfile.fromMap(String uid, Map<String, dynamic> map) => BkkProfile(
        uid: map['uid'] as String? ?? uid,
        name: map['name'] as String? ?? '',
        description: map['description'] as String? ?? '',
        address: map['address'] as String? ?? '',
        phone: map['phone'] as String? ?? '',
        verified: map['verified'] as bool? ?? false,
      );

  factory BkkProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      BkkProfile.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'description': description,
        'address': address,
        'phone': phone,
        'verified': verified,
      };

  bool get isComplete => name.trim().isNotEmpty && phone.trim().isNotEmpty;
}
