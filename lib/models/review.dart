import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final double rating; // 1-5 stars
  final String text;
  final String fromUid;
  final String toUid;
  final String parcelId;
  final String role; // 'sender' or 'traveler'
  final DateTime createdAt;

  Review({
    required this.id,
    required this.rating,
    required this.text,
    required this.fromUid,
    required this.toUid,
    required this.parcelId,
    required this.role,
    required this.createdAt,
  });

  factory Review.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      rating: (data['rating'] ?? 0).toDouble(),
      text: data['text'] ?? '',
      fromUid: data['fromUid'] ?? '',
      toUid: data['toUid'] ?? '',
      parcelId: data['parcelId'] ?? '',
      role: data['role'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rating': rating,
      'text': text,
      'fromUid': fromUid,
      'toUid': toUid,
      'parcelId': parcelId,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
