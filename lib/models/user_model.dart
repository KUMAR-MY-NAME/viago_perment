import 'package:cloud_firestore/cloud_firestore.dart'; // for Timestamp

class AppUser {
  final String uid;
  final String? username;
  final String? phone;
  final String? passwordHash;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    this.username,
    this.phone,
    this.passwordHash,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'phone': phone,
      'passwordHash': passwordHash,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!.toUtc()) : null,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final created = map['createdAt'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is DateTime) {
      createdAt = created;
    } else if (created is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(created);
    }

    return AppUser(
      uid: map['uid'] as String? ?? '',
      username: map['username'] as String?,
      phone: map['phone'] as String?,
      passwordHash: map['passwordHash'] as String?,
      createdAt: createdAt,
    );
  }

  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('Document ${doc.id} has no data');
    }
    return AppUser.fromMap(data);
  }
}
