import 'package:cloud_firestore/cloud_firestore.dart';

class Traveler {
  String id; // same as uid
  String travelerUid;
  String travelerName;
  String fromCity;
  String toCity;
  DateTime travelDate;
  String mode; // vehicle | bus | train | flight
  double capacityKg;
  DateTime createdAt;

  Traveler({
    required this.id,
    required this.travelerUid,
    required this.travelerName,
    required this.fromCity,
    required this.toCity,
    required this.travelDate,
    required this.mode,
    required this.capacityKg,
    required this.createdAt,
  });

  factory Traveler.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Traveler(
      id: doc.id,
      travelerUid: d['travelerUid'],
      travelerName: d['travelerName'] ?? '',
      fromCity: d['fromCity'] ?? '',
      toCity: d['toCity'] ?? '',
      travelDate: (d['travelDate'] as Timestamp).toDate(),
      mode: d['mode'] ?? 'vehicle',
      capacityKg: (d['capacityKg'] ?? 0).toDouble(),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'travelerUid': travelerUid,
        'travelerName': travelerName,
        'fromCity': fromCity,
        'toCity': toCity,
        'travelDate': Timestamp.fromDate(travelDate),
        'mode': mode,
        'capacityKg': capacityKg,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
