import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/application_model.dart';
import '../models/job_model.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'notification_service.dart';
import 'decision_letter_service.dart';

/// Kesalahan yang bisa ditampilkan langsung ke pengguna.
class ApplyException implements Exception {
  final String message;
  ApplyException(this.message);
  @override
  String toString() => message;
}

class ApplicationService {
  ApplicationService._();
  static final ApplicationService instance = ApplicationService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(Col.applications);

  Stream<List<ApplicationModel>> watchMyApplications(String alumniId) {
    return Stream.fromFuture(_col.where('alumniId', isEqualTo: alumniId).get())
        .map((s) {
      final list = s.docs.map(ApplicationModel.fromDoc).toList();
      list.sort((a, b) {
        final da = a.appliedAt ?? Timestamp(0, 0);
        final db_ = b.appliedAt ?? Timestamp(0, 0);
        return db_.compareTo(da);
      });
      return list;
    });
  }

  Stream<ApplicationModel?> watchApplication(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? ApplicationModel.fromDoc(d) : null);

  /// Lamaran alumni pada satu lowongan (null bila belum melamar).
  Stream<ApplicationModel?> watchApplicationForJob({
    required String alumniId,
    required String jobId,
  }) {
    return Stream.fromFuture(_col
            .where('alumniId', isEqualTo: alumniId)
            .where('jobId', isEqualTo: jobId)
            .limit(1)
            .get())
        .map((s) =>
            s.docs.isEmpty ? null : ApplicationModel.fromDoc(s.docs.first));
  }

  Future<bool> hasApplied({
    required String alumniId,
    required String jobId,
  }) async {
    final snap = await _col
        .where('alumniId', isEqualTo: alumniId)
        .where('jobId', isEqualTo: jobId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// True bila alumni sudah diterima di salah satu perusahaan.
  Future<bool> hasAccepted(String alumniId) async {
    final snap = await _col.where('alumniId', isEqualTo: alumniId).get();
    return snap.docs
        .any((doc) => (doc.data()['status'] as String?) == AppStatus.diterima);
  }

  Stream<bool> watchHasAccepted(String alumniId) => Stream.fromFuture(
        _col
            .where('alumniId', isEqualTo: alumniId)
            .where('status', isEqualTo: AppStatus.diterima)
            .limit(1)
            .get(),
      ).map((s) => s.docs.isNotEmpty);

  /// Mengirim lamaran dengan seluruh validasi aturan bisnis.
  Future<ApplicationModel> apply({
    required JobModel job,
    required String alumniId,
  }) async {
    final userSnapshot = await _db.collection(Col.users).doc(alumniId).get();
    final role = userSnapshot.data()?['role'] as String?;
    if (role != Roles.alumni) {
      throw ApplyException(
        'Role akun Anda bukan alumni ($role). Perbarui field role menjadi alumni di users/$alumniId.',
      );
    }

    final jobSnapshot = await _db.collection(Col.jobs).doc(job.id).get();
    final jobData = jobSnapshot.data();
    if (!jobSnapshot.exists || jobData == null) {
      throw ApplyException(
          'Lowongan tidak ditemukan di server. Muat ulang halaman.');
    }
    if (jobData['status'] != AppStatus.jobOpen) {
      throw ApplyException('Lowongan ini sudah ditutup.');
    }
    if (jobData['bkkId'] != job.bkkId ||
        (jobData['bkkId'] as String? ?? '').trim().isEmpty) {
      throw ApplyException(
        'Data pemilik lowongan tidak cocok. Minta BKK membuka ulang atau memperbarui lowongan ini.',
      );
    }

    if (job.bkkId.trim().isEmpty) {
      throw ApplyException(
        'Lowongan ini belum memiliki data BKK yang valid. Minta BKK memperbarui lowongan.',
      );
    }
    if (job.isClosed) {
      throw ApplyException('Lowongan ini sudah ditutup.');
    }
    if (job.isExpired) {
      throw ApplyException('Batas waktu lamaran sudah lewat.');
    }
    if (await hasAccepted(alumniId)) {
      throw ApplyException(
        'Anda sudah diterima di sebuah perusahaan, sehingga tidak dapat melamar lagi.',
      );
    }
    final ref = _col.doc('${alumniId}_${job.id}');

    final application = ApplicationModel(
      id: ref.id,
      jobId: job.id,
      alumniId: alumniId,
      status: AppStatus.menunggu,
      jobTitle: job.title,
      company: job.company,
      bkkId: job.bkkId,
    );
    // Write langsung menghindari transaction.get pada dokumen baru. Rules
    // aplikasi memang tidak mengizinkan alumni membaca lamaran milik orang lain.
    await ref.set(application.toMap());

    try {
      await NotificationService.instance.create(
        userId: alumniId,
        title: 'Lamaran terkirim',
        body: 'Lamaran untuk ${job.title} di ${job.company} berhasil dikirim.',
        type: 'application',
        referenceId: ref.id,
      );
    } on FirebaseException {
      // Lamaran sudah tersimpan; notifikasi boleh gagal tanpa membatalkan proses.
    }

    return application;
  }

  /// Membatalkan lamaran yang masih berstatus menunggu.
  Future<void> cancel(ApplicationModel application) async {
    if (application.status != AppStatus.menunggu) {
      throw ApplyException(
        'Lamaran yang sudah diproses tidak dapat dibatalkan.',
      );
    }
    await _col.doc(application.id).delete();
  }

  // ---------------- Sisi BKK ----------------

  /// Seluruh pelamar pada satu lowongan.
  Stream<List<ApplicationModel>> watchApplicantsOfJob(
    String jobId,
    String bkkId,
  ) {
    return _col
        .where('jobId', isEqualTo: jobId)
        .where('bkkId', isEqualTo: bkkId)
        .get()
        .asStream()
        .map((s) {
      final list = s.docs.map(ApplicationModel.fromDoc).toList();
      list.sort((a, b) {
        final da = a.appliedAt ?? Timestamp(0, 0);
        final db_ = b.appliedAt ?? Timestamp(0, 0);
        return db_.compareTo(da);
      });
      return list;
    });
  }

  /// Seluruh lamaran yang masuk ke lowongan milik satu BKK.
  Stream<List<ApplicationModel>> watchApplicantsOfBkk(String bkkId) {
    return Stream.fromFuture(_col.where('bkkId', isEqualTo: bkkId).get())
        .map((s) {
      final list = s.docs.map(ApplicationModel.fromDoc).toList();
      list.sort((a, b) {
        final da = a.appliedAt ?? Timestamp(0, 0);
        final db_ = b.appliedAt ?? Timestamp(0, 0);
        return db_.compareTo(da);
      });
      return list;
    });
  }

  /// Mengubah status lamaran + membuat notifikasi in-app untuk alumni.
  /// Push FCM dikirim oleh Cloud Function onApplicationStatusChanged.
  Future<void> updateStatus({
    required ApplicationModel application,
    required String status,
    String note = '',
  }) async {
    if (!AppStatus.all.contains(status)) {
      throw ApplyException('Status tidak dikenal.');
    }
    await _col.doc(application.id).set({
      'status': status,
      'note': note.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (status == AppStatus.diterima || status == AppStatus.ditolak) {
      try {
        await DecisionLetterService.instance.createAndUpload(
          application: ApplicationModel(
            id: application.id,
            jobId: application.jobId,
            alumniId: application.alumniId,
            appliedAt: application.appliedAt,
            status: status,
            jobTitle: application.jobTitle,
            company: application.company,
            bkkId: application.bkkId,
            note: note.trim(),
          ),
          status: status,
        );
      } on FirebaseException {
        // Status tetap tersimpan bila Storage belum dikonfigurasi.
      }
    }

    await NotificationService.instance.create(
      userId: application.alumniId,
      title: 'Status lamaran diperbarui',
      body:
          'Lamaran ${application.jobTitle} kini berstatus ${Fmt.statusLabel(status)}.',
      type: 'application',
      referenceId: application.id,
    );
  }

  /// Menghapus seluruh lamaran pada sebuah lowongan (dipakai saat lowongan dihapus).
  Future<void> deleteByJob(String jobId, String bkkId) async {
    final snap = await _col
        .where('jobId', isEqualTo: jobId)
        .where('bkkId', isEqualTo: bkkId)
        .get();
    if (snap.docs.isEmpty) return;
    for (var i = 0; i < snap.docs.length; i += 500) {
      final batch = _db.batch();
      for (final doc in snap.docs.skip(i).take(500)) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }
}
