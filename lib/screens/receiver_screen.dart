import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({super.key});

  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _rid = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track Parcel')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(blurRadius: 8, color: Colors.black12)
              ],
            ),
            child: Column(children: [
              _input('Name', _name),
              _input('Phone Number', _phone, type: TextInputType.phone),
              _input('Receiver ID', _rid),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => setState(() {}),
                child: const Text('Find My Parcel'),
              )
            ]),
          ),
          const SizedBox(height: 16),
          _results(_name.text.trim(), _phone.text.trim(), _rid.text.trim()),
        ]),
      ),
    );
  }

  Widget _results(String name, String phone, String rid) {
    if (name.isEmpty && phone.isEmpty && rid.isEmpty) return const SizedBox();
    Query q = FirebaseFirestore.instance.collection('parcels');
    if (name.isNotEmpty) q = q.where('receiverName', isEqualTo: name);
    if (phone.isNotEmpty) q = q.where('receiverPhone', isEqualTo: phone);
    if (rid.isNotEmpty) q = q.where('receiverId', isEqualTo: rid);

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (c, s) {
        if (!s.hasData) return const SizedBox();
        final docs = s.data!.docs;
        if (docs.isEmpty) return const Text('No matching parcel');
        return ListView.builder(
          itemCount: docs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (c, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text('#${d['id']} – ${d['contents']}'),
                subtitle: Text(
                    'Sender: ${d['senderName']}  Traveler: ${d['assignedTravelerName'] ?? '—'}  Cost: ₹${d['price']}'),
                trailing: TextButton(
                  child: const Text('View'),
                  onPressed: () => _showDetails(context, docs[i].id),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDetails(BuildContext context, String parcelId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        final ref =
            FirebaseFirestore.instance.collection('parcels').doc(parcelId);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<DocumentSnapshot>(
            stream: ref.snapshots(),
            builder: (c, s) {
              if (!s.hasData)
                return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()));
              final p = s.data!.data() as Map<String, dynamic>;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Package #${p['id']} – ${p['contents']}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                      'Pickup: ${p['pickupCity']} • Destination: ${p['destCity']}'),
                  Text(
                      'Traveler: ${p['assignedTravelerName'] ?? 'Not selected'}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      // When receiver starts tracking, mark parcel.trackedReceiverUid so it appears in Receiver's MyTrip
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('You must be signed in to track')));
                        return;
                      }
                      await FirebaseFirestore.instance
                          .collection('parcels')
                          .doc(parcelId)
                          .update({
                        'trackedReceiverUid': uid,
                        'updatedAt': FieldValue.serverTimestamp()
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Parcel added to your Receiver MyTrip')));
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Start Tracking (Add to MyTrip)'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      // If receiver chosen for delivery confirmation, they may request delivery OTP to themselves
                      final snap = await FirebaseFirestore.instance
                          .collection('parcels')
                          .doc(parcelId)
                          .get();
                      final data = snap.data() as Map<String, dynamic>;
                      if (data['confirmationWho'] == 'receiver') {
                        final uid = FirebaseAuth.instance.currentUser?.uid ??
                            data['createdByUid'];
                        final otp = (100000 +
                                (DateTime.now().millisecondsSinceEpoch %
                                    900000))
                            .toString()
                            .substring(0, 6);
                        await FirebaseFirestore.instance
                            .collection('parcels')
                            .doc(parcelId)
                            .update({
                          'pendingOtp': {
                            'type': 'delivery',
                            'code': otp,
                            'toUid': uid
                          },
                          'updatedAt': FieldValue.serverTimestamp()
                        });
                        final notif = FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('notifications')
                            .doc();
                        await notif.set({
                          'id': notif.id,
                          'parcelId': parcelId,
                          'type': 'delivery',
                          'code': otp,
                          'status': 'sent',
                          'createdAt': FieldValue.serverTimestamp()
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'Delivery OTP sent to your notifications. Share with traveler')));
                          Navigator.pop(context);
                        }
                      } else {
                        if (context.mounted)
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'This parcel requires sender confirmation for delivery.')));
                      }
                    },
                    child: const Text(
                        'Get Delivery OTP (if you are chosen to confirm)'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _input(String label, TextEditingController c, {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }
}
