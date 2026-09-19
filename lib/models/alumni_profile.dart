import 'package:cloud_firestore/cloud_firestore.dart';

class AlumniProfile {
  final String uid;
  final int? graduationYear;
  final String major;
  final String bio;
  final List<String> skills;

  const AlumniProfile({
    required this.uid,
    this.graduationYear,
    this.major = '',
    this.bio = '',
    this.skills = const [],
  });

  factory AlumniProfile.empty(String uid) => AlumniProfile(uid: uid);

  factory AlumniProfile.fromMap(String uid, Map<String, dynamic> map) {
    final year = map['graduationYear'];
    return AlumniProfile(
      uid: map['uid'] as String? ?? uid,
      graduationYear: year is int ? year : int.tryParse('${year ?? ''}'),
      major: map['major'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      skills: (map['skills'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  factory AlumniProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      AlumniProfile.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'graduationYear': graduationYear,
        'major': major,
        'bio': bio,
        'skills': skills,
      };

  bool get isComplete =>
      graduationYear != null && major.trim().isNotEmpty && skills.isNotEmpty;
}
