import 'package:cloud_firestore/cloud_firestore.dart'; // for Timestamp

class AppUser {
  final String uid;
  final String username;
  final String phone;
  final String passwordHash;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.username,
    required this.phone,
    required this.passwordHash,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'phone': phone,
      'passwordHash': passwordHash,
      'createdAt': Timestamp.fromDate(createdAt.toUtc()),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final created = map['createdAt'];
    DateTime createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is DateTime) {
      createdAt = created;
    } else if (created is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(created);
    } else {
// If you prefer not to throw, replace with:
// createdAt = DateTime.now().toUtc();
      throw StateError("Invalid createdAt type: ${created.runtimeType}");
    }

    return AppUser(
      uid: map['uid'] as String,
      username: map['username'] as String,
      phone: map['phone'] as String,
      passwordHash: map['passwordHash'] as String,
      createdAt: createdAt,
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Document ${doc.id} has no data');
    }
    return AppUser.fromMap(data);
  }
}
