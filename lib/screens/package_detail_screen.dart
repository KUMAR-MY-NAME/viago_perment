import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:packmate/screens/chat_screen.dart';
import 'package:packmate/services/firestore_service.dart';
import 'package:packmate/services/storage_service.dart';
import 'package:packmate/services/pricing.dart'; // Added
import 'package:packmate/services/wallet_service.dart'; // Added
import 'otp_confirm_screen.dart';
import 'otp_delivery_screen.dart';
import 'package:packmate/screens/receiver_payment_screen.dart'; // Added
import 'package:packmate/widgets/parcel_status_bar.dart'; // Added

import 'package:flutter_sound/flutter_sound.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:packmate/models/report.dart';
import 'package:packmate/screens/leave_review_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for FirebaseAuth.instance.currentUser
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_storage/firebase_storage.dart'; // ✅ Added import

class PackageDetailScreen extends StatefulWidget {
  final String parcelId;
  final String role;

  const PackageDetailScreen({
    super.key,
    required this.parcelId,
    required this.role,
  });

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  late final WalletService _walletService; // Initialized here

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _filePath;

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _initPlayer();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _walletService = WalletService(currentUser.uid);
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    await _recorder.openRecorder();
  }

  Future<void> _initPlayer() async {
    await _player.openPlayer();
  }

  Future<void> _startRecording() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    final tempDir = await getTemporaryDirectory();
    _filePath = '${tempDir.path}/flutter_sound.aac';
    await _recorder.startRecorder(toFile: _filePath);
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    _uploadVoiceNote();
  }

  Future<void> _uploadVoiceNote() async {
    if (_filePath == null) return;
    final downloadUrl =
        await _storageService.uploadVoiceNote(_filePath!, widget.parcelId);
    await _firestoreService
        .updateParcel(widget.parcelId, {'voiceNoteUrl': downloadUrl});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice note uploaded!')),
    );
  }

  Future<void> _playVoiceNote(Map<String, dynamic> parcel) async {
    if (parcel['voiceNoteUrl'] == null) return;
    await _player.startPlayer(
      fromURI: parcel['voiceNoteUrl'],
      whenFinished: () {
        setState(() {
          _isPlaying = false;
        });
      },
    );
    setState(() {
      _isPlaying = true;
    });
  }

  Future<void> _stopPlaying() async {
    await _player.stopPlayer();
    setState(() {
      _isPlaying = false;
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone call to $phoneNumber')),
      );
    }
  }

  void _chatWith(String otherUserId, String otherUserName) {
    final currentUserId = _firestoreService.uid;
    final chatRoomId = _firestoreService.getChatRoomId(
        widget.parcelId, currentUserId, otherUserId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatRoomId: chatRoomId,
          recipientName: otherUserName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Package #${widget.parcelId}")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parcels')
            .doc(widget.parcelId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final parcel = snapshot.data!.data() as Map<String, dynamic>;

          final isSender = widget.role == 'sender';
          final isTraveler = widget.role == 'traveler';
          final isReceiver = widget.role == 'receiver';

          final senderId = parcel['createdByUid'];
          final travelerId = parcel['assignedTravelerUid'];
          final receiverId = parcel['receiverUid'];

          final senderName = parcel['senderName'] ?? 'Sender';
          final travelerName = parcel['assignedTravelerName'] ?? 'Traveler';
          final receiverName = parcel['receiverName'] ?? 'Receiver';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(
                  'Contents: ${parcel['contents']}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sender: $senderName (${parcel['senderPhone']})'),
                    if (isTraveler || isReceiver)
                      IconButton(
                        icon: const Icon(Icons.phone),
                        onPressed: () => _makePhoneCall(parcel['senderPhone']),
                      ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        'Receiver: $receiverName (${parcel['receiverPhone']})'),
                    if (isSender || isTraveler)
                      IconButton(
                        icon: const Icon(Icons.phone),
                        onPressed: () =>
                            _makePhoneCall(parcel['receiverPhone']),
                      ),
                  ],
                ),
                if (travelerId != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'Traveler: $travelerName (${parcel['assignedTravelerPhone'] ?? ''})'),
                      if ((isSender || isReceiver) &&
                          parcel['assignedTravelerPhone'] != null)
                        IconButton(
                          icon: const Icon(Icons.phone),
                          onPressed: () =>
                              _makePhoneCall(parcel['assignedTravelerPhone']),
                        ),
                    ],
                  ),
                Text(
                    'Pickup: ${parcel['pickupCity']} → Destination: ${parcel['destCity']}'),
                Text('Price: ₹${parcel['price']}'),
                Text('Status: ${parcel['status']}'),
                const Divider(height: 24),

                // Parcel Status Bar
                ParcelStatusBar(currentStatus: parcel['status']),
                const Divider(height: 24),

                // Map View
                // --- Replace the existing FlutterMap / MarkerLayer block with this ---
                if ((isSender || isReceiver) &&
                    parcel['latitude'] != null &&
                    parcel['longitude'] != null)
                  SizedBox(
                    height: 200,
                    child: FlutterMap(
                      options: MapOptions(
                        center: LatLng(
                          (parcel['latitude'] ?? 0).toDouble(),
                          (parcel['longitude'] ?? 0).toDouble(),
                        ),
                        zoom: 15.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                          subdomains: const ['a', 'b', 'c'],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 80.0,
                              height: 80.0,
                              point: LatLng(
                                (parcel['latitude'] ?? 0).toDouble(),
                                (parcel['longitude'] ?? 0).toDouble(),
                              ),
                              // use `child` (not `builder`) for recent flutter_map versions
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                // Voice Note UI
                if (isSender) _buildVoiceNoteRecorder(),
                if (isTraveler && parcel['voiceNoteUrl'] != null)
                  _buildVoiceNotePlayer(parcel),

                // Delivery Proof
                if (isTraveler && parcel['status'] == 'in_transit')
                  _buildDeliveryProofUploader(parcel),
                if (parcel['deliveryProofUrl'] != null)
                  _buildDeliveryProofViewer(parcel),

                // Communications
                const Text('Communications',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (isSender && travelerId != null)
                  ElevatedButton(
                    onPressed: () => _chatWith(travelerId, travelerName),
                    child: const Text('Chat with Traveler'),
                  ),
                if (isTraveler) ...[
                  ElevatedButton(
                    onPressed: () => _chatWith(senderId, senderName),
                    child: const Text('Chat with Sender'),
                  ),
                  ElevatedButton(
                    onPressed: receiverId != null
                        ? () => _chatWith(receiverId, receiverName)
                        : null,
                    child: const Text('Chat with Receiver'),
                  ),
                ],
                if (isReceiver && travelerId != null)
                  ElevatedButton(
                    onPressed: () => _chatWith(travelerId, travelerName),
                    child: const Text('Chat with Traveler'),
                  ),

                const Divider(height: 24),

                // Review Button
                _buildReviewButton(context, parcel),

                const SizedBox(height: 16),

                // Report Buttons
                _buildReportButtons(context, parcel),

                const SizedBox(height: 16),

                // Block Buttons
                _buildBlockButtons(context, parcel),

                const SizedBox(height: 16),

                // Cancel Button
                _buildCancelButton(context, parcel),

                if (widget.role == 'traveler') ...[
                  // Show "Confirm Order" button ONLY when the parcel is 'selected'
                  if (parcel['status'] == 'selected')
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                OtpConfirmScreen(parcelId: widget.parcelId),
                          ),
                        );
                      },
                      child: const Text("Confirm Order (OTP from Sender)"),
                    ),

                  // Show "Request Payment" button ONLY when parcel is 'in_transit' AND payment is 'pending_on_delivery'
                  if (parcel['status'] == 'in_transit' &&
                      parcel['paymentStatus'] == 'pending_on_delivery')
                    ElevatedButton(
                      onPressed: () async {
                        await _firestoreService.updateParcel(widget.parcelId, {
                          'status': 'awaiting_receiver_payment',
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Payment request sent to the receiver.')),
                        );
                      },
                      child: const Text("Request Payment from Receiver"),
                    ),

                  // Show "Waiting for Receiver to Pay" ONLY when status is 'awaiting_receiver_payment'
                  if (parcel['status'] == 'awaiting_receiver_payment')
                    const ElevatedButton(
                      onPressed: null,
                      child: Text("Waiting for Receiver to Pay"),
                    ),

                  // Show "Send OTP for Delivery" ONLY when parcel is 'in_transit' AND payment is 'paid'
                  if (parcel['status'] == 'in_transit' &&
                      parcel['paymentStatus'] == 'paid')
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                OtpDeliveryScreen(parcelId: widget.parcelId),
                          ),
                        );
                      },
                      child: const Text("Proceed to Delivery OTP"),
                    ),
                ],

                // Receiver's Payment Button
                if (widget.role == 'receiver' &&
                    parcel['status'] == 'awaiting_receiver_payment')
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReceiverPaymentScreen(
                            parcelId: widget.parcelId,
                            receiverUid: parcel['receiverUid'],
                            senderUid: parcel['createdByUid'],
                            amount: (parcel['price'] ?? 0.0).toDouble(),
                          ),
                        ),
                      );
                    },
                    child: const Text("Pending Payment: Pay Now"),
                  ),

                // Button for Sender/Receiver to request OTP to their own device
                if ((isSender && parcel['confirmationWho'] == 'sender') ||
                    (isReceiver && parcel['confirmationWho'] == 'receiver'))
                  ElevatedButton(
                    onPressed: () => _getDeliveryOtp(parcel),
                    child: const Text("Get Delivery OTP"),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _getDeliveryOtp(Map<String, dynamic> parcel) async {
    try {
      final who = parcel['confirmationWho'];
      final targetUid = who == 'sender'
          ? parcel['createdByUid']
          : parcel['receiverUid'];

      if (targetUid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Confirmation user not found.')),
        );
        return;
      }
      
      // Ensure the current user is the one who should be getting the OTP
      if (FirebaseAuth.instance.currentUser?.uid != targetUid) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: You are not authorized to request this OTP.')),
        );
        return;
      }

      await _firestoreService.createAndSendOtp(
        parcelId: widget.parcelId,
        type: 'delivery',
        targetUid: targetUid,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'OTP sent to your notifications. Share it with the traveler.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get OTP: $e')),
      );
    }
  }

  Widget _buildVoiceNoteRecorder() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isRecording ? _stopRecording : _startRecording,
          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
          label: Text(_isRecording ? 'Stop Recording' : 'Record Voice Note'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isRecording ? Colors.red : null,
          ),
        ),
        if (_isRecording)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Recording...'),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildVoiceNotePlayer(Map<String, dynamic> parcel) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isPlaying ? _stopPlaying : () => _playVoiceNote(parcel),
          icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow),
          label: const Text('Play Voice Note'),
        ),
        if (_isPlaying)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Playing...'),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDeliveryProofUploader(Map<String, dynamic> parcel) {
    return ElevatedButton.icon(
      onPressed: () => _uploadDeliveryProof(parcel),
      icon: const Icon(Icons.camera_alt),
      label: const Text('Upload Delivery Proof'),
    );
  }

  Widget _buildDeliveryProofViewer(Map<String, dynamic> parcel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Delivery Proof:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Image.network(parcel['deliveryProofUrl']),
      ],
    );
  }

  Future<void> _uploadDeliveryProof(Map<String, dynamic> parcel) async {
    final picker = ImagePicker();
    final img =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (img != null) {
      final f = File(img.path);
      final ref = FirebaseStorage.instance
          .ref('delivery_proofs/${widget.parcelId}.jpg');
      await ref.putFile(f);
      final url = await ref.getDownloadURL();
      await _firestoreService
          .updateParcel(widget.parcelId, {'deliveryProofUrl': url});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery proof uploaded!')),
      );
    }
  }

  Widget _buildReviewButton(BuildContext context, Map<String, dynamic> parcel) {
    final role = widget.role;
    final currentUserUid = _firestoreService.uid;
    final isDelivered = parcel['status'] == 'delivered';

    if (!isDelivered) {
      return const SizedBox.shrink();
    }

    final reviewsGiven = parcel['reviewsGiven'] as Map<String, dynamic>? ?? {};
    final hasUserReviewed = reviewsGiven[currentUserUid] == true;

    if (hasUserReviewed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('You have already reviewed this delivery.',
            style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }

    String? toUid;
    String toRole = '';
    if (role == 'sender') {
      toUid = parcel['assignedTravelerUid'];
      toRole = 'traveler';
    } else if (role == 'traveler') {
      toUid = parcel['createdByUid'];
      toRole = 'sender';
    }

    if (toUid == null) {
      return const SizedBox.shrink();
    }

    return ElevatedButton.icon(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeaveReviewScreen(
              parcelId: widget.parcelId,
              fromUid: currentUserUid,
              toUid: toUid!,
              role: role,
            ),
          ),
        );
      },
      icon: const Icon(Icons.star),
      label: Text('Rate and Review $toRole'),
    );
  }

  void _showReportDialog(String reportedUid) {
    final reportController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Report User'),
          content: TextFormField(
            controller: reportController,
            decoration:
                const InputDecoration(hintText: 'Reason for reporting...'),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (reportController.text.trim().isEmpty) {
                  return;
                }
                final reportRef =
                    FirebaseFirestore.instance.collection('reports').doc();
                final report = Report(
                  id: reportRef.id,
                  reason: reportController.text.trim(),
                  reportedByUid: _firestoreService.uid,
                  reportedUid: reportedUid,
                  parcelId: widget.parcelId,
                  createdAt: DateTime.now(),
                );
                await reportRef.set(report.toMap());
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report submitted.')),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReportButtons(
      BuildContext context, Map<String, dynamic> parcel) {
    final role = widget.role;
    List<Widget> buttons = [];

    if (role == 'sender') {
      final travelerUid = parcel['assignedTravelerUid'];
      if (travelerUid != null) {
        buttons.add(
          ElevatedButton(
            onPressed: () => _showReportDialog(travelerUid),
            child: const Text('Report Traveler'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        );
      }
    } else if (role == 'traveler') {
      final senderUid = parcel['createdByUid'];
      final receiverUid = parcel['receiverUid'];
      buttons.add(
        ElevatedButton(
          onPressed: () => _showReportDialog(senderUid),
          child: const Text('Report Sender'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
      );
      if (receiverUid != null) {
        buttons.add(
          ElevatedButton(
            onPressed: () => _showReportDialog(receiverUid),
            child: const Text('Report Receiver'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        );
      }
    } else if (role == 'receiver') {
      final travelerUid = parcel['assignedTravelerUid'];
      if (travelerUid != null) {
        buttons.add(
          ElevatedButton(
            onPressed: () => _showReportDialog(travelerUid),
            child: const Text('Report Traveler'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        );
      }
    }

    return Column(children: buttons);
  }

  void _showBlockDialog(String blockedUid, String blockedUserName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Block $blockedUserName?'),
          content: const Text(
              'They will not be able to see your packages, and you will not see theirs.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentUserUid = _firestoreService.uid;
                final profileRef = FirebaseFirestore.instance
                    .collection('profiles')
                    .doc(currentUserUid);
                await profileRef.update({
                  'blockedUsers': FieldValue.arrayUnion([blockedUid])
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$blockedUserName has been blocked.')),
                );
              },
              child: const Text('Block'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBlockButtons(BuildContext context, Map<String, dynamic> parcel) {
    final role = widget.role;
    List<Widget> buttons = [];

    if (role == 'sender') {
      final travelerUid = parcel['assignedTravelerUid'];
      final travelerName = parcel['assignedTravelerName'] ?? 'Traveler';
      if (travelerUid != null) {
        buttons.add(
          ElevatedButton(
            onPressed: () => _showBlockDialog(travelerUid, travelerName),
            child: const Text('Block Traveler'),
          ),
        );
      }
    } else if (role == 'traveler') {
      final senderUid = parcel['createdByUid'];
      final senderName = parcel['senderName'] ?? 'Sender';
      buttons.add(
        ElevatedButton(
          onPressed: () => _showBlockDialog(senderUid, senderName),
          child: const Text('Block Sender'),
        ),
      );
    }

    return Column(children: buttons);
  }

  Widget _buildCancelButton(BuildContext context, Map<String, dynamic> parcel) {
    final isSender = widget.role == 'sender';
    final isCancellable =
        parcel['status'] != 'delivered' && parcel['status'] != 'canceled';

    if (!isSender || !isCancellable) {
      return const SizedBox.shrink();
    }

    return ElevatedButton(
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancel Parcel?'),
            content: const Text(
                'Are you sure you want to cancel this parcel? This action cannot be undone.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No')),
              ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes, Cancel')),
            ],
          ),
        );

        if (confirm == true) {
          // Update parcel status to canceled
          await FirebaseFirestore.instance
              .collection('parcels')
              .doc(widget.parcelId)
              .update({
            'status': 'canceled',
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Check if payment was already processed and refund
          // Assuming payment is processed when status becomes 'confirmed' or 'selected'
          final packagePrice = (parcel['price'] ?? 0.0).toDouble();
          final senderUid = parcel['createdByUid'];

          if (parcel['status'] == 'confirmed' ||
              parcel['status'] == 'selected') {
            await _walletService.refundMoney(
                senderUid, packagePrice, widget.parcelId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Parcel canceled and ₹${packagePrice.toStringAsFixed(2)} refunded to your wallet.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Parcel canceled.')),
            );
          }
          Navigator.of(context).pop(); // Pop PackageDetailScreen
        }
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
      child: const Text('Cancel Parcel'),
    );
  }
}
