import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:packmate/screens/package_detail_screen.dart';
import 'package:packmate/models/parcel.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String _searchQuery = '';
  DateTime? _selectedDate;
  String _selectedParcelType = 'All'; // 'All', 'Fragile', 'Fast Delivery'

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text('Please log in to view your trips.'));
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Trips'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sender'),
              Tab(text: 'Traveler'),
              Tab(text: 'Receiver'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search by City or Address',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedParcelType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      items: <String>['All', 'Fragile', 'Fast Delivery']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedParcelType = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildParcelList(role: 'sender'),
                  _buildParcelList(role: 'traveler'),
                  _buildParcelList(role: 'receiver'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParcelList({required String role}) {
    List<String> statuses;
    switch (role) {
      case 'sender':
        statuses = ['posted', 'selected', 'confirmed', 'in_transit', 'awaiting_receiver_payment'];
        break;
      case 'traveler':
        statuses = ['selected', 'confirmed', 'in_transit', 'awaiting_receiver_payment'];
        break;
      case 'receiver':
        statuses = ['selected','confirmed', 'in_transit', 'awaiting_receiver_payment'];
        break;
      default:
        statuses = [];
    }

    if (statuses.isEmpty) {
      return const Center(child: Text('Invalid role.'));
    }

    Query query = FirebaseFirestore.instance.collection('parcels')
        .where('status', whereIn: statuses);
    final uid = currentUser!.uid;

    if (role == 'sender') {
      query = query.where('createdByUid', isEqualTo: uid);
    } else if (role == 'traveler') {
      query = query.where('assignedTravelerUid', isEqualTo: uid);
    } else if (role == 'receiver') {
      query = query.where('receiverUid', isEqualTo: uid);
    }

    // Apply search query (city/address)
    if (_searchQuery.isNotEmpty) {
      query = query.where('pickupCity', isGreaterThanOrEqualTo: _searchQuery)
                   .where('pickupCity', isLessThanOrEqualTo: _searchQuery + '\uf8ff');
      // You might want to add more complex search logic for multiple fields or fuzzy search
      // For simplicity, only pickupCity is filtered here.
    }

    // Apply date filter
    if (_selectedDate != null) {
      final startOfDay = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day);
      final endOfDay = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59);
      query = query.where('pickupDate', isGreaterThanOrEqualTo: startOfDay)
                   .where('pickupDate', isLessThanOrEqualTo: endOfDay);
    }

    // Apply parcel type filter
    if (_selectedParcelType == 'Fragile') {
      query = query.where('fragile', isEqualTo: true);
    } else if (_selectedParcelType == 'Fast Delivery') {
      query = query.where('fastDelivery', isEqualTo: true);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (c, s) {
        if (s.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (s.hasError) {
          return Center(child: Text('Error: ${s.error}'));
        }
        if (!s.hasData || s.data!.docs.isEmpty) {
          return const Center(child: Text('No packages found.'));
        }
        
        final docs = s.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (c, i) {
            final parcel = Parcel.fromDoc(docs[i]);
            return Card(
              margin: const EdgeInsets.all(8),
              child: ListTile(
                title: Text('#${parcel.id} – ${parcel.contents}'),
                subtitle:
                    Text('From: ${parcel.pickupCity} To: ${parcel.destCity} • Status: ${parcel.status}'),
                trailing: TextButton(
                  child: const Text('View'),
                  onPressed: () {
                    Navigator.push(
                      c,
                      MaterialPageRoute(
                        builder: (_) => PackageDetailScreen(
                          parcelId: parcel.id,
                          role: role,
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}
