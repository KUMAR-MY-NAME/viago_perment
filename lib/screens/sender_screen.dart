import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/parcel.dart';
import '../services/pricing.dart';

class SenderScreen extends StatefulWidget {
  const SenderScreen({super.key});

  @override
  State<SenderScreen> createState() => _SenderScreenState();
}

class _SenderScreenState extends State<SenderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _senderName = TextEditingController();
  final _senderPhone = TextEditingController();
  DateTime? _pickupDate;
  final _contents = TextEditingController();
  final _goodsValue = TextEditingController();
  final _deadline = ValueNotifier<DateTime?>(null);
  final _pickupPin = TextEditingController();
  final _pickupCity = TextEditingController();
  final _pickupState = TextEditingController();
  final _pickupAddress = TextEditingController();
  final _destPin = TextEditingController();
  final _destCity = TextEditingController();
  final _destState = TextEditingController();
  final _destAddress = TextEditingController();
  final _receiverName = TextEditingController();
  final _receiverPhone = TextEditingController();
  final _receiverId = TextEditingController();
  final _weight = TextEditingController();
  final _len = TextEditingController();
  final _wid = TextEditingController();
  final _ht = TextEditingController();
  final _km = TextEditingController();
  bool _fragile = false;
  bool _fast = false;
  String _who = 'receiver'; // sender | receiver
  List<File> _photos = [];
  String? _receiverPhotoUrl;
  double _estimated = 0;

  Future<void> _pickDate(BuildContext ctx, bool isPickup) async {
    final now = DateTime.now();
    final res = await showDatePicker(
      context: ctx,
      firstDate: now.subtract(const Duration(days: 0)),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now,
    );
    if (res != null) {
      setState(() {
        if (isPickup)
          _pickupDate = res;
        else
          _deadline.value = res;
      });
    }
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 70);
    if (images != null) {
      setState(() {
        _photos = images.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<List<String>> _uploadPhotos(String parcelId) async {
    final storage = FirebaseStorage.instance;
    List<String> urls = [];
    for (var i = 0; i < _photos.length; i++) {
      final ref = storage.ref('parcels/$parcelId/$i.jpg');
      await ref.putFile(_photos[i]);
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  void _calcPrice() {
    final price = Pricing.estimate(
      minCharge: 99,
      baseFare: 49,
      perKm: 7.5,
      distanceKm: double.tryParse(_km.text) ?? 0,
      perKg: 12.0,
      actualWeightKg: double.tryParse(_weight.text) ?? 0,
      lCm: double.tryParse(_len.text) ?? 0,
      wCm: double.tryParse(_wid.text) ?? 0,
      hCm: double.tryParse(_ht.text) ?? 0,
      fragile: _fragile,
      fast: _fast,
    );
    setState(() => _estimated = price);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _pickupDate == null) return;
    final auth = FirebaseAuth.instance;
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    _calcPrice();

    final doc = FirebaseFirestore.instance.collection('parcels').doc();
    final now = DateTime.now();
    final parcel = Parcel(
      id: doc.id,
      createdByUid: uid,
      senderName: _senderName.text.trim(),
      senderPhone: _senderPhone.text.trim(),
      pickupDate: _pickupDate!,
      contents: _contents.text.trim(),
      goodsValue: double.tryParse(_goodsValue.text) ?? 0,
      photoUrls: [],
      deadline: _deadline.value,
      pickupPincode: _pickupPin.text.trim(),
      pickupCity: _pickupCity.text.trim(),
      pickupState: _pickupState.text.trim(),
      pickupAddress: _pickupAddress.text.trim(),
      destPincode: _destPin.text.trim(),
      destCity: _destCity.text.trim(),
      destState: _destState.text.trim(),
      destAddress: _destAddress.text.trim(),
      receiverName: _receiverName.text.trim(),
      receiverPhone: _receiverPhone.text.trim(),
      receiverId: _receiverId.text.trim(),
      receiverUid: null,
      receiverPhotoUrl: _receiverPhotoUrl,
      weightKg: double.tryParse(_weight.text) ?? 0,
      lengthCm: double.tryParse(_len.text) ?? 0,
      widthCm: double.tryParse(_wid.text) ?? 0,
      heightCm: double.tryParse(_ht.text) ?? 0,
      distanceKm: double.tryParse(_km.text) ?? 0,
      fragile: _fragile,
      fastDelivery: _fast,
      price: _estimated,
      status: 'posted',
      assignedTravelerUid: null,
      assignedTravelerName: null,
      confirmationWho: _who,
      trackedReceiverUid: null,
      pendingOtp: null,
      createdAt: now,
      updatedAt: now,
    );

    await doc.set(parcel.toMap());
    final urls = await _uploadPhotos(doc.id);
    await doc.update({'photoUrls': urls});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Parcel posted and added to your MyTrip (Sender tab)')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Parcel')),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _section('Parcel details', [
                _rowDate(
                    'Pickup date', _pickupDate, () => _pickDate(context, true)),
                _input('Parcel contents', _contents),
                _input('Value of goods (₹)', _goodsValue,
                    type: TextInputType.number),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickPhotos,
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload photos'),
                    ),
                    if (_photos.isNotEmpty) Text('${_photos.length} selected')
                  ],
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder<DateTime?>(
                  valueListenable: _deadline,
                  builder: (_, v, __) => _rowDate('Deadline for delivery', v,
                      () => _pickDate(context, false)),
                ),
              ]),
              _section('Pickup details', [
                _input('Pincode', _pickupPin, type: TextInputType.number),
                _input('City', _pickupCity),
                _input('State', _pickupState),
                _input('Full address', _pickupAddress, maxLines: 2),
              ]),
              _section('Destination details', [
                _input('Pincode', _destPin, type: TextInputType.number),
                _input('City', _destCity),
                _input('State', _destState),
                _input('Full address', _destAddress, maxLines: 2),
              ]),
              _section('Receiver details', [
                _input('Name', _receiverName),
                _input('Phone', _receiverPhone, type: TextInputType.phone),
                _input('Receiver ID (unique)', _receiverId),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final img = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);
                    if (img == null) return;
                    final f = File(img.path);
                    final ref = FirebaseStorage.instance.ref(
                        'receivers/${DateTime.now().millisecondsSinceEpoch}.jpg');
                    await ref.putFile(f);
                    _receiverPhotoUrl = await ref.getDownloadURL();
                    setState(() {});
                  },
                  icon: const Icon(Icons.upload_file),
                  label: Text(_receiverPhotoUrl == null
                      ? 'Upload Receiver Photo'
                      : 'Re-upload Receiver Photo'),
                ),
              ]),
              _section('Estimated charges', [
                _input('Weight (kg)', _weight, type: TextInputType.number),
                Row(children: [
                  Expanded(
                      child: _input('Length (cm)', _len,
                          type: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _input('Width (cm)', _wid,
                          type: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _input('Height (cm)', _ht,
                          type: TextInputType.number)),
                ]),
                _input('Distance (KM)', _km, type: TextInputType.number),
                Row(children: [
                  Checkbox(
                      value: _fragile,
                      onChanged: (v) {
                        setState(() => _fragile = v ?? false);
                        _calcPrice();
                      }),
                  const Text('Handle with care / Fragile')
                ]),
                Row(children: [
                  Checkbox(
                      value: _fast,
                      onChanged: (v) {
                        setState(() => _fast = v ?? false);
                        _calcPrice();
                      }),
                  const Text('Fast delivery (extra charges)')
                ]),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated cost:'),
                    Text('₹ ${_estimated.toStringAsFixed(2)}')
                  ],
                ),
              ]),
              _section('Confirmation', [
                const Text('Who should confirm delivery for payment release?'),
                RadioListTile(
                  value: 'receiver',
                  groupValue: _who,
                  onChanged: (v) {
                    setState(() => _who = v as String);
                  },
                  title: const Text('Receiver confirms'),
                ),
                RadioListTile(
                  value: 'sender',
                  groupValue: _who,
                  onChanged: (v) {
                    setState(() => _who = v as String);
                  },
                  title: const Text('Sender confirms'),
                ),
              ]),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Send Parcel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black12)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...children
      ]),
    );
  }

  Widget _input(String label, TextEditingController c,
      {TextInputType? type, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        onChanged: (_) => _calcPrice(),
      ),
    );
  }

  Widget _rowDate(String label, DateTime? date, VoidCallback onPick) {
    return Row(
      children: [
        Expanded(
            child: Text(date == null
                ? '$label: not set'
                : '$label: ${date.day}/${date.month}/${date.year}')),
        TextButton(onPressed: onPick, child: const Text('Pick')),
      ],
    );
  }
}
