import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:packmate/models/wallet.dart';
import 'package:packmate/models/wallet_transaction.dart';

class WalletService {
  final String uid;
  late final DocumentReference<Map<String, dynamic>> _walletRef;

  WalletService(this.uid) {
    _walletRef = FirebaseFirestore.instance.collection('wallets').doc(uid);
  }

  Stream<Wallet> get walletStream {
    return _walletRef.snapshots().map((doc) {
      if (doc.exists) {
        return Wallet.fromDoc(doc);
      } else {
        // Create wallet if it doesn't exist
        _walletRef.set({'balance': 0.0});
        return Wallet(uid: uid, balance: 0.0);
      }
    });
  }

  Stream<List<WalletTransaction>> get transactionsStream {
    return _walletRef.collection('transactions').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => WalletTransaction.fromDoc(doc)).toList();
    });
  }

  Future<void> addMoney(double amount, {String? parcelId, TransactionType type = TransactionType.deposit}) async {
    // In a real app, this would involve a payment gateway.
    // Here, we'll just simulate a successful deposit.
    final transactionRef = _walletRef.collection('transactions').doc();
    final transaction = WalletTransaction(
      id: transactionRef.id,
      amount: amount,
      type: type,
      parcelId: parcelId,
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final walletSnapshot = await tx.get(_walletRef);
      final currentBalance = (walletSnapshot.data()?['balance'] ?? 0.0).toDouble();
      tx.update(_walletRef, {'balance': currentBalance + amount});
      tx.set(transactionRef, transaction.toMap());
    });
  }

  Future<bool> processParcelPayment(String senderUid, String travelerUid, double amount, String parcelId, double platformFee) async {
    final senderWalletRef = FirebaseFirestore.instance.collection('wallets').doc(senderUid);
    final travelerWalletRef = FirebaseFirestore.instance.collection('wallets').doc(travelerUid);

    final senderTransactionRef = senderWalletRef.collection('transactions').doc();
    final travelerTransactionRef = travelerWalletRef.collection('transactions').doc();

    final senderTransaction = WalletTransaction(
      id: senderTransactionRef.id,
      amount: -amount, // Negative for sender
      type: TransactionType.payment,
      parcelId: parcelId,
      createdAt: DateTime.now(),
    );

    final travelerAmount = amount - platformFee;
    final travelerTransaction = WalletTransaction(
      id: travelerTransactionRef.id,
      amount: travelerAmount,
      type: TransactionType.deposit,
      parcelId: parcelId,
      createdAt: DateTime.now(),
    );

    return await FirebaseFirestore.instance.runTransaction((tx) async {
      final senderWalletSnapshot = await tx.get(senderWalletRef);
      final senderBalance = (senderWalletSnapshot.data()?['balance'] ?? 0.0).toDouble();

      if (senderBalance < amount) {
        // Not enough balance
        return false;
      }

      // Deduct from sender
      tx.update(senderWalletRef, {'balance': senderBalance - amount});
      tx.set(senderTransactionRef, senderTransaction.toMap());

      // Add to traveler
      final travelerWalletSnapshot = await tx.get(travelerWalletRef);
      final travelerBalance = (travelerWalletSnapshot.data()?['balance'] ?? 0.0).toDouble();
      tx.update(travelerWalletRef, {'balance': travelerBalance + travelerAmount});
      tx.set(travelerTransactionRef, travelerTransaction.toMap());
      
      return true;
    });
  }

  Future<void> refundMoney(String recipientUid, double amount, String parcelId) async {
    final recipientWalletRef = FirebaseFirestore.instance.collection('wallets').doc(recipientUid);
    final recipientTransactionRef = recipientWalletRef.collection('transactions').doc();

    final recipientTransaction = WalletTransaction(
      id: recipientTransactionRef.id,
      amount: amount,
      type: TransactionType.refund,
      parcelId: parcelId,
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final recipientWalletSnapshot = await tx.get(recipientWalletRef);
      final recipientBalance = (recipientWalletSnapshot.data()?['balance'] ?? 0.0).toDouble();
      tx.update(recipientWalletRef, {'balance': recipientBalance + amount});
      tx.set(recipientTransactionRef, recipientTransaction.toMap());
    });
  }

  Future<bool> withdrawMoney(double amount) async {
    final transactionRef = _walletRef.collection('transactions').doc();
    final transaction = WalletTransaction(
      id: transactionRef.id,
      amount: -amount, // Negative for withdrawal
      type: TransactionType.withdrawal,
      createdAt: DateTime.now(),
    );

    return await FirebaseFirestore.instance.runTransaction((tx) async {
      final walletSnapshot = await tx.get(_walletRef);
      final currentBalance = (walletSnapshot.data()?['balance'] ?? 0.0).toDouble();

      if (currentBalance < amount) {
        return false; // Insufficient balance
      }

      tx.update(_walletRef, {'balance': currentBalance - amount});
      tx.set(transactionRef, transaction.toMap());
      return true;
    });
  }
}
