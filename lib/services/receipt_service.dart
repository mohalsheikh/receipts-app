import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/receipt.dart';

enum RangeField { none, date, total, store }

class ReceiptService {
  ReceiptService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _db = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _userReceiptsCol(String uid) =>
      _db.collection('users').doc(uid).collection('receipts');

  Stream<List<Receipt>> watchReceipts(String uid) {
    return _userReceiptsCol(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Receipt.fromDoc(d)).toList());
  }

  Stream<List<Receipt>> watchReceiptsFiltered(
    String uid, {
    String? storePrefix,
    DateTime? startDate,
    DateTime? endDate,
    double? minTotal,
    double? maxTotal,
    bool? withImage,
    List<String>? categories,
  }) {
    final storePrefixNorm = (storePrefix ?? '').trim().toLowerCase();
    final wantsStoreRange = storePrefixNorm.isNotEmpty;
    final hasDateRange = (startDate != null || endDate != null);
    final hasTotalRange = (minTotal != null || maxTotal != null);

    final cats = (categories ?? [])
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    RangeField chosen = RangeField.none;
    if (hasDateRange) {
      chosen = RangeField.date;
    } else if (hasTotalRange) {
      chosen = RangeField.total;
    } else if (wantsStoreRange) {
      chosen = RangeField.store;
    }

    Query<Map<String, dynamic>> q = _userReceiptsCol(uid);

    if (withImage == true) {
      q = q.where('hasImage', isEqualTo: true);
    }

    final canUseWhereIn = cats.isNotEmpty && cats.length <= 10;
    if (canUseWhereIn) {
      q = q.where('categoryLower', whereIn: cats);
    }

    switch (chosen) {
      case RangeField.date:
        if (startDate != null) {
          final d0 = DateTime(startDate.year, startDate.month, startDate.day);
          q = q.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(d0));
        }
        if (endDate != null) {
          final eod = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
            999,
          );
          q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(eod));
        }
        q = q.orderBy('date', descending: true);
        break;

      case RangeField.total:
        if (minTotal != null) {
          q = q.where('total', isGreaterThanOrEqualTo: minTotal);
        }
        if (maxTotal != null) {
          q = q.where('total', isLessThanOrEqualTo: maxTotal);
        }
        q = q
            .orderBy('total', descending: true)
            .orderBy('date', descending: true);
        break;

      case RangeField.store:
        q = q
            .where('storeLower', isGreaterThanOrEqualTo: storePrefixNorm)
            .where('storeLower', isLessThan: '$storePrefixNorm\uf8ff')
            .orderBy('storeLower')
            .orderBy('date', descending: true);
        break;

      case RangeField.none:
        q = q.orderBy('date', descending: true);
        break;
    }

    return q.snapshots().map((snap) {
      var list = snap.docs.map((d) => Receipt.fromDoc(d)).toList();

      if (wantsStoreRange && chosen != RangeField.store) {
        list = list
            .where((r) => r.store.toLowerCase().startsWith(storePrefixNorm))
            .toList();
      }
      if (chosen != RangeField.date) {
        if (startDate != null)
          list = list.where((r) => !r.date.isBefore(startDate)).toList();
        if (endDate != null)
          list = list.where((r) => !r.date.isAfter(endDate)).toList();
      }
      if (chosen != RangeField.total) {
        if (minTotal != null)
          list = list.where((r) => r.total >= minTotal).toList();
        if (maxTotal != null)
          list = list.where((r) => r.total <= maxTotal).toList();
      }
      if (cats.isNotEmpty && !canUseWhereIn) {
        list = list.where((r) {
          final cat = (r.category ?? '').trim().toLowerCase();
          return cats.contains(cat);
        }).toList();
      }

      return list;
    });
  }

  Future<String?> uploadImage({
    required String uid,
    required String receiptId,
    required File file,
  }) async {
    final ref = _storage.ref().child('users/$uid/receipts/$receiptId.jpg');
    final task = await ref.putFile(file);
    return await task.ref.getDownloadURL();
  }

  Future<void> saveReceipt({
    required String uid,
    required Receipt receipt,
  }) async {
    final image = (receipt.imageUrl ?? '').trim();
    final categoryLower = (receipt.category ?? '').trim().toLowerCase();
    final storeLower = receipt.store.toLowerCase();

    await _userReceiptsCol(uid).doc(receipt.id).set({
      ...receipt.toJson(),
      'hasImage': image.isNotEmpty,
      'categoryLower': categoryLower,
      'storeLower': storeLower,
    }, SetOptions(merge: true));
  }

  Future<void> deleteReceipt({
    required String uid,
    required Receipt receipt,
  }) async {
    await _userReceiptsCol(uid).doc(receipt.id).delete();
    if ((receipt.imageUrl ?? '').isNotEmpty) {
      try {
        final ref = _storage.refFromURL(receipt.imageUrl!);
        await ref.delete();
      } catch (_) {}
    }
  }

  Future<List<Receipt>> fetchReceiptsInRange(
    String uid, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    Query<Map<String, dynamic>> q = _userReceiptsCol(uid);

    if (startDate != null) {
      final d0 = DateTime(startDate.year, startDate.month, startDate.day);
      q = q.where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(d0));
    }
    if (endDate != null) {
      final eod = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
        999,
      );
      q = q.where('date', isLessThanOrEqualTo: Timestamp.fromDate(eod));
    }

    q = q.orderBy('date', descending: true);
    final snap = await q.get();
    return snap.docs.map((d) => Receipt.fromDoc(d)).toList();
  }

  Future<List<Receipt>> fetchAllReceiptsOnce(String uid) async {
    final snap = await _userReceiptsCol(
      uid,
    ).orderBy('date', descending: true).get();
    return snap.docs.map((d) => Receipt.fromDoc(d)).toList();
  }
}
