import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/formatters.dart';

class TrainingModel {
  final String id;
  final String title;
  final String provider;
  final String description;
  final String schedule;
  final String duration;
  final String mode; // online | offline | hybrid
  final Timestamp? deadline;
  final String link;
  final Timestamp? createdAt;

  const TrainingModel({
    required this.id,
    required this.title,
    this.provider = '',
    this.description = '',
    this.schedule = '',
    this.duration = '',
    this.mode = '',
    this.deadline,
    this.link = '',
    this.createdAt,
  });

  factory TrainingModel.fromMap(String id, Map<String, dynamic> map) =>
      TrainingModel(
        id: map['id'] as String? ?? id,
        title: map['title'] as String? ?? '',
        provider: map['provider'] as String? ?? '',
        description: map['description'] as String? ?? '',
        schedule: map['schedule'] as String? ?? '',
        duration: map['duration'] as String? ?? '',
        mode: map['mode'] as String? ?? '',
        deadline: Fmt.toTimestamp(map['deadline']),
        link: map['link'] as String? ?? '',
        createdAt: Fmt.toTimestamp(map['createdAt']),
      );

  factory TrainingModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      TrainingModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'provider': provider,
        'description': description,
        'schedule': schedule,
        'duration': duration,
        'mode': mode,
        'deadline': deadline,
        'link': link,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };

  bool get isExpired => Fmt.isExpired(deadline);
  String get searchText => '$title $provider $mode'.toLowerCase();
}
