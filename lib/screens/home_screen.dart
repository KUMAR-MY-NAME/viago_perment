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
        backgroundColor: const Color.fromARGB(255, 82, 76, 161),
        centerTitle: true,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(27), // ✅ Rounded logo
          child: Image.asset(
            'assets/images/text_logo.png',
            height: 55,
            fit: BoxFit.contain,
          ),
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
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 82, 76, 161),
          borderRadius: BorderRadius.circular(40),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: _currentIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: ""),
            BottomNavigationBarItem(icon: Icon(Icons.directions_walk), label: ""),
            BottomNavigationBarItem(icon: Icon(Icons.access_time), label: ""),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: ""),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          color: const Color.fromARGB(255, 82, 76, 161),
          padding: const EdgeInsets.all(25),
          child: Text(
            "Welcome ${username ?? 'username'}",
            style: const TextStyle(color: Colors.white, fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 30),
        _buildStyledButton(context, "Sender", const Color.fromARGB(255, 82, 76, 161), Icons.person,
            const SenderScreen()),
        _buildStyledButton(context, "Traveler",const Color.fromARGB(255, 215, 145, 65),
            Icons.directions_walk, const TravelerScreen(), inverted: true),
        _buildStyledButton(context, "Receiver", const Color.fromARGB(255, 168, 173, 95), Icons.home,
            const ReceiverScreen()),
      ],
    );
  }

  Widget _buildStyledButton(BuildContext context, String text, Color color,
      IconData icon, Widget screen, {bool inverted = false}) {
    final label = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );

    final iconCircle = Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 255, 255, 255),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
      ),
      child: Icon(icon, color: color),
    );

    final stripes = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          width: 18,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
        child: Center( // ✅ Centered buttons
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: inverted
                ? [
                    iconCircle,
                    const SizedBox(width: 12),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 240,
                          height: 70,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(36),
                          ),
                        ),
                        Positioned(left: 16, child: stripes),
                        Center(child:label),
                      ],
                    ),
                  ]
                : [
                    Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Container(
                          width: 240,
                          height: 70,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(36),
                          ),
                        ),
                        Positioned(right: 16, child: stripes),
                        Positioned(right: 60, child: label),
                      ],
                    ),
                    const SizedBox(width: 12),
                    iconCircle,
                  ],
          ),
        ),
      ),
    );
  }
}
