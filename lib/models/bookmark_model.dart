import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/formatters.dart';

class BookmarkModel {
  final String id;
  final String userId;
  final String contentId;
  final String contentType; // job | scholarship | training | announcement
  final Timestamp? createdAt;

  const BookmarkModel({
    required this.id,
    required this.userId,
    required this.contentId,
    required this.contentType,
    this.createdAt,
  });

  factory BookmarkModel.fromMap(String id, Map<String, dynamic> map) =>
      BookmarkModel(
        id: map['id'] as String? ?? id,
        userId: map['userId'] as String? ?? '',
        contentId: map['contentId'] as String? ?? '',
        contentType: map['contentType'] as String? ?? '',
        createdAt: Fmt.toTimestamp(map['createdAt']),
      );

  factory BookmarkModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      BookmarkModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'contentId': contentId,
        'contentType': contentType,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };
}
