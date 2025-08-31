import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sender_screen.dart';
import 'traveler_screen.dart';
import 'receiver_screen.dart';
import 'my_trips_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'menu_screen.dart'; // ✅ new
import 'notification_screen.dart'; // ✅ new

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? username;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString('uid');
    String? uid;

    if (savedUid != null) {
      uid = savedUid; // login via username/password
    } else {
      final user = FirebaseAuth.instance.currentUser;
      uid = user?.uid; // login via OTP
    }

    if (uid != null) {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        setState(() {
          username = doc['username'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      _buildHomeContent(context),
      const MyTripsScreen(),
      const HistoryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      drawer: MenuScreen(username: username), // ✅ use MenuScreen
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
        title: const Text(
          "ViaGo",
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          )
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.directions_walk), label: "My Trips"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.deepPurple,
          padding: const EdgeInsets.all(12),
          child: Text(
            "Welcome ${username ?? 'username'}",
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          color: Colors.deepPurple,
          child: Column(
            children: [
              Container(height: 8, color: Colors.orange),
              const SizedBox(height: 5),
              Container(height: 8, color: Colors.green),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _buildStyledButton(context, "Sender", Colors.deepPurple, Icons.person,
            const SenderScreen()),
        _buildStyledButton(context, "Traveler", Colors.orange,
            Icons.directions_walk, const TravelerScreen()),
        _buildStyledButton(context, "Receiver", Colors.green, Icons.home,
            const ReceiverScreen()),
      ],
    );
  }

  Widget _buildStyledButton(BuildContext context, String text, Color color,
      IconData icon, Widget screen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 25, height: 3, color: color),
                  const SizedBox(width: 4),
                  Container(width: 25, height: 3, color: color),
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(30)),
                child: Icon(icon, color: Colors.white),
              )
            ],
          ),
        ),
      ),
    );
  }
}
