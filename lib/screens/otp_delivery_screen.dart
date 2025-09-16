// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:packmate/services/firestore_service.dart';

class OtpDeliveryScreen extends StatefulWidget {
  final String parcelId;
  const OtpDeliveryScreen({super.key, required this.parcelId});

  @override
  State<OtpDeliveryScreen> createState() => _OtpDeliveryScreenState();
}

class _OtpDeliveryScreenState extends State<OtpDeliveryScreen> {
  final _otpCtrl = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isOtpSent = false;
  bool _isSendingOtp = false;

  Future<void> _sendOtp() async {
    setState(() {
      _isSendingOtp = true;
    });

    try {
      final snap = await FirebaseFirestore.instance
          .collection('parcels')
          .doc(widget.parcelId)
          .get();
      final parcel = snap.data();

      if (parcel == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: Parcel not found.")),
        );
        return;
      }

      final who = parcel['confirmationWho'] ?? 'receiver';
      final targetUid = who == 'sender'
          ? parcel['createdByUid']
          : (parcel['trackedReceiverUid'] ?? parcel['receiverUid']);

      if (targetUid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Error: The designated receiver has not registered or started tracking this parcel yet.')),
        );
        return;
      }

      await _firestoreService.createAndSendOtp(
        parcelId: widget.parcelId,
        type: 'delivery',
        targetUid: targetUid,
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("OTP sent successfully.")));
      setState(() {
        _isOtpSent = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to send OTP: $e")),
      );
    } finally {
      setState(() {
        _isSendingOtp = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final entered = _otpCtrl.text.trim();
    if (entered.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please enter the OTP.")));
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('parcels')
        .doc(widget.parcelId)
        .get();
    final data = snap.data();
    final pending = data?['pendingOtp'];

    if (pending != null &&
        pending['type'] == 'delivery' &&
        pending['code'] == entered) {
      await FirebaseFirestore.instance
          .collection('parcels')
          .doc(widget.parcelId)
          .update({
        'pendingOtp': FieldValue.delete(),
        'status': 'delivered',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Delivery confirmed!")));
      Navigator.pop(context); // Go back from OTP screen
      Navigator.pop(context); // Go back from package detail screen
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid OTP. Please try again.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Confirm Delivery")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isOtpSent)
              ElevatedButton(
                onPressed: _isSendingOtp ? null : _sendOtp,
                child: _isSendingOtp
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Send OTP to Recipient"),
              ),
            if (_isOtpSent) ...[
              const Text(
                "An OTP has been sent. Please enter it below to confirm the delivery.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Enter OTP",
                    border: OutlineInputBorder(),
                  ),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _verifyOtp,
                child: const Text("Verify OTP & Complete Delivery"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}