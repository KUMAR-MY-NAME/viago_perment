import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:packmate/models/parcel.dart';
import 'package:packmate/services/wallet_service.dart';

class CancellationRefundScreen extends StatefulWidget {
  const CancellationRefundScreen({super.key});

  @override
  State<CancellationRefundScreen> createState() =>
      _CancellationRefundScreenState();
}

class _CancellationRefundScreenState extends State<CancellationRefundScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _processRefund(Parcel parcel) async {
    if (currentUser == null) return;

    // Disable button to prevent multiple clicks
    setState(() {});

    try {
      final walletService = WalletService(currentUser!.uid);
      await walletService.refundMoney(currentUser!.uid, parcel.price, parcel.id);

      // Update the parcel to mark as refunded
      await FirebaseFirestore.instance
          .collection('parcels')
          .doc(parcel.id)
          .update({'refundStatus': 'refunded'});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refund processed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing refund: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Cancellation & Refund")),
        body: const Center(child: Text('Please log in to view this page.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Cancellation & Refund")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parcels')
            .where('createdByUid', isEqualTo: currentUser!.uid)
            .where('status', isEqualTo: 'cancelled')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('You have no cancelled packages.'));
          }

          final cancelledParcels = snapshot.data!.docs
              .map((doc) => Parcel.fromDoc(doc))
              .toList();

          return ListView.builder(
            itemCount: cancelledParcels.length,
            itemBuilder: (context, index) {
              final parcel = cancelledParcels[index];
              final bool wasPaid = parcel.paymentStatus == 'paid';
              final bool isRefunded = parcel.refundStatus == 'refunded';

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('Parcel ID: ${parcel.id}'),
                  subtitle: Text(
                      'Contents: ${parcel.contents}\nPrice: ₹${parcel.price.toStringAsFixed(2)}'),
                  trailing: wasPaid
                      ? ElevatedButton(
                          onPressed: isRefunded
                              ? null // Disable button if already refunded
                              : () => _processRefund(parcel),
                          child: Text(isRefunded ? 'Refunded' : 'Refund Amount'),
                        )
                      : null, // No button if not paid
                ),
              );
            },
          );
        },
      ),
    );
  }
}