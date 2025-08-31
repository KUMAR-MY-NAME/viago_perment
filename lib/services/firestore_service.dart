import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collections
  CollectionReference get users => _db.collection('users');
  CollectionReference get usernames => _db.collection('usernames');
  CollectionReference get packages => _db.collection('packages'); // 👈 new

  /// ---------------- USERNAME / USER -----------------

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
      tx.set(unameRef, {
        'uid': uid,
        'reservedAt': FieldValue.serverTimestamp(),
      });
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

  /// ---------------- PACKAGE HELPERS -----------------

  /// Generate a random 6-digit OTP
  String _generateOtp() {
    final rand = Random();
    return (100000 + rand.nextInt(900000)).toString();
  }

  /// Create a new package (from sender)
  Future<String> createPackage(Map<String, dynamic> packageData) async {
    final otp = _generateOtp();
    final docRef = await packages.add({
      ...packageData,
      'otp': otp, // 🔹 store OTP
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Update package status (e.g. pending, requested, accepted, delivered)
  Future<void> updatePackageStatus(String packageId, String status) async {
    await packages.doc(packageId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// ✅ Get OTP for a specific package (always return as String)
  Future<String?> getPackageOtp(String packageId) async {
    final doc = await packages.doc(packageId).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return null;

    final otp = data['otp'];
    if (otp == null) return null;

    return otp.toString(); // 🔹 ensures int/string is always returned as String
  }

  /// Get packages going to a specific destination (for travelers)
  Stream<QuerySnapshot> getPackagesForDestination(String destination) {
    return packages
        .where('receiverAddress', isEqualTo: destination)
        .snapshots();
  }

  /// Assign a traveler to a package
  Future<void> assignTraveler(String packageId, String travelerId) async {
    await packages.doc(packageId).update({
      'travelerId': travelerId,
      'status': 'accepted',
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }
}
