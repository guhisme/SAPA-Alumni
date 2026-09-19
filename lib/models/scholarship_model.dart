import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/formatters.dart';

class ScholarshipModel {
  final String id;
  final String title;
  final String provider;
  final String description;
  final String requirements;
  final String benefits;
  final Timestamp? deadline;
  final String link;
  final Timestamp? createdAt;

  const ScholarshipModel({
    required this.id,
    required this.title,
    this.provider = '',
    this.description = '',
    this.requirements = '',
    this.benefits = '',
    this.deadline,
    this.link = '',
    this.createdAt,
  });

  factory ScholarshipModel.fromMap(String id, Map<String, dynamic> map) =>
      ScholarshipModel(
        id: map['id'] as String? ?? id,
        title: map['title'] as String? ?? '',
        provider: map['provider'] as String? ?? '',
        description: map['description'] as String? ?? '',
        requirements: map['requirements'] as String? ?? '',
        benefits: map['benefits'] as String? ?? '',
        deadline: Fmt.toTimestamp(map['deadline']),
        link: map['link'] as String? ?? '',
        createdAt: Fmt.toTimestamp(map['createdAt']),
      );

  factory ScholarshipModel.fromDoc(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      ScholarshipModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'provider': provider,
        'description': description,
        'requirements': requirements,
        'benefits': benefits,
        'deadline': deadline,
        'link': link,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };

  bool get isExpired => Fmt.isExpired(deadline);
  String get searchText => '$title $provider'.toLowerCase();
}
