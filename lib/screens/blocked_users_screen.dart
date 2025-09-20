import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:packmate/models/user_model.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
      ),
      body: _buildBlockedUsersList(),
    );
  }

  Widget _buildBlockedUsersList() {
    if (currentUser == null) return const Center(child: Text('Please log in.'));

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('profiles')
          .doc(currentUser!.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('Could not load user profile.'));
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final List<String> blockedUids = List<String>.from(data?['blockedUsers'] ?? []);

        if (blockedUids.isEmpty) {
          return const Center(
            child: Text('You have not blocked any users.'),
          );
        }

        return ListView.builder(
          itemCount: blockedUids.length,
          itemBuilder: (context, index) {
            final blockedUid = blockedUids[index];
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(blockedUid)
                  .get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    title: Text(blockedUid),
                    subtitle: const Text('Loading user...'),
                  );
                }
                if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                  return ListTile(
                    title: Text(blockedUid),
                    subtitle: const Text('User not found.'),
                  );
                }

                final blockedUserData = AppUser.fromDoc(userSnapshot.data!);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Text(blockedUserData.username ?? 'Unknown User'),
                    subtitle: Text('UID: ${blockedUserData.uid}'),
                                        trailing: ElevatedButton(
                      child: const Text('Unblock'),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection('profiles')
                            .doc(currentUser!.uid)
                            .update({
                          'blockedUsers': FieldValue.arrayRemove([blockedUid])
                        }).then((_) {
                          // We call setState here to trigger a rebuild of the outer FutureBuilder
                          setState(() {});
                        });
                      },
                    ),
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
