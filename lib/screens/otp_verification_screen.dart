import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../models/user_model.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _codeCtrl = TextEditingController();
  final _authService = FirebaseAuthService();
  final _fs = FirestoreService();
  bool _verifying = false;
  bool _resending = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map?;
    if (args == null) return;

    final flow = (args['flow'] as String?) ?? 'signup';

    if (mounted) setState(() => _verifying = true);
    try {
      UserCredential cred;

      if (args.containsKey('confirmationResult')) {
        // Web
        cred = await _authService.confirmOtpWeb(
          args['confirmationResult'],
          _codeCtrl.text.trim(),
        );
      } else {
        // Mobile: verificationId + smsCode
        final verificationId = args['verificationId'] as String;
        final smsCode = _codeCtrl.text.trim();
        final c = _authService.buildSmsCredential(verificationId, smsCode);
        cred = await _authService.signInWithCredential(c);
      }

      if (!mounted) return;

      final user = cred.user;
      if (user == null) {
        throw Exception('No user after verification');
      }

      if (flow == 'signup') {
        final username = (args['username'] as String).toLowerCase();
        final password = args['password'] as String;
        final phone = args['phone'] as String;

        // 1) Reserve username (transaction)
        final reserved = await _fs.tryReserveUsername(username, user.uid);
        if (!reserved) {
          await _authService.signOut();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Username already taken. Please choose another one.'),
            ),
          );
          Navigator.popUntil(context, ModalRoute.withName('/signup'));
          return;
        }

        // 2) Create user document in Firestore
        final passwordHash = _authService.hashPassword(password);
        final appUser = AppUser(
          uid: user.uid,
          username: username,
          phone: phone,
          passwordHash: passwordHash,
          createdAt: DateTime.now(),
        );
        await _fs.createUser(appUser);

        if (!mounted) return;

        // ✅ Keep user signed in and go to Home
        Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
      } else if (flow == 'reset') {
        final uid =
            (args['uid'] as String?) ?? FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) {
          throw Exception('No user for reset');
        }

        if (!mounted) return;

        Navigator.of(context).pushReplacementNamed(
          '/forgot',
          arguments: {'stage': 'set_new', 'uid': uid},
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP verify failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _resending = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _resending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP resent!')),
    );
  }

  Widget _buildCombinedIcon() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.orange[700],
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 10,
            bottom: 10,
            child: Icon(
              Icons.phone_in_talk_rounded,
              size: 28,
              color: Colors.white,
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Icon(
              Icons.sms_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Via',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[900],
                        ),
                      ),
                      Text(
                        'Go',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildCombinedIcon(),
                  const SizedBox(height: 16),
                  Text(
                    'OTP Verification',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter the 6-digit code sent to your mobile',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  PinCodeTextField(
                    appContext: context,
                    length: 6,
                    controller: _codeCtrl,
                    keyboardType: TextInputType.number,
                    animationType: AnimationType.fade,
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.box,
                      borderRadius: BorderRadius.circular(8),
                      fieldHeight: 50,
                      fieldWidth: 40,
                      activeColor: Colors.orange[700]!,
                      selectedColor: Colors.indigo[900]!,
                      inactiveColor: Colors.grey[300]!,
                    ),
                    onChanged: (value) {},
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verifying ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[900],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _verifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Verify OTP',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Haven't received OTP?",
                        style: TextStyle(fontSize: 14),
                      ),
                      TextButton(
                        onPressed: _resending ? null : _resendOtp,
                        child: Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: Colors.orange[700],
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
    );
  }
}
