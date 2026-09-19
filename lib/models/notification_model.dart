import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/formatters.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String
      type; // job | scholarship | training | announcement | application
  final String referenceId;
  final bool isRead;
  final Timestamp? createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    this.body = '',
    this.type = '',
    this.referenceId = '',
    this.isRead = false,
    this.createdAt,
  });

  factory NotificationModel.fromMap(String id, Map<String, dynamic> map) =>
      NotificationModel(
        id: map['id'] as String? ?? id,
        userId: map['userId'] as String? ?? '',
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        type: map['type'] as String? ?? '',
        referenceId: map['referenceId'] as String? ?? '',
        isRead: map['isRead'] as bool? ?? false,
        createdAt: Fmt.toTimestamp(map['createdAt']),
      );

  factory NotificationModel.fromDoc(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      NotificationModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'referenceId': referenceId,
        'isRead': isRead,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };
}
