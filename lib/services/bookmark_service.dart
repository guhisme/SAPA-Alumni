import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bookmark_model.dart';
import '../utils/constants.dart';

class BookmarkService {
  BookmarkService._();
  static final BookmarkService instance = BookmarkService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection(Col.bookmarks);

  /// ID dibuat deterministik agar tidak mungkin ada duplikat.
  String _idOf(String userId, String contentType, String contentId) =>
      '${userId}_${contentType}_$contentId';

  Stream<List<BookmarkModel>> watchBookmarks(String userId) {
    return Stream.fromFuture(_col.where('userId', isEqualTo: userId).get())
        .map((s) {
      final list = s.docs.map(BookmarkModel.fromDoc).toList();
      list.sort((a, b) {
        final da = a.createdAt ?? Timestamp(0, 0);
        final db_ = b.createdAt ?? Timestamp(0, 0);
        return db_.compareTo(da);
      });
      return list;
    });
  }

  Stream<bool> watchIsBookmarked({
    required String userId,
    required String contentType,
    required String contentId,
  }) {
    return Stream.fromFuture(
      _col.doc(_idOf(userId, contentType, contentId)).get(),
    ).map((d) => d.exists);
  }

  /// Menyimpan/menghapus bookmark. Mengembalikan status akhir (true = tersimpan).
  Future<bool> toggle({
    required String userId,
    required String contentType,
    required String contentId,
  }) async {
    final ref = _col.doc(_idOf(userId, contentType, contentId));
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
      return false;
    }
    await ref.set(BookmarkModel(
      id: ref.id,
      userId: userId,
      contentId: contentId,
      contentType: contentType,
    ).toMap());
    return true;
  }

  Future<void> remove(String bookmarkId) => _col.doc(bookmarkId).delete();
}
