import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:packmate/models/report.dart';
import 'package:packmate/models/user_model.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reports'),
      ),
      body: _buildReportsList(),
    );
  }

  Widget _buildReportsList() {
    if (currentUser == null) return const Center(child: Text('Please log in.'));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .where('reportedByUid', isEqualTo: currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('You have not filed any reports.'));
        }

        final reports = snapshot.data!.docs
            .map((doc) => Report.fromMap(doc.data() as Map<String, dynamic>))
            .toList();

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(report.reportedUid)
                  .get(),
              builder: (context, userSnapshot) {
                String username = 'Unknown User';

                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  username = 'Loading...';
                } else if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  final userData = AppUser.fromDoc(userSnapshot.data!);
                  username = userData.username ?? 'Unknown User';
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text('Report against: $username'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Parcel ID: ${report.parcelId ?? 'N/A'}'),
                        Text('Reason: ${report.reason ?? 'No reason provided'}'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
