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
import 'package:packmate/services/wallet_service.dart'; // Added
import 'package:packmate/services/firestore_service.dart'; // Added for notifications

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
  String? _category;
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

  String _paymentOption = 'pay_on_delivery'; // 'pay_now' | 'pay_on_delivery'
  String _payNowMethod =
      'wallet'; // 'wallet' | 'phonepe' | 'googlepay' | 'paytm'
  bool _isProcessingPayment = false;

  // Make wallet service nullable to avoid late init runtime problems if user is null
  WalletService? _walletService;

  @override
  void initState() {
    super.initState();
    _weight.addListener(_calcPrice);
    _len.addListener(_calcPrice);
    _wid.addListener(_calcPrice);
    _ht.addListener(_calcPrice);
    _km.addListener(_calcPrice);
    _goodsValue.addListener(_calcPrice);

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _walletService = WalletService(currentUser.uid);
    }
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
    _deadline.dispose();
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
      final img =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (img != null) {
        final f = File(img.path);
        final ref = FirebaseStorage.instance
            .ref('receivers/${DateTime.now().millisecondsSinceEpoch}.jpg');
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

  void _resetForm() {
    _formKey.currentState?.reset();
    _senderName.clear();
    _senderPhone.clear();
    _contents.clear();
    _goodsValue.clear();
    _pickupPin.clear();
    _pickupCity.clear();
    _pickupState.clear();
    _pickupAddress.clear();
    _destPin.clear();
    _destCity.clear();
    _destState.clear();
    _destAddress.clear();
    _receiverName.clear();
    _receiverPhone.clear();
    _receiverId.clear();
    _weight.clear();
    _len.clear();
    _wid.clear();
    _ht.clear();
    _km.clear();
    setState(() {
      _pickupDate = null;
      _category = null;
      _fragile = false;
      _fast = false;
      _photos = [];
      _receiverPhotoUrl = null;
      _estimated = 0;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _pickupDate == null) return;
    final auth = FirebaseAuth.instance;
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    _calcPrice();

    String finalPaymentStatus = 'unpaid'; // Default

    if (_paymentOption == 'pay_now') {
      setState(() => _isProcessingPayment = true);
      bool paymentSuccess = false;

      if (_payNowMethod == 'wallet') {
        // Ensure wallet service exists
        if (_walletService == null) {
          setState(() => _isProcessingPayment = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Wallet not available. Please log in or choose another payment method.')),
          );
          return;
        }

        // _walletService.addMoney may return void or bool; handle both by try/catch.
        try {
          // Attempt to call; if it returns Future<bool> you could capture it, but if it's Future<void> we just await
          final result = _walletService!.addMoney(-_estimated);
          if (result is Future<bool>) {
            final bool res = await result;
            paymentSuccess = res;
          } else {
            // assume Future<void>
            await result;
            paymentSuccess = true;
          }
        } catch (e) {
          paymentSuccess = false;
        }
      } else {
        // Simulate external payment success
        await Future.delayed(const Duration(seconds: 2));
        paymentSuccess = true;
      }

      if (!mounted) return;
      setState(() => _isProcessingPayment = false);

      if (!paymentSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Payment failed. Please try again or choose another method.')),
        );
        return;
      }
      finalPaymentStatus = 'paid';
    } else {
      finalPaymentStatus = 'pending_on_delivery';
    }

    final doc = FirebaseFirestore.instance.collection('parcels').doc();
    final now = DateTime.now();
    final parcel = Parcel(
      id: doc.id,
      createdByUid: uid,
      senderName: _senderName.text.trim(),
      senderPhone: _senderPhone.text.trim(),
      category: _category!,
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
      paymentStatus: finalPaymentStatus, // Set payment status here
      createdAt: now,
      updatedAt: now,
    );

    await doc.set(parcel.toMap());
    final urls = await _uploadPhotos(doc.id);
    await doc.update({'photoUrls': urls});

    // Notify travelers about new package on their route
    final matchingTrips = await FirebaseFirestore.instance
        .collection('trips')
        .where('fromCity', isEqualTo: _pickupCity.text.trim())
        .where('toCity', isEqualTo: _destCity.text.trim())
        .get();

    for (var tripDoc in matchingTrips.docs) {
      final travelerUid = tripDoc.id; // trip doc ID is the traveler UID
      await FirestoreService().sendNotification(
        recipientUid: travelerUid,
        message: 'New package available on your route from ${_pickupCity.text.trim()} to ${_destCity.text.trim()}!',
        type: 'new_package',
        parcelId: doc.id,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Parcel posted and added to your MyTrip (Sender tab)')),
      );
      _showCreateAnotherParcelDialog();
    }
  }

  Future<void> _showCreateAnotherParcelDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Parcel Created'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Would you like to create another parcel?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _resetForm();
              },
            ),
          ],
        );
      },
    );
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
                title: 'Sender details:',
                children: [
                  _buildTextField('Name:', _senderName, hint: 'Sender name'),
                  _buildTextField('Phone No:', _senderPhone,
                      hint: '+91 xxxxxxxxxx', type: TextInputType.phone),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildCard(
                title: 'Parcel details:',
                children: [
                  _buildDropdownField('Category:', [
                    'documents',
                    'electronics',
                    'food',
                    'fragile items'
                  ]),
                  _buildDateField('Pickup date:', _pickupDate,
                      () => _pickDate(context, true)),
                  _buildTextField('Parcel contents:', _contents, hint: 'items'),
                  _buildTextField('Value of Goods:', _goodsValue,
                      hint: '₹', type: TextInputType.number),
                  _buildUploadField(
                      'Upload the parcel photos:', () => _pickPhotos(false)),
                  ValueListenableBuilder<DateTime?>(
                    valueListenable: _deadline,
                    builder: (_, v, __) => _buildDateField(
                        'Deadline for the delivery:',
                        v,
                        () => _pickDate(context, false)),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildCard(
                title: 'Pickup details:',
                children: [
                  _buildTextField('Pincode:', _pickupPin,
                      hint: 'Enter the pincode', type: TextInputType.number),
                  _buildTextField('City:', _pickupCity, hint: 'City name'),
                  _buildTextField('State:', _pickupState, hint: 'State name'),
                  _buildTextField('Full Address:', _pickupAddress,
                      hint: 'Enter the full address', maxLines: 3),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildCard(
                title: 'Destination details:',
                children: [
                  _buildTextField('Pincode:', _destPin,
                      hint: 'Enter the pincode', type: TextInputType.number),
                  _buildTextField('City:', _destCity, hint: 'City name'),
                  _buildTextField('State:', _destState, hint: 'State name'),
                  _buildTextField('Full Address:', _destAddress,
                      hint: 'Enter the full address', maxLines: 3),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildCard(
                title: 'Receiver details:',
                children: [
                  _buildTextField('Name:', _receiverName,
                      hint: 'Receiver name'),
                  _buildTextField('Phone No:', _receiverPhone,
                      hint: '+91 xxxxxxxxxx', type: TextInputType.phone),
                  _buildTextField('Receiver ID:', _receiverId,
                      hint: 'Unique ID'),
                  _buildUploadField(
                      'Upload photo of receiver:', () => _pickPhotos(true)),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildCard(
                title: 'Estimated charges:',
                children: [
                  _buildTextField('Weight:', _weight,
                      hint: 'in Kgs', type: TextInputType.number),
                  _buildDimensionsRow(_len, _wid, _ht, 'L x W x H'),
                  _buildTextField('KMs:', _km,
                      hint: 'Distance', type: TextInputType.number),
                  // New layout for optional checkboxes
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Optional:',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500)),
                        _buildCheckbox(
                            'Handle with care/fragile contents', _fragile, (v) {
                          setState(() => _fragile = v ?? false);
                          _calcPrice();
                        }),
                        _buildCheckbox('Fast delivery (extra charges)', _fast,
                            (v) {
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
                      Text('Estimated cost:',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      Text('₹ ${_estimated.toStringAsFixed(2)} approx.',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildCard(
                title: 'Confirmation:',
                children: [
                  Text('Who should confirm delivery for payment on receipt:',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  _buildRadio<String>('Receiver confirms', 'receiver', _who,
                      (value) {
                    setState(() => _who = value!);
                  }),
                  _buildRadio<String>('Sender confirms', 'sender', _who,
                      (value) {
                    setState(() => _who = value!);
                  }),
                  const SizedBox(height: 8.0),
                  Text('This ensures secure transactions and avoids disputes.',
                      style: GoogleFonts.poppins(
                          color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 16.0),
              _buildPaymentSection(),
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
                  child: Text('Send Parcel',
                      style: GoogleFonts.poppins(fontSize: 18.0)),
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
            child: Text(label,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide:
                    const BorderSide(color: Color(0xFF514CA1), width: 2.0),
              ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionsRow(TextEditingController len,
      TextEditingController wid, TextEditingController ht, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text('Dimensions:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ),
          TextFormField(
            controller: len,
            keyboardType: TextInputType.number,
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide:
                    const BorderSide(color: Color(0xFF514CA1), width: 2.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
          ),
          DropdownButtonFormField<String>(
            isExpanded: true,
            value: _category,
            hint: Text('Select Category', style: GoogleFonts.poppins(color: Colors.grey)),
            style: GoogleFonts.poppins(color: Colors.black87),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(color: Color(0xFF514CA1), width: 2.0),
              ),
            ),
            items: items.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: GoogleFonts.poppins()),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() => _category = newValue);
              }
            },
            validator: (v) => v == null ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onPick) {
    final formattedDate =
        date != null ? DateFormat('dd/MM/yyyy').format(date) : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(label,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
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
                  suffixIcon: const Icon(Icons.calendar_today,
                      color: Color(0xFF514CA1)),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey[400]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide:
                        const BorderSide(color: Color(0xFF514CA1), width: 2.0),
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
            child: Text(label,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
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

  Widget _buildCheckbox(
      String text, bool value, ValueChanged<bool?> onChanged) {
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

  Widget _buildRadio<T>(
      String text, T value, T groupValue, ValueChanged<T?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Radio<T>(
            value: value,
            groupValue: groupValue,
            onChanged: onChanged,
            activeColor: const Color(0xFF514CA1),
          ),
          Text(text, style: GoogleFonts.poppins()),
        ],
      ),
    );
  }

  Widget _buildPaymentSection() {
    return _buildCard(
      title: 'Payment Options:',
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRadio<String>('Pay Now', 'pay_now', _paymentOption, (value) {
              setState(() => _paymentOption = value!);
            }),
            _buildRadio<String>(
                'Pay on Delivery', 'pay_on_delivery', _paymentOption, (value) {
              setState(() => _paymentOption = value!);
            }),
          ],
        ),
        if (_paymentOption == 'pay_now')
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // show processing indicator if processing
                if (_isProcessingPayment) const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text('Choose Payment Method:',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                _buildRadio<String>('Wallet', 'wallet', _payNowMethod, (value) {
                  setState(() => _payNowMethod = value!);
                }),
                _buildRadio<String>(
                    'PhonePe (Simulated)', 'phonepe', _payNowMethod, (value) {
                  setState(() => _payNowMethod = value!);
                }),
                _buildRadio<String>(
                    'Google Pay (Simulated)', 'googlepay', _payNowMethod,
                    (value) {
                  setState(() => _payNowMethod = value!);
                }),
                _buildRadio<String>('Paytm (Simulated)', 'paytm', _payNowMethod,
                    (value) {
                  setState(() => _payNowMethod = value!);
                }),
              ],
            ),
          ),
      ],
    );
  }
}
