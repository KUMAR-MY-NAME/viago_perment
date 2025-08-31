import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class SenderScreen extends StatefulWidget {
  const SenderScreen({super.key});

  @override
  State<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Package details controllers
  final TextEditingController pickupDateController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final TextEditingController valueController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController dimensionController = TextEditingController();
  bool handleWithCare = false;
  bool speedDelivery = false;
  XFile? packageImage;

  // Destination details
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  // Receiver details
  final TextEditingController receiverNameController = TextEditingController();
  final TextEditingController receiverPhoneController = TextEditingController();
  XFile? receiverPhoto;

  // Confirmation option
  String confirmationChoice = "sender"; // sender or receiver

  // Pick image
  Future<void> _pickImage(bool isPackage) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isPackage) {
          packageImage = picked;
        } else {
          receiverPhoto = picked;
        }
      });
    }
  }

  // Generate OTP
  String generateOtp() {
    var rnd = Random();
    return (100000 + rnd.nextInt(899999)).toString();
  }

  // Generate Package ID
  String generatePackageId() {
    return "PKG${DateTime.now().millisecondsSinceEpoch}";
  }

  // Save to Firestore
  Future<void> _submitPackage() async {
    if (_formKey.currentState!.validate()) {
      String packageId = generatePackageId();
      String otp = generateOtp();

      await FirebaseFirestore.instance
          .collection("packages")
          .doc(packageId)
          .set({
        "packageId": packageId,
        "senderId":
            "USER123", // TODO: replace with FirebaseAuth.currentUser!.uid
        "receiverId": receiverPhoneController.text,
        "packageInfo": {
          "pickupDate": pickupDateController.text,
          "content": contentController.text,
          "value": valueController.text,
          "weight": weightController.text,
          "dimension": dimensionController.text,
          "handleWithCare": handleWithCare,
          "speedDelivery": speedDelivery,
          "packageImage": packageImage?.path ?? "",
        },
        "destinationInfo": {
          "pincode": pincodeController.text,
          "city": cityController.text,
          "state": stateController.text,
          "address": addressController.text,
        },
        "receiverInfo": {
          "name": receiverNameController.text,
          "phone": receiverPhoneController.text,
          "photo": receiverPhoto?.path ?? "",
        },
        "confirmationBy": confirmationChoice,
        "status": "pending",
        "otp": otp,
        "createdAt": DateTime.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Package request submitted successfully")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sender - Create Package")),
      body: Form(
        key: _formKey,
        child: Stepper(
          type: StepperType.vertical,
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _submitPackage();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          steps: [
            // Step 1: Package details
            Step(
              title: const Text("Package Details"),
              content: Column(
                children: [
                  TextFormField(
                    controller: pickupDateController,
                    decoration: const InputDecoration(labelText: "Pickup Date"),
                    validator: (val) => val!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: contentController,
                    decoration:
                        const InputDecoration(labelText: "Parcel Content"),
                    validator: (val) => val!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: valueController,
                    decoration:
                        const InputDecoration(labelText: "Value of Goods"),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: weightController,
                    decoration: const InputDecoration(labelText: "Weight"),
                  ),
                  TextFormField(
                    controller: dimensionController,
                    decoration: const InputDecoration(labelText: "Dimension"),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: handleWithCare,
                        onChanged: (val) =>
                            setState(() => handleWithCare = val!),
                      ),
                      const Text("Handle with Care"),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: speedDelivery,
                        onChanged: (val) =>
                            setState(() => speedDelivery = val!),
                      ),
                      const Text("Speed Delivery"),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _pickImage(true),
                    child: const Text("Upload Package Image"),
                  ),
                  if (packageImage != null)
                    Text("Image selected: ${packageImage!.name}"),
                ],
              ),
              isActive: _currentStep >= 0,
            ),

            // Step 2: Destination details
            Step(
              title: const Text("Destination Details"),
              content: Column(
                children: [
                  TextFormField(
                    controller: pincodeController,
                    decoration: const InputDecoration(labelText: "Pincode"),
                    keyboardType: TextInputType.number,
                  ),
                  TextFormField(
                    controller: cityController,
                    decoration: const InputDecoration(labelText: "City"),
                  ),
                  TextFormField(
                    controller: stateController,
                    decoration: const InputDecoration(labelText: "State"),
                  ),
                  TextFormField(
                    controller: addressController,
                    decoration:
                        const InputDecoration(labelText: "Full Address"),
                    maxLines: 2,
                  ),
                ],
              ),
              isActive: _currentStep >= 1,
            ),

            // Step 3: Receiver details
            Step(
              title: const Text("Receiver Details"),
              content: Column(
                children: [
                  TextFormField(
                    controller: receiverNameController,
                    decoration:
                        const InputDecoration(labelText: "Receiver Name"),
                  ),
                  TextFormField(
                    controller: receiverPhoneController,
                    decoration:
                        const InputDecoration(labelText: "Receiver Phone"),
                    keyboardType: TextInputType.phone,
                  ),
                  ElevatedButton(
                    onPressed: () => _pickImage(false),
                    child: const Text("Upload Receiver Photo"),
                  ),
                  if (receiverPhoto != null)
                    Text("Image selected: ${receiverPhoto!.name}"),
                ],
              ),
              isActive: _currentStep >= 2,
            ),

            // Step 4: Confirmation
            Step(
              title: const Text("Confirmation of Delivery"),
              content: Column(
                children: [
                  RadioListTile(
                    value: "sender",
                    groupValue: confirmationChoice,
                    onChanged: (val) =>
                        setState(() => confirmationChoice = val.toString()),
                    title: const Text("Sender will confirm OTP"),
                  ),
                  RadioListTile(
                    value: "receiver",
                    groupValue: confirmationChoice,
                    onChanged: (val) =>
                        setState(() => confirmationChoice = val.toString()),
                    title: const Text("Receiver will confirm OTP"),
                  ),
                ],
              ),
              isActive: _currentStep >= 3,
            ),
          ],
        ),
      ),
    );
  }
}
