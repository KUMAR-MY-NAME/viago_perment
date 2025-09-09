import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/traveler.dart';

class TravelerScreen extends StatefulWidget {
  const TravelerScreen({super.key});

  @override
  State<TravelerScreen> createState() => _TravelerScreenState();
}

class _TravelerScreenState extends State<TravelerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fromCity = TextEditingController();
  final _toCity = TextEditingController();
  final _capacity = TextEditingController();
  DateTime? _date;
  String _mode = 'vehicle';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Trip')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _tripForm(),
          const SizedBox(height: 20),
          _PackagesList(fromCityCtrl: _fromCity, toCityCtrl: _toCity),
        ]),
      ),
    );
  }

  Widget _tripForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
      ),
      child: Form(
        key: _formKey,
        child: Column(children: [
          _input('From (City)', _fromCity),
          _input('To (City)', _toCity),
          Row(children: [
            Expanded(
                child: Text(_date == null
                    ? 'Travel date: not set'
                    : 'Travel date: ${_date!.day}/${_date!.month}/${_date!.year}')),
            TextButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(
                      context: context,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 365)),
                      initialDate: now);
                  if (d != null) setState(() => _date = d);
                },
                child: const Text('Pick'))
          ]),
          DropdownButtonFormField<String>(
            value: _mode,
            items: const [
              DropdownMenuItem(value: 'vehicle', child: Text('Vehicle')),
              DropdownMenuItem(value: 'bus', child: Text('Bus')),
              DropdownMenuItem(value: 'train', child: Text('Train')),
              DropdownMenuItem(value: 'flight', child: Text('Flight')),
            ],
            onChanged: (v) => setState(() => _mode = v!),
            decoration: const InputDecoration(
                border: OutlineInputBorder(), labelText: 'Mode of travel'),
          ),
          const SizedBox(height: 8),
          _input('Capacity (kg)', _capacity, type: TextInputType.number),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _saveTrip,
            child: const Text('Update MyTrip'),
          )
        ]),
      ),
    );
  }

  Widget _input(String label, TextEditingController c, {TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
      ),
    );
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate() || _date == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = FirebaseAuth.instance.currentUser;
    final travelerName = user?.displayName ?? 'Traveler';

    final traveler = Traveler(
      id: uid,
      travelerUid: uid,
      travelerName: travelerName,
      fromCity: _fromCity.text.trim(),
      toCity: _toCity.text.trim(),
      travelDate: _date!,
      mode: _mode,
      capacityKg: double.tryParse(_capacity.text) ?? 0,
      createdAt: DateTime.now(),
    );

    await FirebaseFirestore.instance
        .collection('trips')
        .doc(uid)
        .set(traveler.toMap(), SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Trip updated.')));
    }
  }
}

class _PackagesList extends StatelessWidget {
  final TextEditingController fromCityCtrl;
  final TextEditingController toCityCtrl;
  const _PackagesList({required this.fromCityCtrl, required this.toCityCtrl});

  @override
  Widget build(BuildContext context) {
    final from = fromCityCtrl.text.trim();
    final to = toCityCtrl.text.trim();

    if (from.isEmpty || to.isEmpty) {
      return const SizedBox();
    }

    final q = FirebaseFirestore.instance
        .collection('parcels')
        .where('pickupCity', isEqualTo: from)
        .where('destCity', isEqualTo: to)
        .where('status', isEqualTo: 'posted');

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Text('No packages available for this route.');
        }
        return ListView.builder(
          itemCount: docs.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (c, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text('#${d['id'] ?? docs[i].id} – ${d['contents']}'),
                subtitle: Text(
                    'Sender: ${d['senderName']}  •  Price: ₹${(d['price'] ?? 0).toString()}'),
                trailing: TextButton(
                  child: const Text('Select'),
                  onPressed: () async {
                    final uid = FirebaseAuth.instance.currentUser!.uid;
                    final user = FirebaseAuth.instance.currentUser;
                    final travelerName = user?.displayName ?? 'Traveler';

                    await FirebaseFirestore.instance
                        .collection('parcels')
                        .doc(docs[i].id)
                        .update({
                      'assignedTravelerUid': uid,
                      'assignedTravelerName': travelerName,
                      'status': 'selected',
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Package added to MyTrips (Traveler)')));
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
