import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String? id;
  final String? reason;
  final String? reportedByUid;
  final String? reportedUid;
  final String? parcelId;
  final DateTime? createdAt;

  Report({
    this.id,
    this.reason,
    this.reportedByUid,
    this.reportedUid,
    this.parcelId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reason': reason,
      'reportedByUid': reportedByUid,
      'reportedUid': reportedUid,
      'parcelId': parcelId,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    final created = map['createdAt'];
    DateTime? createdAt;
    if (created is Timestamp) {
      createdAt = created.toDate();
    } else if (created is DateTime) {
      createdAt = created;
    } else if (created is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(created);
    }

    return Report(
      id: map['id'] as String?,
      reason: map['reason'] as String?,
      reportedByUid: map['reportedByUid'] as String?,
      reportedUid: map['reportedUid'] as String?,
      parcelId: map['parcelId'] as String?,
      createdAt: createdAt,
    );
  }
}
