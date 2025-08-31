import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class TravelerScreen extends StatefulWidget {
  const TravelerScreen({super.key});

  @override
  State<TravelerScreen> createState() => _TravelerScreenState();
}

class _TravelerScreenState extends State<TravelerScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _tripCreated = false;
  String?
      travelerId; // Replace with FirebaseAuth.currentUser!.uid if login exists

  // Traveler info
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController fromController = TextEditingController();
  final TextEditingController toController = TextEditingController();
  XFile? proofImage;

  // Selected package
  String? selectedPackageId;
  final TextEditingController otpController = TextEditingController();

  Future<void> _pickProofImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        proofImage = picked;
      });
    }
  }

  Future<void> _submitTrip() async {
    if (_formKey.currentState!.validate()) {
      travelerId = "TRAVELER_${DateTime.now().millisecondsSinceEpoch}";
      await FirebaseFirestore.instance.collection("trips").doc(travelerId).set({
        "travelerId": travelerId,
        "name": nameController.text,
        "phone": phoneController.text,
        "from": fromController.text,
        "to": toController.text,
        "proof": proofImage?.path ?? "",
        "date": DateTime.now(),
        "available": true,
      });

      setState(() => _tripCreated = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Trip created successfully")),
      );
    }
  }

  Future<void> _acceptPackage(String packageId) async {
    await FirebaseFirestore.instance
        .collection("packages")
        .doc(packageId)
        .update({
      "status": "accepted",
      "travelerId": travelerId,
    });

    setState(() {
      selectedPackageId = packageId;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Package accepted, waiting for OTP verification")),
    );
  }

  Future<void> _verifyOtp() async {
    if (selectedPackageId == null) return;

    DocumentSnapshot packageDoc = await FirebaseFirestore.instance
        .collection("packages")
        .doc(selectedPackageId)
        .get();

    if (packageDoc.exists) {
      String savedOtp = packageDoc["otp"];
      if (otpController.text == savedOtp) {
        await FirebaseFirestore.instance
            .collection("packages")
            .doc(selectedPackageId)
            .update({"status": "delivered"});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("OTP Verified ✅ Package Delivered")),
        );

        setState(() {
          selectedPackageId = null;
          otpController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Wrong OTP")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Traveler")),
      body: !_tripCreated
          ? Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text("Traveler Details",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: "Name"),
                    validator: (val) => val!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: phoneController,
                    decoration:
                        const InputDecoration(labelText: "Phone Number"),
                    keyboardType: TextInputType.phone,
                  ),
                  TextFormField(
                    controller: fromController,
                    decoration: const InputDecoration(labelText: "From Place"),
                  ),
                  TextFormField(
                    controller: toController,
                    decoration: const InputDecoration(labelText: "To Place"),
                  ),
                  ElevatedButton(
                    onPressed: _pickProofImage,
                    child: const Text("Upload Proof of Journey"),
                  ),
                  if (proofImage != null) Text("Selected: ${proofImage!.name}"),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitTrip,
                    child: const Text("Submit Trip"),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("packages")
                        .where("destinationInfo.city",
                            isEqualTo: toController.text)
                        .where("status", isEqualTo: "pending")
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());

                      final docs = snapshot.data!.docs;

                      if (docs.isEmpty) {
                        return const Center(
                            child: Text(
                                "No packages available for this destination"));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data = docs[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              title: Text("Package ID: ${data["packageId"]}"),
                              subtitle: Text(
                                  "Content: ${data["packageInfo"]["content"]}"),
                              trailing: ElevatedButton(
                                onPressed: () => _acceptPackage(data.id),
                                child: const Text("Accept"),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                if (selectedPackageId != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text("Verify OTP to confirm delivery",
                            style: TextStyle(fontSize: 16)),
                        TextField(
                          controller: otpController,
                          decoration:
                              const InputDecoration(labelText: "Enter OTP"),
                          keyboardType: TextInputType.number,
                        ),
                        ElevatedButton(
                          onPressed: _verifyOtp,
                          child: const Text("Verify OTP"),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
