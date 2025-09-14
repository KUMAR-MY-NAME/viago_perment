import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { deposit, withdrawal, payment, refund }

class WalletTransaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String? parcelId;
  final DateTime createdAt;

  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    this.parcelId,
    required this.createdAt,
  });

  factory WalletTransaction.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WalletTransaction(
      id: doc.id,
      amount: (data['amount'] ?? 0.0).toDouble(),
      type: TransactionType.values.firstWhere((e) => e.toString() == data['type'], orElse: () => TransactionType.payment),
      parcelId: data['parcelId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'type': type.toString(),
      'parcelId': parcelId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
