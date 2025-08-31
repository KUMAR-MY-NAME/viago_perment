import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../services/firebase_auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = FirebaseAuthService();
  final _fs = FirestoreService();
  bool _sending = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtpForReset() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter phone number')));
      return;
    }

    if (mounted) setState(() => _sending = true);

    try {
      final result = await _authService.sendOtp(
        _phoneCtrl.text.trim(),
        codeSent: (verificationId, resendToken) {
          if (!mounted) return;
          Navigator.of(context).pushNamed(
            '/otp',
            arguments: {
              'flow': 'reset',
              'verificationId': verificationId,
            },
          );
        },
      );

      if (!mounted) return;

      if (result != null) {
        Navigator.of(context).pushNamed(
          '/otp',
          arguments: {
            'flow': 'reset',
            'confirmationResult': result,
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to send OTP: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _setNewPassword(String uid) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final hash = _authService.hashPassword(_newPassCtrl.text);
      await _fs.updatePasswordHash(uid, hash);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please login.')),
      );

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    final stage = args != null ? args['stage'] as String? : null;
    final uid = args != null ? args['uid'] as String? : null;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Align background image to center right, not covering logo/input
          if (stage != 'set_new')
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 0), // Adjust if needed
                child: Image.asset(
                  'assets/images/lock_symbol.png',
                  width: 260, // Adjust width as per your design
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                            letterSpacing: 1,
                            color: Color(0xFF22215B),
                          ),
                          children: [
                            TextSpan(text: 'Via'),
                            TextSpan(
                              text: 'Go',
                              style: TextStyle(color: Color(0xFFFBA13C)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (stage == 'set_new')
                      Column(
                        children: [
                          const Icon(Icons.vpn_key_rounded,
                              color: Color(0xFFFBA13C), size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'Reset Your Password',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFFFBA13C),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'password must be difference than before',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF8D8D8D),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _newPassCtrl,
                                  obscureText: _obscureNew,
                                  decoration: InputDecoration(
                                    prefixIcon:
                                        const Icon(Icons.lock_outline_rounded),
                                    labelText: 'New Password',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureNew
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      onPressed: () {
                                        setState(() {
                                          _obscureNew = !_obscureNew;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Required';
                                    }
                                    if (v.length < 8) {
                                      return 'Minimum 8 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _confirmPassCtrl,
                                  obscureText: _obscureConfirm,
                                  decoration: InputDecoration(
                                    prefixIcon:
                                        const Icon(Icons.lock_outline_rounded),
                                    labelText: 'Confirm Password',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureConfirm
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirm = !_obscureConfirm;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Required';
                                    }
                                    if (v != _newPassCtrl.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4B4BC6),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: uid == null
                                        ? null
                                        : () => _setNewPassword(uid),
                                    child: const Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          const Icon(Icons.lock_reset_rounded,
                              color: Color(0xFFFBA13C), size: 36),
                          const SizedBox(height: 8),
                          const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFFFBA13C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Enter your Mobile Number:',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8D8D8D),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                  Icons.phone_android_rounded,
                                  color: Color(0xFF4B4BC6)),
                              labelText: 'PhoneNumber',
                              hintText: '+91  PhoneNumber',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4B4BC6),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _sending ? null : _sendOtpForReset,
                              child: _sending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
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
