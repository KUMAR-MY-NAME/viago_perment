import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String reason;
  final String reportedByUid;
  final String reportedUid;
  final String? parcelId;
  final DateTime createdAt;

  Report({
    required this.id,
    required this.reason,
    required this.reportedByUid,
    required this.reportedUid,
    this.parcelId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'reason': reason,
      'reportedByUid': reportedByUid,
      'reportedUid': reportedUid,
      'parcelId': parcelId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
