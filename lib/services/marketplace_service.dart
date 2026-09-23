import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/marketplace_product.dart';
import '../utils/constants.dart';

class MarketplaceService {
  MarketplaceService._();
  static final instance = MarketplaceService._();
  final _db = FirebaseFirestore.instance;

  Stream<List<MarketplaceProduct>> watchProducts() {
    return Stream.fromFuture(_db.collection(Col.marketplaceProducts).get())
        .map((snap) {
      if (snap.docs.isEmpty) return MarketplaceProduct.products;
      return snap.docs
          .map((doc) => MarketplaceProduct.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Future<void> save(MarketplaceProduct product) => _db
      .collection(Col.marketplaceProducts)
      .doc(product.id)
      .set(product.toMap(), SetOptions(merge: true));

  Future<void> remove(String id) =>
      _db.collection(Col.marketplaceProducts).doc(id).delete();

  Future<void> seedDefaults() async {
    final batch = _db.batch();
    for (final product in MarketplaceProduct.products) {
      batch.set(_db.collection(Col.marketplaceProducts).doc(product.id),
          product.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }
}
