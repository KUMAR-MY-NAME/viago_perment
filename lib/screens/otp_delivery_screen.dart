// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpDeliveryScreen extends StatefulWidget {
  final String parcelId;
  const OtpDeliveryScreen({super.key, required this.parcelId});

  @override
  State<OtpDeliveryScreen> createState() => _OtpDeliveryScreenState();
}

class _OtpDeliveryScreenState extends State<OtpDeliveryScreen> {
  final _otpCtrl = TextEditingController();
  final _svc = FirebaseFirestore.instance;

  Future<void> _sendOtp() async {
    final snap = await _svc.collection('parcels').doc(widget.parcelId).get();
    final parcel = snap.data()!;
    final who = parcel['confirmationWho'] ?? 'receiver';
    String targetUid = parcel['createdByUid'];
    if (who == 'receiver' && parcel['receiverUid'] != null) {
      targetUid = parcel['receiverUid'];
    }

    final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
        .toString()
        .substring(0, 6);

    await _svc.collection('parcels').doc(widget.parcelId).update({
      'pendingOtp': {'type': 'delivery', 'code': otp, 'toUid': targetUid},
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final notif = _svc
        .collection('users')
        .doc(targetUid)
        .collection('notifications')
        .doc();
    await notif.set({
      'id': notif.id,
      'parcelId': widget.parcelId,
      'type': 'delivery',
      'code': otp,
      'status': 'sent',
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("OTP sent")));
  }

  Future<void> _verifyOtp() async {
    final entered = _otpCtrl.text.trim();
    final snap = await _svc.collection('parcels').doc(widget.parcelId).get();
    final data = snap.data()!;
    final pending = data['pendingOtp'];

    if (pending != null &&
        pending['type'] == 'delivery' &&
        pending['code'] == entered) {
      await _svc.collection('parcels').doc(widget.parcelId).update({
        'pendingOtp': FieldValue.delete(),
        'status': 'delivered',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Delivery confirmed")));
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Invalid OTP")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Delivery OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(onPressed: _sendOtp, child: const Text("Send OTP")),
            const SizedBox(height: 16),
            TextField(
                controller: _otpCtrl,
                decoration: const InputDecoration(labelText: "Enter OTP")),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _verifyOtp, child: const Text("Verify OTP")),
          ],
        ),
      ),
    );
  }
}
