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
  final _formKey = GlobalKey<FormState>();
  final _authService = FirebaseAuthService();
  final _fs = FirestoreService();
  bool _sending = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtpForReset() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter phone number'))); // Safe: no async yet
      return;
    }

    if (mounted) {
      setState(() => _sending = true);
    }

    try {
      final result = await _authService.sendOtp(
        _phoneCtrl.text.trim(),
        codeSent: (verificationId, resendToken) {
          // Callback can be invoked later; guard with mounted before using context
          if (!mounted) return; // Guard per lint rule
          Navigator.of(context).pushNamed(
            '/otp',
            arguments: {
              'flow': 'reset',
              'verificationId': verificationId,
              // We'll locate uid by phone after verification
            },
          );
        },
      );

      if (!mounted) return; // Guard after await before using context

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
      if (!mounted) return; // Guard before using context
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to send OTP: $e')));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _setNewPassword(String uid) async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final hash = _authService.hashPassword(_newPassCtrl.text);
      await _fs.updatePasswordHash(uid, hash);

      if (!mounted) return; // Guard after await before using context

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please login.')),
      );

      if (!mounted) return; // Guard before navigation

      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    } catch (e) {
      if (!mounted) return; // Guard before using context
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
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: stage == 'set_new'
            ? Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _newPassCtrl,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'New Password'),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.length < 8) return 'Minimum 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed:
                          uid == null ? null : () => _setNewPassword(uid),
                      child: const Text('Save New Password'),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone (+CountryCode...)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _sending ? null : _sendOtpForReset,
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Send OTP'),
                  ),
                ],
              ),
      ),
    );
  }
}
