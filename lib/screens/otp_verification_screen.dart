import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

        // 1) Atomically reserve username (transaction)
        final reserved = await _fs.tryReserveUsername(username, user.uid);
        if (!reserved) {
          // Username already taken
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

        // 2) Create user document
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

        // 3) Optional: sign out to require username/password login later
        await _authService.signOut();

        if (!mounted) return;

        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
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

  @override
  Widget build(BuildContext context) {
    final flow =
        (ModalRoute.of(context)!.settings.arguments as Map?)?['flow'] ??
            'signup';
    return Scaffold(
      appBar: AppBar(title: Text('Enter OTP (${flow.toString()})')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _codeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'OTP Code'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _verifying ? null : _verify,
              child: _verifying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
