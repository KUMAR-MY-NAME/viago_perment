// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _phoneCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _sendingOtp = false;
  bool _obscurePassword = true;

  final _authService = FirebaseAuthService();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _startSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneCtrl.text.trim();
    final username = _usernameCtrl.text.trim().toLowerCase();
    final password = _passwordCtrl.text;

    setState(() => _sendingOtp = true);
    try {
      final result = await _authService.sendOtp(
        phone,
        codeSent: (verificationId, resendToken) async {
          // ✅ Save to Firestore
          await _createUserDocs(username, phone, password);

          // ✅ Save locally
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("username", username);
          await prefs.setString("phone", phone);
          await prefs.setBool("loggedIn", true);

          if (!mounted) return;
          Navigator.of(context).pushNamed(
            '/otp',
            arguments: {
              'flow': 'signup',
              'verificationId': verificationId,
              'username': username,
              'password': password,
              'phone': phone,
            },
          );
        },
      );

      if (!mounted) return;
      if (result != null) {
        await _createUserDocs(username, phone, password);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("username", username);
        await prefs.setString("phone", phone);
        await prefs.setBool("loggedIn", true);

        Navigator.of(context).pushNamed(
          '/otp',
          arguments: {
            'flow': 'signup',
            'confirmationResult': result,
            'username': username,
            'password': password,
            'phone': phone,
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  /// 🔥 Creates documents in both `users` and `profiles`
  Future<void> _createUserDocs(
      String username, String phone, String password) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection("users").doc(username).set({
      "username": username,
      "phone": phone,
      "password": password, // ⚠️ hash in production
      "createdAt": FieldValue.serverTimestamp(),
    });

    await firestore.collection("profiles").doc(username).set({
      "username": username,
      "phone": phone,
      "name": "",
      "age": "",
      "gender": "",
      "email": "",
      "profileImage": "",
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone required';
    if (!v.trim().startsWith('+')) return 'Include country code (e.g., +91...)';
    return null;
  }

  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Username required';
    if (!RegExp(r'^[a-zA-Z0-9._]{3,}$').hasMatch(v)) {
      return 'Min 3 chars, letters/digits/_/.';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password required';
    if (v.length < 8) return 'Minimum 8 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color.fromARGB(255, 81, 76, 161);
    const orange = Color.fromARGB(255, 248, 175,0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/signup_image.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// 🔥 Updated ViaGo text with shadow
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            letterSpacing: 1,
                          ),
                          children: [
                            TextSpan(
                              text: 'Via',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.normal,
                                color: purple,
                                shadows: const [
                                  Shadow(
                                    offset: Offset(2, 2),
                                    blurRadius: 4,
                                    color: purple,
                                  ),
                                ],
                              ),
                            ),
                            TextSpan(
                              text: 'Go',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: orange,
                                shadows: const [
                                  Shadow(
                                    offset: Offset(2, 2),
                                    blurRadius: 4,
                                    color: orange,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _usernameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          labelStyle: GoogleFonts.poppins(),
                          prefixIcon: const Icon(Icons.person, color: purple),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                        validator: _validateUsername,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: GoogleFonts.poppins(),
                          prefixIcon: const Icon(Icons.lock, color: purple),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(
                                  () => _obscurePassword = !_obscurePassword);
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: '+91 PhoneNumber',
                          labelStyle: GoogleFonts.poppins(),
                          prefixIcon: const Icon(Icons.phone, color: purple),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                        validator: _validatePhone,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _sendingOtp ? null : _startSignup,
                          child: _sendingOtp
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Sign Up',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account?',
                            style: GoogleFonts.poppins(),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushReplacementNamed('/login');
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Login In',
                              style: GoogleFonts.poppins(
                                color: orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
