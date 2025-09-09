import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtpConfirmScreen extends StatefulWidget {
  final String parcelId;
  const OtpConfirmScreen({super.key, required this.parcelId});

  @override
  State<OtpConfirmScreen> createState() => _OtpConfirmScreenState();
}

class _OtpConfirmScreenState extends State<OtpConfirmScreen> {
  final _otpCtrl = TextEditingController();
  final _svc = FirebaseFirestore.instance;

  Future<void> _sendOtp() async {
    final snap = await _svc.collection('parcels').doc(widget.parcelId).get();
    final parcel = snap.data()!;
    final senderUid = parcel['createdByUid'];

    final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
        .toString()
        .substring(0, 6);

    await _svc.collection('parcels').doc(widget.parcelId).update({
      'pendingOtp': {'type': 'confirm', 'code': otp, 'toUid': senderUid},
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // notify sender
    final notif = _svc
        .collection('users')
        .doc(senderUid)
        .collection('notifications')
        .doc();
    await notif.set({
      'id': notif.id,
      'parcelId': widget.parcelId,
      'type': 'confirm',
      'code': otp,
      'status': 'sent',
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("OTP sent to sender")));
  }

  Future<void> _verifyOtp() async {
    final entered = _otpCtrl.text.trim();
    final snap = await _svc.collection('parcels').doc(widget.parcelId).get();
    final data = snap.data()!;
    final pending = data['pendingOtp'];

    if (pending != null &&
        pending['type'] == 'confirm' &&
        pending['code'] == entered) {
      await _svc.collection('parcels').doc(widget.parcelId).update({
        'pendingOtp': FieldValue.delete(),
        'status': 'confirmed',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Order confirmed")));
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
      appBar: AppBar(title: const Text("Confirm Order OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
                onPressed: _sendOtp, child: const Text("Send OTP to Sender")),
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
