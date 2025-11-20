import 'package:cloud_firestore/cloud_firestore.dart';

class Receipt {
  final String id;
  final String store;
  final DateTime date;
  final double total;
  final DateTime? returnBy;
  final DateTime? warrantyEnds;
  final String? category;
  final String? imageUrl;
  final bool hasImage;

  const Receipt({
    required this.id,
    required this.store,
    required this.date,
    required this.total,
    this.returnBy,
    this.warrantyEnds,
    this.category,
    this.imageUrl,
    this.hasImage = false,
  });

  Map<String, dynamic> toJson() {
    final image = (imageUrl ?? '').trim();
    final cat = (category ?? '').trim();
    return {
      'store': store,
      'storeLower': store.toLowerCase(),
      'date': Timestamp.fromDate(date),
      'total': total,
      'returnBy': returnBy != null ? Timestamp.fromDate(returnBy!) : null,
      'warrantyEnds': warrantyEnds != null
          ? Timestamp.fromDate(warrantyEnds!)
          : null,
      'category': category,
      'categoryLower': cat.toLowerCase(),
      'imageUrl': imageUrl,
      'hasImage': image.isNotEmpty,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Receipt.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Receipt(
      id: doc.id,
      store: (data['store'] ?? '') as String,
      date: (data['date'] as Timestamp).toDate(),
      total: (data['total'] as num).toDouble(),
      returnBy: data['returnBy'] != null
          ? (data['returnBy'] as Timestamp).toDate()
          : null,
      warrantyEnds: data['warrantyEnds'] != null
          ? (data['warrantyEnds'] as Timestamp).toDate()
          : null,
      category: data['category'] as String?,
      imageUrl: data['imageUrl'] as String?,
      hasImage: (data['hasImage'] ?? false) as bool,
    );
  }
}
