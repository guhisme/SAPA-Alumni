import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

class ApplicationModel {
  final String id;
  final String jobId;
  final String alumniId;
  final Timestamp? appliedAt;
  final String status; // menunggu | diproses | diterima | ditolak

  // Field bantu (denormalisasi) agar daftar lamaran tidak perlu query berulang.
  final String jobTitle;
  final String company;
  final String bkkId;
  final String note;
  final String decisionLetterUrl;

  const ApplicationModel({
    required this.id,
    required this.jobId,
    required this.alumniId,
    this.appliedAt,
    this.status = AppStatus.menunggu,
    this.jobTitle = '',
    this.company = '',
    this.bkkId = '',
    this.note = '',
    this.decisionLetterUrl = '',
  });

  factory ApplicationModel.fromMap(String id, Map<String, dynamic> map) =>
      ApplicationModel(
        id: map['id'] as String? ?? id,
        jobId: map['jobId'] as String? ?? '',
        alumniId: map['alumniId'] as String? ?? '',
        appliedAt: Fmt.toTimestamp(map['appliedAt']),
        status: map['status'] as String? ?? AppStatus.menunggu,
        jobTitle: map['jobTitle'] as String? ?? '',
        company: map['company'] as String? ?? '',
        bkkId: map['bkkId'] as String? ?? '',
        note: map['note'] as String? ?? '',
        decisionLetterUrl: map['decisionLetterUrl'] as String? ?? '',
      );

  factory ApplicationModel.fromDoc(
          DocumentSnapshot<Map<String, dynamic>> doc) =>
      ApplicationModel.fromMap(doc.id, doc.data() ?? {});

  Map<String, dynamic> toMap() => {
        'id': id,
        'jobId': jobId,
        'alumniId': alumniId,
        'appliedAt': appliedAt ?? FieldValue.serverTimestamp(),
        'status': status,
        'jobTitle': jobTitle,
        'company': company,
        'bkkId': bkkId,
        'note': note,
        if (decisionLetterUrl.isNotEmpty)
          'decisionLetterUrl': decisionLetterUrl,
      };
}
