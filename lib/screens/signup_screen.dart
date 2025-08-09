import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
        codeSent: (verificationId, resendToken) {
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

      // Web path (ConfirmationResult)
      if (result != null) {
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

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Phone required';
    if (!v.trim().startsWith('+')) return 'Include country code (e.g., +91...)';
    return null;
  }

  // Fixed: added underscore to match usage in validator
  String? _validateUsername(String? v) {
    if (v == null || v.trim().isEmpty) return 'Username required';
    // Allow letters, digits, underscore, dot. Min length 3.
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
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (+CountryCode...)',
                ),
                validator: _validatePhone,
              ),
              TextFormField(
                controller: _usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: _validateUsername, // now matches function name
              ),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: _validatePassword,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _sendingOtp ? null : _startSignup,
                child: _sendingOtp
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send OTP'),
              ),
              if (kIsWeb)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Note: On web, an invisible reCAPTCHA may appear.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
