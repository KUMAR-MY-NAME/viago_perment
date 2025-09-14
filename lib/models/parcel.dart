import 'package:cloud_firestore/cloud_firestore.dart';

class Parcel {
  String id;
  String createdByUid;
  String senderName;
  String senderPhone;

  // Parcel details
  String category;
  DateTime pickupDate;
  String contents;
  double goodsValue;
  List<String> photoUrls;
  DateTime? deadline;

  // Pickup
  String pickupPincode;
  String pickupCity;
  String pickupState;
  String pickupAddress;

  // Destination
  String destPincode;
  String destCity;
  String destState;
  String destAddress;

  // Receiver
  String receiverName;
  String receiverPhone;
  String receiverId; // unique identifier given by sender (phone/email/custom)
  String? receiverUid; // optional if receiver has account
  String? receiverPhotoUrl;

  // Estimates
  double weightKg;
  double lengthCm;
  double widthCm;
  double heightCm;
  double distanceKm;
  bool fragile;
  bool fastDelivery;
  double price;

  // Workflow
    String status; // posted | selected | confirmed | in_transit | delivered | canceled
  String? assignedTravelerUid;
  String? assignedTravelerName;
  String confirmationWho; // 'sender' or 'receiver'
  String?
      trackedReceiverUid; // when receiver starts tracking (adds to receiver's MyTrip)

  // OTP helper: stores last pending otp for confirm/delivery
  Map<String, dynamic>?
      pendingOtp; // { 'type': 'confirm'|'delivery', 'code': '123456', 'toUid': 'uid' }

  String paymentStatus; // 'unpaid' | 'paid' | 'pending_on_delivery'

  double? latitude;
  double? longitude;

  String? deliveryProofUrl;

  DateTime createdAt;
  DateTime updatedAt;

  Parcel({
    required this.id,
    required this.createdByUid,
    required this.senderName,
    required this.senderPhone,
    required this.category,
    required this.pickupDate,
    required this.contents,
    required this.goodsValue,
    required this.photoUrls,
    this.deadline,
    required this.pickupPincode,
    required this.pickupCity,
    required this.pickupState,
    required this.pickupAddress,
    required this.destPincode,
    required this.destCity,
    required this.destState,
    required this.destAddress,
    required this.receiverName,
    required this.receiverPhone,
    required this.receiverId,
    this.receiverUid,
    this.receiverPhotoUrl,
    required this.weightKg,
    required this.lengthCm,
    required this.widthCm,
    required this.heightCm,
    required this.distanceKm,
    required this.fragile,
    required this.fastDelivery,
    required this.price,
    required this.status,
    this.assignedTravelerUid,
    this.assignedTravelerName,
    required this.confirmationWho,
    this.trackedReceiverUid,
    this.pendingOtp,
    required this.paymentStatus,
    this.latitude,
    this.longitude,
    this.deliveryProofUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Parcel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Parcel(
      id: doc.id,
      createdByUid: d['createdByUid'],
      senderName: d['senderName'] ?? '',
      senderPhone: d['senderPhone'] ?? '',
      category: d['category'] ?? '',
      pickupDate: (d['pickupDate'] as Timestamp).toDate(),
      contents: d['contents'] ?? '',
      goodsValue: (d['goodsValue'] ?? 0).toDouble(),
      photoUrls: List<String>.from(d['photoUrls'] ?? []),
      deadline:
          d['deadline'] != null ? (d['deadline'] as Timestamp).toDate() : null,
      pickupPincode: d['pickupPincode'] ?? '',
      pickupCity: d['pickupCity'] ?? '',
      pickupState: d['pickupState'] ?? '',
      pickupAddress: d['pickupAddress'] ?? '',
      destPincode: d['destPincode'] ?? '',
      destCity: d['destCity'] ?? '',
      destState: d['destState'] ?? '',
      destAddress: d['destAddress'] ?? '',
      receiverName: d['receiverName'] ?? '',
      receiverPhone: d['receiverPhone'] ?? '',
      receiverId: d['receiverId'] ?? '',
      receiverUid: d['receiverUid'],
      receiverPhotoUrl: d['receiverPhotoUrl'],
      weightKg: (d['weightKg'] ?? 0).toDouble(),
      lengthCm: (d['lengthCm'] ?? 0).toDouble(),
      widthCm: (d['widthCm'] ?? 0).toDouble(),
      heightCm: (d['heightCm'] ?? 0).toDouble(),
      distanceKm: (d['distanceKm'] ?? 0).toDouble(),
      fragile: d['fragile'] ?? false,
      fastDelivery: d['fastDelivery'] ?? false,
      price: (d['price'] ?? 0).toDouble(),
      status: d['status'] ?? 'posted',
      assignedTravelerUid: d['assignedTravelerUid'],
      assignedTravelerName: d['assignedTravelerName'],
      confirmationWho: d['confirmationWho'] ?? 'receiver',
      trackedReceiverUid: d['trackedReceiverUid'],
      pendingOtp: d['pendingOtp'] != null
          ? Map<String, dynamic>.from(d['pendingOtp'])
          : null,
      paymentStatus: d['paymentStatus'] ?? 'unpaid',
      latitude: (d['latitude'] ?? 0.0).toDouble(),
      longitude: (d['longitude'] ?? 0.0).toDouble(),
      deliveryProofUrl: d['deliveryProofUrl'],
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'createdByUid': createdByUid,
        'senderName': senderName,
        'senderPhone': senderPhone,
        'category': category,
        'pickupDate': Timestamp.fromDate(pickupDate),
        'contents': contents,
        'goodsValue': goodsValue,
        'photoUrls': photoUrls,
        'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
        'pickupPincode': pickupPincode,
        'pickupCity': pickupCity,
        'pickupState': pickupState,
        'pickupAddress': pickupAddress,
        'destPincode': destPincode,
        'destCity': destCity,
        'destState': destState,
        'destAddress': destAddress,
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'receiverId': receiverId,
        'receiverUid': receiverUid,
        'receiverPhotoUrl': receiverPhotoUrl,
        'weightKg': weightKg,
        'lengthCm': lengthCm,
        'widthCm': widthCm,
        'heightCm': heightCm,
        'distanceKm': distanceKm,
        'fragile': fragile,
        'fastDelivery': fastDelivery,
        'price': price,
        'status': status,
        'assignedTravelerUid': assignedTravelerUid,
        'assignedTravelerName': assignedTravelerName,
        'confirmationWho': confirmationWho,
        'trackedReceiverUid': trackedReceiverUid,
        'pendingOtp': pendingOtp,
        'paymentStatus': paymentStatus,
        'latitude': latitude,
        'longitude': longitude,
        'deliveryProofUrl': deliveryProofUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      }..removeWhere((k, v) => v == null);
  
}
