import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/announcement_model.dart';
import '../models/job_model.dart';
import '../models/scholarship_model.dart';
import '../models/training_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

/// Pengelolaan data oleh admin: pengguna dan seluruh informasi.
class AdminService {
  AdminService._();
  static final AdminService instance = AdminService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------- Pengguna ----------------

  Stream<List<UserModel>> watchUsers({String? role}) {
    Query<Map<String, dynamic>> query = _db.collection(Col.users);
    if (role != null) query = query.where('role', isEqualTo: role);
    return Stream.fromFuture(query.get()).map((s) {
      final list = s.docs.map(UserModel.fromDoc).toList();
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Future<void> setRole(String uid, String role) => _db
      .collection(Col.users)
      .doc(uid)
      .set({'role': role}, SetOptions(merge: true));

  /// Jumlah dokumen pada sebuah collection (untuk kartu ringkasan).
  Stream<int> watchCount(String collection) => Stream.fromFuture(
        _db.collection(collection).count().get(),
      ).map((s) => s.count ?? 0);

  Stream<int> watchUserCountByRole(String role) => Stream.fromFuture(
        _db.collection(Col.users).where('role', isEqualTo: role).count().get(),
      ).map((s) => s.count ?? 0);

  // ---------------- Beasiswa ----------------

  Future<void> saveScholarship(ScholarshipModel item) async {
    final ref = item.id.isEmpty
        ? _db.collection(Col.scholarships).doc()
        : _db.collection(Col.scholarships).doc(item.id);
    final data = item.toMap();
    data['id'] = ref.id;
    if (item.id.isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await ref.set(data);
    } else {
      data.remove('createdAt');
      await ref.set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteScholarship(String id) =>
      _db.collection(Col.scholarships).doc(id).delete();

  // ---------------- Pelatihan ----------------

  Future<void> saveTraining(TrainingModel item) async {
    final ref = item.id.isEmpty
        ? _db.collection(Col.trainings).doc()
        : _db.collection(Col.trainings).doc(item.id);
    final data = item.toMap();
    data['id'] = ref.id;
    if (item.id.isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await ref.set(data);
    } else {
      data.remove('createdAt');
      await ref.set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteTraining(String id) =>
      _db.collection(Col.trainings).doc(id).delete();

  // ---------------- Pengumuman ----------------

  Future<void> saveAnnouncement(AnnouncementModel item) async {
    final ref = item.id.isEmpty
        ? _db.collection(Col.announcements).doc()
        : _db.collection(Col.announcements).doc(item.id);
    final data = item.toMap();
    data['id'] = ref.id;
    if (item.id.isEmpty) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await ref.set(data);
    } else {
      data.remove('createdAt');
      await ref.set(data, SetOptions(merge: true));
    }
  }

  Future<void> deleteAnnouncement(String id) =>
      _db.collection(Col.announcements).doc(id).delete();

  /// Mengisi contoh data untuk pengujian. ID tetap membuat operasi ini aman
  /// dijalankan berulang kali tanpa membuat dokumen duplikat.
  Future<void> seedDemoContent() async {
    final now = Timestamp.now();
    final batch = _db.batch();

    final announcement = AnnouncementModel(
      id: 'demo-announcement-1',
      title: 'SAPA Alumni resmi digunakan',
      content:
          'Temukan lowongan kerja, beasiswa, dan pelatihan terbaru untuk alumni.',
      createdAt: now,
    );
    batch.set(
      _db.collection(Col.announcements).doc(announcement.id),
      announcement.toMap(),
    );

    final scholarship = ScholarshipModel(
      id: 'demo-scholarship-1',
      title: 'Beasiswa Prestasi Alumni 2026',
      provider: 'Yayasan Pendidikan Nusantara',
      description: 'Bantuan pendidikan untuk alumni berprestasi.',
      requirements: 'IPK minimal 3.25 dan aktif mengikuti kegiatan alumni.',
      benefits: 'Bantuan biaya pendidikan dan mentoring karier.',
      deadline: Timestamp.fromDate(now.toDate().add(const Duration(days: 45))),
      link: 'https://example.com/beasiswa-alumni',
      createdAt: now,
    );
    batch.set(
      _db.collection(Col.scholarships).doc(scholarship.id),
      scholarship.toMap(),
    );

    final training = TrainingModel(
      id: 'demo-training-1',
      title: 'Pelatihan Persiapan Karier',
      provider: 'Career Center Alumni',
      description:
          'Pelatihan singkat untuk mempersiapkan alumni memasuki dunia kerja.',
      schedule: 'Setiap Sabtu, 09.00 - 12.00',
      duration: '4 pertemuan',
      mode: 'hybrid',
      deadline: Timestamp.fromDate(now.toDate().add(const Duration(days: 30))),
      link: 'https://example.com/pelatihan-karier',
      createdAt: now,
    );
    batch.set(
      _db.collection(Col.trainings).doc(training.id),
      training.toMap(),
    );

    final job = JobModel(
      id: 'demo-job-1',
      title: 'Junior Staff Administrasi',
      company: 'PT Nusantara Berkarya',
      description: 'Mendukung administrasi dan pengelolaan dokumen kantor.',
      requirements:
          'Teliti, mampu menggunakan Microsoft Office, dan komunikatif.',
      location: 'Bandung',
      deadline: Timestamp.fromDate(now.toDate().add(const Duration(days: 21))),
      bkkId: 'demo-bkk',
      status: AppStatus.jobOpen,
      createdAt: now,
    );
    batch.set(_db.collection(Col.jobs).doc(job.id), job.toMap());

    await batch.commit();
  }
}
