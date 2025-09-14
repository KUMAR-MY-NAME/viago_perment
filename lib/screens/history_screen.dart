import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:packmate/screens/package_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Queries for delivered packages
    final asSender = FirebaseFirestore.instance
        .collection('parcels')
        .where('createdByUid', isEqualTo: uid)
        .where('status', whereIn: ['delivered', 'canceled']);

    final asTraveler = FirebaseFirestore.instance
        .collection('parcels')
        .where('assignedTravelerUid', isEqualTo: uid)
        .where('status', whereIn: ['delivered', 'canceled']);

    final asReceiver = FirebaseFirestore.instance
        .collection('parcels')
        .where('trackedReceiverUid', isEqualTo: uid)
        .where('status', whereIn: ['delivered', 'canceled']);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sender'),
              Tab(text: 'Traveler'),
              Tab(text: 'Receiver'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _list(asSender, role: 'sender'),
            _list(asTraveler, role: 'traveler'),
            _list(asReceiver, role: 'receiver'),
          ],
        ),
      ),
    );
  }

  Widget _list(Query q, {required String role}) {
    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (c, s) {
        if (!s.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = s.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('No delivered packages yet'));
        }
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (c, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text('#${d['id'] ?? '-'} – ${d['contents'] ?? ''}'),
                subtitle: Text('Price: ₹${d['price']}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(d['status'] ?? ''),
                    TextButton(
                      child: const Text('View'),
                      onPressed: () {
                        Navigator.push(
                          c,
                          MaterialPageRoute(
                            builder: (_) => PackageDetailScreen(
                              parcelId: docs[i].id,
                              role: role,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
