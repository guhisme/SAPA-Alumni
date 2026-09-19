import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/job_model.dart';
import '../utils/constants.dart';

/// Pembacaan dan pengelolaan lowongan.
class JobService {
  JobService._();
  static final JobService instance = JobService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(Col.jobs);

  // ---------------- Pembacaan (Alumni) ----------------

  /// Semua lowongan berstatus open, terbaru di atas.
  Stream<List<JobModel>> watchOpenJobs({int limit = 20}) {
    return Stream.fromFuture(_getOpenJobs(limit))
        .map((s) => s.docs.map(JobModel.fromDoc).toList());
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _getOpenJobs(int limit) async {
    final query = _col
        .where('status', isEqualTo: AppStatus.jobOpen)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    try {
      return await query.get(const GetOptions(source: Source.server));
    } on FirebaseException {
      return query.get(const GetOptions(source: Source.cache));
    }
  }

  Stream<List<JobModel>> watchLatestJobs({int limit = 5}) =>
      watchOpenJobs(limit: limit);

  Stream<JobModel?> watchJob(String jobId) =>
      Stream.fromFuture(_col.doc(jobId).get())
          .map((d) => d.exists ? JobModel.fromDoc(d) : null);

  Future<JobModel?> getJob(String jobId) async {
    final doc = await _col.doc(jobId).get();
    return doc.exists ? JobModel.fromDoc(doc) : null;
  }

  Future<Map<String, JobModel>> getJobsByIds(Iterable<String> ids) async {
    final values = ids.toSet().toList();
    final result = <String, JobModel>{};
    if (values.isEmpty) return result;
    for (var i = 0; i < values.length; i += 30) {
      final chunk = values.skip(i).take(30).toList();
      final snapshot =
          await _col.where(FieldPath.documentId, whereIn: chunk).get();
      for (final doc in snapshot.docs) {
        result[doc.id] = JobModel.fromDoc(doc);
      }
    }
    return result;
  }

  // ---------------- Pengelolaan (BKK) ----------------

  /// Lowongan milik satu BKK saja.
  Stream<List<JobModel>> watchJobsByBkk(String bkkId) {
    return Stream.fromFuture(_col.where('bkkId', isEqualTo: bkkId).get())
        .map((s) {
      final list = s.docs.map(JobModel.fromDoc).toList();
      list.sort((a, b) {
        final da = a.createdAt ?? Timestamp(0, 0);
        final db_ = b.createdAt ?? Timestamp(0, 0);
        return db_.compareTo(da);
      });
      return list;
    });
  }

  /// Membuat lowongan baru. Mengembalikan id dokumen.
  Future<String> create(JobModel job) async {
    final ref = _col.doc();
    final data = job.toMap();
    data['id'] = ref.id;
    data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    return ref.id;
  }

  Future<void> update(JobModel job) async {
    final data = job.toMap();
    data.remove('createdAt');
    await _col.doc(job.id).set(data, SetOptions(merge: true));
  }

  Future<void> setStatus(String jobId, String status) =>
      _col.doc(jobId).set({'status': status}, SetOptions(merge: true));

  Future<void> delete(String jobId) => _col.doc(jobId).delete();

  // ---------------- Pencarian sisi klien ----------------

  static List<JobModel> filter(
    List<JobModel> jobs, {
    String query = '',
    String location = '',
  }) {
    final q = query.trim().toLowerCase();
    return jobs.where((job) {
      final matchQuery = q.isEmpty || job.searchText.contains(q);
      final matchLocation = location.isEmpty ||
          job.location.toLowerCase() == location.toLowerCase();
      return matchQuery && matchLocation;
    }).toList();
  }

  static List<String> locationsOf(List<JobModel> jobs) {
    final set = <String>{};
    for (final job in jobs) {
      if (job.location.trim().isNotEmpty) set.add(job.location.trim());
    }
    final list = set.toList()..sort();
    return list;
  }
}
