import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

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
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _rid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFA8AD5F),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Track Parcel',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildCard(
            title: 'Parcel Details:',
            children: [
              _buildInput('Name:', _name, hint: 'Full Name'),
              _buildInput('Phone Number:', _phone, hint: '+91 XXXXXXXXXX', type: TextInputType.phone),
              _buildInput('Receiver ID:', _rid, hint: 'Unique ID'),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  '(Enter the receiver details set by the sender while updating the parcel.)',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA8AD5F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () => setState(() {}),
              child: Text(
                'Find My Parcel',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _results(_name.text.trim(), _phone.text.trim(), _rid.text.trim()),
        ]),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(
          color: Color(0xFFA8AD5F),
          width: 4.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFA8AD5F),
              ),
            ),
            const Divider(color: Color(0xFFA8AD5F)),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController c, {TextInputType? type, String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: c,
              keyboardType: type,
              style: GoogleFonts.poppins(),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Color(0xFFA8AD5F), width: 2.0),
                ),
              ),
            ),
          ),
        ],
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
                    'Sender: ${d['senderName']}  Traveler: ${d['assignedTravelerName'] ?? '—'}  Cost: ₹${d['price']}'),
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
              if (!s.hasData) {
                return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()));
              }
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
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text(
                                  'This parcel requires sender confirmation for delivery.')));
                        }
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
}
