import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final stream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (c, s) {
          if (!s.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = s.data!.docs;
          if (docs.isEmpty)
            return const Center(child: Text('No notifications yet'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (c, i) {
              final d = docs[i].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text('OTP for ${d['type']}'),
                  subtitle:
                      Text('Parcel: ${d['parcelId']} • Code: ${d['code']}'),
                  trailing: Text(d['status'] ?? 'sent'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
