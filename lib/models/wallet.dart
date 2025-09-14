import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String uid;
  final double balance;

  Wallet({required this.uid, required this.balance});

  factory Wallet.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Wallet(
      uid: doc.id,
      balance: (data['balance'] ?? 0.0).toDouble(),
    );
  }
}
