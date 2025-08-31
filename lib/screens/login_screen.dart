import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fs = FirestoreService();
  final _authService = FirebaseAuthService();
  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveLogin(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loggedIn', true);
    await prefs.setString('uid', uid);
  }

  Future<void> _login() async {
    if (mounted) setState(() => _loading = true);

    try {
      final username = _usernameCtrl.text.trim().toLowerCase();
      final user = await _fs.getUserByUsername(username);

      if (!mounted) return;

      if (user == null ||
          _authService.hashPassword(_passwordCtrl.text) != user.passwordHash) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
        return;
      }

      await _saveLogin(user.uid);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void goSignup() => Navigator.of(context).pushNamed('/signup');
  void goForgot() => Navigator.of(context).pushNamed('/forgot');

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFF4A300);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/login_image.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Title
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Via',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.normal,
                              color: const Color.fromARGB(255, 81, 76, 161),
                            ),
                          ),
                          TextSpan(
                            text: 'Go',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 248, 175, 0),
                              shadows: [
                                Shadow(
                                  color: orange.withOpacity(0.5),
                                  offset: const Offset(2, 2),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Username
                    TextField(
                      controller: _usernameCtrl,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.person, color: Color(0xFF8B8B8B)),
                        labelText: 'Username',
                        labelStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Password
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      style: GoogleFonts.poppins(),
                      decoration: InputDecoration(
                        prefixIcon:
                            const Icon(Icons.lock, color: Color(0xFF8B8B8B)),
                        labelText: 'Password',
                        labelStyle: GoogleFonts.poppins(),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 18, horizontal: 16),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: goForgot,
                        child: Text(
                          'Forgot Password?',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF8B8B8B),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4B3FAE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'Login',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // Sign Up Prompt
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF8B8B8B),
                          ),
                        ),
                        GestureDetector(
                          onTap: goSignup,
                          child: Text(
                            'Sign Up',
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
        ],
      ),
    );
  }
}
