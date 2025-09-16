import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:packmate/services/wallet_service.dart';
import 'package:packmate/services/pricing.dart';
import 'package:packmate/models/wallet_transaction.dart'; // For TransactionType

class ReceiverPaymentScreen extends StatefulWidget {
  final String parcelId;
  final String? receiverUid; // Receiver's UID (can be null if not registered)
  final String senderUid;
  final double amount;

  const ReceiverPaymentScreen({
    super.key,
    required this.parcelId,
    this.receiverUid,
    required this.senderUid,
    required this.amount,
  });

  @override
  State<ReceiverPaymentScreen> createState() => _ReceiverPaymentScreenState();
}

class _ReceiverPaymentScreenState extends State<ReceiverPaymentScreen> {
  String _payMethod = 'wallet'; // 'wallet' | 'phonepe' | 'googlepay' | 'paytm'
  bool _isProcessingPayment = false;
  late final WalletService _walletService;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _walletService = WalletService(currentUser.uid);
    }
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessingPayment = true);
    bool paymentSuccess = false;
    String? message;

    final travelerUid = (await FirebaseFirestore.instance.collection('parcels').doc(widget.parcelId).get()).data()?['assignedTravelerUid'];

    if (travelerUid == null) {
      message = 'Traveler not assigned yet.';
      paymentSuccess = false;
    } else {
      if (_payMethod == 'wallet') {
        paymentSuccess = await _walletService.processParcelPayment(
          widget.receiverUid ?? FirebaseAuth.instance.currentUser!.uid, // Receiver pays
          travelerUid, // Traveler receives
          widget.amount,
          widget.parcelId,
          Pricing.getPlatformFee(widget.amount),
        );
        if (!paymentSuccess) {
          message = 'Insufficient balance in wallet.';
        }
      } else {
        // Simulate external payment success
        await Future.delayed(const Duration(seconds: 2));
        paymentSuccess = true;
        message = 'Payment simulated successfully!';
      }
    }

    if (!mounted) return;
    setState(() => _isProcessingPayment = false);

    if (paymentSuccess) {
      // Update parcel payment status to paid and status back to in_transit
      await FirebaseFirestore.instance.collection('parcels').doc(widget.parcelId).update({
        'paymentStatus': 'paid',
        'status': 'in_transit', // Reset status to allow traveler to proceed
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Payment successful!')),
      );
      Navigator.of(context).pop(); // Pop ReceiverPaymentScreen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Payment failed. Please try again.')),
      );
    }
  }

  Widget _buildRadio<T>(String text, T value, T groupValue, ValueChanged<T?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Radio<T>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
          Text(text),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receiver Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amount to Pay: ₹${widget.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text('Choose Payment Method:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildRadio('Wallet', 'wallet', _payMethod, (value) {
              setState(() => _payMethod = value!);
            }),
            _buildRadio('PhonePe (Simulated)', 'phonepe', _payMethod, (value) {
              setState(() => _payMethod = value!);
            }),
            _buildRadio('Google Pay (Simulated)', 'googlepay', _payMethod, (value) {
              setState(() => _payMethod = value!);
            }),
            _buildRadio('Paytm (Simulated)', 'paytm', _payMethod, (value) {
              setState(() => _payMethod = value!);
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessingPayment ? null : _processPayment,
                child: _isProcessingPayment
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Pay Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
