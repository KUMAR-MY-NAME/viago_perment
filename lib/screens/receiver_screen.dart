import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiverScreen extends StatefulWidget {
  const ReceiverScreen({super.key});

  @override
  State<ReceiverScreen> createState() => _ReceiverScreenState();
}

class _ReceiverScreenState extends State<ReceiverScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  bool _receiverLoggedIn = false;
  String? selectedPackageId;

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
          const SnackBar(content: Text("✅ OTP Verified, Package Delivered")),
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
      appBar: AppBar(title: const Text("Receiver")),
      body: !_receiverLoggedIn
          ? Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text("Receiver Details",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: "Receiver Name"),
                    validator: (val) => val!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: phoneController,
                    decoration:
                        const InputDecoration(labelText: "Receiver Phone"),
                    keyboardType: TextInputType.phone,
                    validator: (val) => val!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        setState(() {
                          _receiverLoggedIn = true;
                        });
                      }
                    },
                    child: const Text("View My Packages"),
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
                        .where("receiverInfo.phone",
                            isEqualTo: phoneController.text)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snapshot.data!.docs;
                      if (docs.isEmpty) {
                        return const Center(
                            child: Text("No packages assigned to this number"));
                      }

                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data = docs[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              title: Text("Package ID: ${data["packageId"]}"),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Content: ${data["packageInfo"]["content"]}"),
                                  Text("Status: ${data["status"]}"),
                                  Text(
                                      "From: ${data["destinationInfo"]["city"]}"),
                                ],
                              ),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedPackageId = data.id;
                                  });
                                },
                                child: const Text("Confirm"),
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text("Enter OTP to confirm delivery",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
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
