import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:packmate/models/parcel.dart';
import 'package:packmate/services/firestore_service.dart';
import 'package:packmate/services/wallet_service.dart';

class CancellationRefundScreen extends StatefulWidget {
  const CancellationRefundScreen({super.key});

  @override
  State<CancellationRefundScreen> createState() =>
      _CancellationRefundScreenState();
}

class _CancellationRefundScreenState extends State<CancellationRefundScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late final FirestoreService _firestoreService;
  late final WalletService _walletService;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _firestoreService = FirestoreService();
      _walletService = WalletService(currentUser!.uid);
    }
  }

  Future<void> _processRefund(Parcel parcel) async {
    if (currentUser == null) return;

    // Show a confirmation dialog before proceeding
    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm Refund'),
            content: Text(
                'Are you sure you want to refund ₹${parcel.price.toStringAsFixed(2)} to your wallet?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Refund'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    // Show a loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      // Use the wallet service to process the refund
      await _walletService.refundMoney(
          currentUser!.uid, parcel.price, parcel.id);

      // Update the parcel to mark as refunded
      await _firestoreService
          .updateParcel(parcel.id, {'refundStatus': 'refunded'});

      // Close the loading indicator
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Refund processed successfully!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      // Close the loading indicator
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error processing refund: $e'),
              backgroundColor: Colors.red),
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
      appBar: AppBar(
        title: const Text("Cancellation & Refund"),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: StreamBuilder<List<Parcel>>(
        stream: _firestoreService.streamMyCancelledParcelsAsSender(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You have no cancelled packages.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final cancelledParcels = snapshot.data!;

          return ListView.builder(
            itemCount: cancelledParcels.length,
            itemBuilder: (context, index) {
              final parcel = cancelledParcels[index];
              final bool wasPaid = parcel.paymentStatus == 'paid';
              final bool isRefunded = parcel.refundStatus == 'refunded';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12.0),
                  title: Text(
                    'Parcel: ${parcel.contents}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('To: ${parcel.receiverName}'),
                      Text('Price: ₹${parcel.price.toStringAsFixed(2)}'),
                      Text('Status: ${parcel.status}'),
                      if (wasPaid)
                        Text('Payment: Paid', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                      if (!wasPaid)
                        Text('Payment: Not Paid', style: TextStyle(color: Colors.orange[700], fontWeight: FontWeight.bold)),
                      if (isRefunded)
                        Text('Refund: Processed', style: TextStyle(color: Colors.blue[700])),
                    ],
                  ),
                  trailing: wasPaid && !isRefunded
                      ? ElevatedButton(
                          onPressed: () => _processRefund(parcel),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: const Text('Refund'),
                        )
                      : wasPaid && isRefunded
                          ? const Chip(
                              label: Text('Refunded'),
                              backgroundColor: Colors.grey,
                            )
                          : const Chip(
                              label: Text('Not Paid'),
                              backgroundColor: Colors.transparent,
                              shape: StadiumBorder(side: BorderSide(color: Colors.grey)),
                            ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}