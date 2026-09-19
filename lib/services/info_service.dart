import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/announcement_model.dart';
import '../models/banner_model.dart';
import '../models/scholarship_model.dart';
import '../models/training_model.dart';
import '../utils/constants.dart';

/// Pembacaan beasiswa, pelatihan, dan pengumuman.
class InfoService {
  InfoService._();
  static final InfoService instance = InfoService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<BannerModel>> watchBanners({int limit = 10}) => Stream.fromFuture(
        _db
            .collection(Col.banners)
            .where('isActive', isEqualTo: true)
            .limit(limit)
            .get(),
      ).map((s) {
        final items = s.docs.map(BannerModel.fromDoc).toList();
        items.sort((a, b) {
          final ad = a.createdAt;
          final bd = b.createdAt;
          if (ad == null && bd == null) return 0;
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad);
        });
        return items;
      });

  Stream<BannerModel?> watchBanner(String id) => Stream.fromFuture(
        _db.collection(Col.banners).doc(id).get(),
      ).map((d) => d.exists ? BannerModel.fromDoc(d) : null);

  Stream<List<ScholarshipModel>> watchScholarships({int limit = 100}) =>
      Stream.fromFuture(_db
              .collection(Col.scholarships)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get())
          .map((s) => s.docs.map(ScholarshipModel.fromDoc).toList());

  Stream<ScholarshipModel?> watchScholarship(String id) => Stream.fromFuture(
        _db.collection(Col.scholarships).doc(id).get(),
      ).map((d) => d.exists ? ScholarshipModel.fromDoc(d) : null);

  Future<ScholarshipModel?> getScholarship(String id) async {
    final doc = await _db.collection(Col.scholarships).doc(id).get();
    return doc.exists ? ScholarshipModel.fromDoc(doc) : null;
  }

  Future<Map<String, ScholarshipModel>> getScholarshipsByIds(
    Iterable<String> ids,
  ) async {
    return _getByIds(ids, Col.scholarships, ScholarshipModel.fromDoc);
  }

  Stream<List<TrainingModel>> watchTrainings({int limit = 100}) =>
      Stream.fromFuture(_db
              .collection(Col.trainings)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get())
          .map((s) => s.docs.map(TrainingModel.fromDoc).toList());

  Stream<TrainingModel?> watchTraining(String id) => Stream.fromFuture(
        _db.collection(Col.trainings).doc(id).get(),
      ).map((d) => d.exists ? TrainingModel.fromDoc(d) : null);

  Future<TrainingModel?> getTraining(String id) async {
    final doc = await _db.collection(Col.trainings).doc(id).get();
    return doc.exists ? TrainingModel.fromDoc(doc) : null;
  }

  Future<Map<String, TrainingModel>> getTrainingsByIds(
    Iterable<String> ids,
  ) async {
    return _getByIds(ids, Col.trainings, TrainingModel.fromDoc);
  }

  Stream<List<AnnouncementModel>> watchAnnouncements({int limit = 100}) =>
      Stream.fromFuture(_db
              .collection(Col.announcements)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get())
          .map((s) => s.docs.map(AnnouncementModel.fromDoc).toList());

  Stream<AnnouncementModel?> watchAnnouncement(String id) => Stream.fromFuture(
        _db.collection(Col.announcements).doc(id).get(),
      ).map((d) => d.exists ? AnnouncementModel.fromDoc(d) : null);

  Future<AnnouncementModel?> getAnnouncement(String id) async {
    final doc = await _db.collection(Col.announcements).doc(id).get();
    return doc.exists ? AnnouncementModel.fromDoc(doc) : null;
  }

  Future<Map<String, AnnouncementModel>> getAnnouncementsByIds(
    Iterable<String> ids,
  ) async {
    return _getByIds(ids, Col.announcements, AnnouncementModel.fromDoc);
  }

  Future<Map<String, T>> _getByIds<T>(
    Iterable<String> ids,
    String collection,
    T Function(DocumentSnapshot<Map<String, dynamic>>) fromDoc,
  ) async {
    final values = ids.toSet().toList();
    final result = <String, T>{};
    if (values.isEmpty) return result;
    for (var i = 0; i < values.length; i += 30) {
      final chunk = values.skip(i).take(30).toList();
      final snapshot = await _db
          .collection(collection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        result[doc.id] = fromDoc(doc);
      }
    }
    return result;
  }
}
