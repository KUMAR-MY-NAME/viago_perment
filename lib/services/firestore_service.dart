import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get users => _db.collection('users');
  CollectionReference get usernames => _db.collection('usernames');

  Future<bool> isUsernameAvailable(String username) async {
    final doc = await usernames.doc(username.toLowerCase()).get();
    return !doc.exists;
  }

// Transactional reservation to avoid race conditions
  Future<bool> tryReserveUsername(String username, String uid) async {
    final uname = username.toLowerCase();
    final unameRef = usernames.doc(uname);

    return await _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(unameRef);
      if (snap.exists) {
        // Already reserved/taken
        return false;
      }
      tx.set(
          unameRef, {'uid': uid, 'reservedAt': FieldValue.serverTimestamp()});
      return true;
    });
  }

  Future<void> reserveUsername(String username, String uid) async {
    await usernames.doc(username.toLowerCase()).set({'uid': uid});
  }

  Future<void> releaseUsername(String username) async {
    await usernames.doc(username.toLowerCase()).delete();
  }

  Future<void> createUser(AppUser user) async {
    await users.doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<AppUser?> getUserByUsername(String username) async {
    final q = await users.where('username', isEqualTo: username).limit(1).get();
    if (q.docs.isEmpty) return null;
    return AppUser.fromMap(q.docs.first.data() as Map<String, dynamic>);
  }

  Future<void> updatePasswordHash(String uid, String newHash) async {
    await users.doc(uid).update({'passwordHash': newHash});
  }
}
