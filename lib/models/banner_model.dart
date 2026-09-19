import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/formatters.dart';

class BannerModel {
  final String id;
  final String title;
  final String content;
  final String imageUrl;
  final String buttonText;
  final Timestamp? createdAt;
  final bool isActive;

  const BannerModel({
    required this.id,
    required this.title,
    this.content = '',
    this.imageUrl = '',
    this.buttonText = 'Lihat informasi',
    this.createdAt,
    this.isActive = true,
  });

  factory BannerModel.fromMap(String id, Map<String, dynamic> map) =>
      BannerModel(
        id: map['id'] as String? ?? id,
        title: map['title'] as String? ?? '',
        content: map['content'] as String? ?? '',
        imageUrl: map['imageUrl'] as String? ?? '',
        buttonText: map['buttonText'] as String? ?? 'Lihat informasi',
        createdAt: Fmt.toTimestamp(map['createdAt']),
        isActive: map['isActive'] as bool? ?? true,
      );

  factory BannerModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) =>
      BannerModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'buttonText': buttonText,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
        'isActive': isActive,
      };
}
