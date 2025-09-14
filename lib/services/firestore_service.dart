import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../models/parcel.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  /// ---------------- COLLECTION REFERENCES -----------------
  CollectionReference get users => _db.collection('users');
  CollectionReference get usernames => _db.collection('usernames');
  CollectionReference get parcels => _db.collection('parcels');
  CollectionReference get trips => _db.collection('trips');

  /// ---------------- USERNAME / USER -----------------

  Future<bool> isUsernameAvailable(String username) async {
    final doc = await usernames.doc(username.toLowerCase()).get();
    return !doc.exists;
  }

  Future<bool> tryReserveUsername(String username, String uid) async {
    final uname = username.toLowerCase();
    final unameRef = usernames.doc(uname);

    return await _db.runTransaction<bool>((tx) async {
      final snap = await tx.get(unameRef);
      if (snap.exists) return false;
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

  /// ---------------- PARCELS -----------------

  Future<String> createParcel(Parcel p) async {
    final ref = parcels.doc();
    await ref.set(p.toMap());
    await ref.update({'id': ref.id});
    return ref.id;
  }

  Future<void> updateParcel(String id, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await parcels.doc(id).update(data);
  }

  Stream<List<Parcel>> streamParcelsByRoute(String fromCity, String toCity) {
    return parcels
        .where('pickupCity', isEqualTo: fromCity)
        .where('destCity', isEqualTo: toCity)
        .where('status', isEqualTo: 'posted')
        .snapshots()
        .map((s) => s.docs.map((d) => Parcel.fromDoc(d)).toList());
  }

  Stream<List<Parcel>> streamMyParcelsAsSender() {
    return parcels
        .where('createdByUid', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => Parcel.fromDoc(d)).toList());
  }

  Stream<List<Parcel>> streamMyParcelsAsTraveler() {
    return parcels
        .where('assignedTravelerUid', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => Parcel.fromDoc(d)).toList());
  }

  Stream<List<Parcel>> streamMyParcelsAsReceiver() {
    return parcels
        .where('trackedReceiverUid', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => Parcel.fromDoc(d)).toList());
  }

  /// ---------------- TRIPS -----------------

  Future<void> upsertTrip(String uid, Map<String, dynamic> tripData) async {
    final ref = trips.doc(uid);
    await ref.set(tripData, SetOptions(merge: true));
  }

  /// ---------------- OTP / NOTIFICATIONS -----------------

  String _generateOtp() {
    final rand = Random();
    return (100000 + rand.nextInt(900000)).toString();
  }

  Future<String> createAndSendOtp({
    required String parcelId,
    required String type, // confirm | delivery
    required String targetUid,
  }) async {
    final code = _generateOtp();

    // Save notification under target user
    final notifRef = users.doc(targetUid).collection('notifications').doc();
    await notifRef.set({
      'id': notifRef.id,
      'parcelId': parcelId,
      'type': type,
      'code': code,
      'status': 'sent',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Store pending OTP on parcel
    await parcels.doc(parcelId).update({
      'pendingOtp': {'type': type, 'code': code, 'toUid': targetUid},
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return code;
  }

  Future<bool> verifyOtp(String parcelId, String enteredCode) async {
    final doc = await parcels.doc(parcelId).get();
    final d = doc.data() as Map<String, dynamic>?;
    if (d == null || d['pendingOtp'] == null) return false;

    final pending = Map<String, dynamic>.from(d['pendingOtp']);
    if (pending['code'] == enteredCode) {
      final type = pending['type'] as String;

      final updates = <String, dynamic>{
        'pendingOtp': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp()
      };

      if (type == 'confirm') updates['status'] = 'confirmed';
      if (type == 'delivery') updates['status'] = 'delivered';

      await parcels.doc(parcelId).update(updates);

      // Fetch parcel details to get sender and receiver UIDs
      final updatedParcelDoc = await parcels.doc(parcelId).get();
      final updatedParcelData = updatedParcelDoc.data() as Map<String, dynamic>;
      final senderUid = updatedParcelData['createdByUid'] as String;
      final receiverUid = updatedParcelData['receiverUid'] as String?;
      final assignedTravelerUid = updatedParcelData['assignedTravelerUid'] as String?;
      final parcelContents = updatedParcelData['contents'] as String;


      // Store notification for traveler (who verified the OTP)
      final travelerUid = _auth.currentUser!.uid;
      final tnotif = users.doc(travelerUid).collection('notifications').doc();
      await tnotif.set({
        'id': tnotif.id,
        'parcelId': parcelId,
        'type': 'verification',
        'code': enteredCode,
        'status': 'verified',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (type == 'delivery') {
        // Notify traveler about successful delivery
        if (assignedTravelerUid != null) {
          await sendNotification(
            recipientUid: assignedTravelerUid,
            message: 'Package "$parcelContents" delivered successfully!',
            type: 'delivery_success',
            parcelId: parcelId,
          );
        }

        // Notify sender about successful delivery
        await sendNotification(
          recipientUid: senderUid,
          message: 'Your package "$parcelContents" has been delivered successfully!',
          type: 'delivery_success',
          parcelId: parcelId,
        );

        // Notify receiver about successful delivery
        if (receiverUid != null) {
          await sendNotification(
            recipientUid: receiverUid,
            message: 'Your package "$parcelContents" has been delivered successfully!',
            type: 'delivery_success',
            parcelId: parcelId,
          );
        }
      } else if (type == 'confirm') {
        // Notify sender about confirmed order
        await sendNotification(
          recipientUid: senderUid,
          message: 'Your package "$parcelContents" has been confirmed by the traveler!',
          type: 'order_confirmed',
          parcelId: parcelId,
        );

        // Notify traveler about confirmed order
        if (assignedTravelerUid != null) {
          await sendNotification(
            recipientUid: assignedTravelerUid,
            message: 'You have confirmed the order for package "$parcelContents".',
            type: 'order_confirmed',
            parcelId: parcelId,
          );
        }
      }

      return true;
    }
    return false;
  }

  Future<void> sendNotification({
    required String recipientUid,
    required String message,
    required String type,
    String? parcelId,
  }) async {
    await users.doc(recipientUid).collection('notifications').add({
      'message': message,
      'type': type,
      'parcelId': parcelId,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false, // New field to track if notification has been read
    });
  }

  /// ---------------- CHAT -----------------

  String getChatRoomId(String parcelId, String user1, String user2) {
    if (user1.hashCode <= user2.hashCode) {
      return '$parcelId\_$user1\_$user2';
    } else {
      return '$parcelId\_$user2\_$user1';
    }
  }

  Future<void> sendMessage(String chatRoomId, String text, String senderId) async {
    await _db.collection('chats').doc(chatRoomId).collection('messages').add({
      'text': text,
      'senderId': senderId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> streamMessages(String chatRoomId) {
    return _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
