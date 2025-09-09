import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'otp_confirm_screen.dart';
import 'otp_delivery_screen.dart';

class PackageDetailScreen extends StatelessWidget {
  final String parcelId;
  final String role;
  final Map<String, dynamic> parcel;

  const PackageDetailScreen({
    super.key,
    required this.parcelId,
    required this.role,
    required this.parcel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Package #${parcel['id']}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Contents: ${parcel['contents']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Sender: ${parcel['senderName']} (${parcel['senderPhone']})'),
            Text(
                'Receiver: ${parcel['receiverName']} (${parcel['receiverPhone']})'),
            Text(
                'Pickup: ${parcel['pickupCity']} → Destination: ${parcel['destCity']}'),
            Text('Price: ₹${parcel['price']}'),
            Text('Status: ${parcel['status']}'),
            const Divider(height: 24),
            if (role == 'traveler') ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OtpConfirmScreen(parcelId: parcelId),
                    ),
                  );
                },
                child: const Text("Confirm Order (OTP from Sender)"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OtpDeliveryScreen(parcelId: parcelId),
                    ),
                  );
                },
                child: const Text("Delivery Order (OTP)"),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
