import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class JobModel {
  final String id;
  final String title;
  final String company;
  final String description;
  final String requirements;
  final String location;
  final Timestamp? deadline;
  final String bkkId;
  final String status; // open | closed
  final Timestamp? createdAt;

  const JobModel({
    required this.id,
    required this.title,
    required this.company,
    this.description = '',
    this.requirements = '',
    this.location = '',
    this.deadline,
    this.bkkId = '',
    this.status = AppStatus.jobOpen,
    this.createdAt,
  });

  factory JobModel.fromMap(String id, Map<String, dynamic> map) => JobModel(
        id: map['id'] as String? ?? id,
        title: map['title'] as String? ?? '',
        company: map['company'] as String? ?? '',
        description: map['description'] as String? ?? '',
        requirements: map['requirements'] as String? ?? '',
        location: map['location'] as String? ?? '',
        deadline: Fmt.toTimestamp(map['deadline']),
        bkkId: map['bkkId'] as String? ?? '',
        status: map['status'] as String? ?? AppStatus.jobOpen,
        createdAt: Fmt.toTimestamp(map['createdAt']),
      );

  factory JobModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      JobModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'company': company,
        'description': description,
        'requirements': requirements,
        'location': location,
        'deadline': deadline,
        'bkkId': bkkId,
        'status': status,
        'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      };

  bool get isExpired => Fmt.isExpired(deadline);
  bool get isClosed => status != AppStatus.jobOpen;

  /// Lowongan masih bisa dilamar.
  bool get isApplicable => !isClosed && !isExpired;

  String get searchText => '$title $company $location'.toLowerCase();
}
