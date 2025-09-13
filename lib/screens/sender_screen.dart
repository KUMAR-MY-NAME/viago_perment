import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    _weight.addListener(_calcPrice);
    _len.addListener(_calcPrice);
    _wid.addListener(_calcPrice);
    _ht.addListener(_calcPrice);
    _km.addListener(_calcPrice);
    _goodsValue.addListener(_calcPrice);
  }

  @override
  void dispose() {
    _weight.removeListener(_calcPrice);
    _len.removeListener(_calcPrice);
    _wid.removeListener(_calcPrice);
    _ht.removeListener(_calcPrice);
    _km.removeListener(_calcPrice);
    _goodsValue.removeListener(_calcPrice);
    _senderName.dispose();
    _senderPhone.dispose();
    _contents.dispose();
    _goodsValue.dispose();
    _pickupPin.dispose();
    _pickupCity.dispose();
    _pickupState.dispose();
    _pickupAddress.dispose();
    _destPin.dispose();
    _destCity.dispose();
    _destState.dispose();
    _destAddress.dispose();
    _receiverName.dispose();
    _receiverPhone.dispose();
    _receiverId.dispose();
    _weight.dispose();
    _len.dispose();
    _wid.dispose();
    _ht.dispose();
    _km.dispose();
    super.dispose();
  }

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
        if (isPickup) {
          _pickupDate = res;
        } else {
          _deadline.value = res;
        }
      });
    }
  }

  Future<void> _pickPhotos(bool isReceiverPhoto) async {
    final picker = ImagePicker();
    if (isReceiverPhoto) {
      final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (img != null) {
        final f = File(img.path);
        final ref = FirebaseStorage.instance.ref(
            'receivers/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await ref.putFile(f);
        _receiverPhotoUrl = await ref.getDownloadURL();
        setState(() {});
      }
    } else {
      final images = await picker.pickMultiImage(imageQuality: 70);
      if (images.isNotEmpty) {
        setState(() {
          _photos = images.map((e) => File(e.path)).toList();
        });
      }
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
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'Send Parcel',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: const Color(0xFF514CA1),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              _buildCard(
                title: 'Parcel details:',
                children: [
                  _buildDateField('Pickup date:', _pickupDate, () => _pickDate(context, true)),
                  _buildTextField('Parcel contents:', _contents, hint: 'items'),
                  _buildTextField('Value of Goods:', _goodsValue, hint: '₹', type: TextInputType.number),
                  _buildUploadField('Upload the parcel photos:', () => _pickPhotos(false)),
                  ValueListenableBuilder<DateTime?>(
                    valueListenable: _deadline,
                    builder: (_, v, __) => _buildDateField('Deadline for the delivery:', v, () => _pickDate(context, false)),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildCard(
                title: 'Pickup details:',
                children: [
                  _buildTextField('Pincode:', _pickupPin, hint: 'Enter the pincode', type: TextInputType.number),
                  _buildTextField('City:', _pickupCity, hint: 'City name'),
                  _buildTextField('State:', _pickupState, hint: 'State name'),
                  _buildTextField('Full Address:', _pickupAddress, hint: 'Enter the full address', maxLines: 3),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildCard(
                title: 'Destination details:',
                children: [
                  _buildTextField('Pincode:', _destPin, hint: 'Enter the pincode', type: TextInputType.number),
                  _buildTextField('City:', _destCity, hint: 'City name'),
                  _buildTextField('State:', _destState, hint: 'State name'),
                  _buildTextField('Full Address:', _destAddress, hint: 'Enter the full address', maxLines: 3),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildCard(
                title: 'Receiver details:',
                children: [
                  _buildTextField('Name:', _receiverName, hint: 'Receiver name'),
                  _buildTextField('Phone No:', _receiverPhone, hint: '+91 xxxxxxxxxx', type: TextInputType.phone),
                  _buildTextField('Receiver ID:', _receiverId, hint: 'Unique ID'),
                  _buildUploadField('Upload photo of receiver:', () => _pickPhotos(true)),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildCard(
                title: 'Estimated charges:',
                children: [
                  _buildTextField('Weight:', _weight, hint: 'in Kgs', type: TextInputType.number),
                  _buildDimensionsRow(_len, _wid, _ht, 'L x W x H'),
                  _buildTextField('KMs:', _km, hint: 'Distance', type: TextInputType.number),
                  // New layout for optional checkboxes
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Optional:', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                        _buildCheckbox('Handle with care/fragile contents', _fragile, (v) {
                          setState(() => _fragile = v ?? false);
                          _calcPrice();
                        }),
                        _buildCheckbox('Fast delivery (extra charges)', _fast, (v) {
                          setState(() => _fast = v ?? false);
                          _calcPrice();
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Estimated cost:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      Text('₹ ${_estimated.toStringAsFixed(2)} approx.', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildCard(
                title: 'Confirmation:',
                children: [
                  Text('Who should confirm delivery for payment on receipt:', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  _buildRadio('Receiver confirms', 'receiver'),
                  _buildRadio('Sender confirms', 'sender'),
                  const SizedBox(height: 8.0),
                  Text('This ensures secure transactions and avoids disputes.', style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 24.0),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF514CA1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onPressed: _submit,
                  child: Text('Send Parcel', style: GoogleFonts.poppins(fontSize: 18.0)),
                ),
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF514CA1),
              ),
            ),
            const Divider(color: Color(0xFF514CA1)),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {String? hint, int maxLines = 1, TextInputType? type}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: type,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Color(0xFF514CA1), width: 2.0),
              ),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionsRow(TextEditingController len, TextEditingController wid, TextEditingController ht, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text('Dimensions:', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ),
          TextFormField(
            controller: len,
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Color(0xFF514CA1), width: 2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onPick) {
    final formattedDate = date != null ? DateFormat('dd/MM/yyyy').format(date) : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ),
          GestureDetector(
            onTap: onPick,
            child: AbsorbPointer(
              child: TextFormField(
                controller: TextEditingController(text: formattedDate),
                style: GoogleFonts.poppins(),
                decoration: InputDecoration(
                  hintText: 'DD/MM/YYYY',
                  hintStyle: GoogleFonts.poppins(),
                  suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF514CA1)),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(color: Color(0xFF514CA1), width: 2.0),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadField(String label, VoidCallback onUpload) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file),
              label: Text('Upload', style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF514CA1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(String text, bool value, ValueChanged<bool?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF514CA1),
          ),
          Flexible(child: Text(text, style: GoogleFonts.poppins())),
        ],
      ),
    );
  }

  Widget _buildRadio(String text, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: _who,
            onChanged: (v) {
              setState(() => _who = v as String);
            },
            activeColor: const Color(0xFF514CA1),
          ),
          Text(text, style: GoogleFonts.poppins()),
        ],
      ),
    );
  }
}
