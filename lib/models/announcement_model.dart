import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/formatters.dart';

class AnnouncementModel {
  final String id;
  final String title;
  final String content;
  final Timestamp? createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    this.content = '',
    this.createdAt,
  });

  factory AnnouncementModel.fromMap(String id, Map<String, dynamic> map) =>
      AnnouncementModel(
        id: map['id'] as String? ?? id,
        title: map['title'] as String? ?? '',
        content: map['content'] as String? ?? '',
        createdAt: Fmt.toTimestamp(map['createdAt']),
      );

  factory AnnouncementModel.fromDoc(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      AnnouncementModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };
}
