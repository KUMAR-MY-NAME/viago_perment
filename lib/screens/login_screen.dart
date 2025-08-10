import 'package:flutter/material.dart';
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
    if (mounted) {
      setState(() => _loading = true);
    }
    try {
      final username = _usernameCtrl.text.trim().toLowerCase();
      final user = await _fs.getUserByUsername(username);

      if (!mounted) return;

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
        return;
      }

      final hash = _authService.hashPassword(_passwordCtrl.text);

      if (!mounted) return;

      if (hash != user.passwordHash) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid username or password')),
        );
        return;
      }

      // Save login state locally
      await _saveLogin(user.uid);

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        '/home',
        arguments: {'uid': user.uid},
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void goSignup() {
    Navigator.of(context).pushNamed('/signup');
  }

  void goForgot() {
    Navigator.of(context).pushNamed('/forgot');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _usernameCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Login'),
            ),
            TextButton(
                onPressed: goForgot, child: const Text('Forgot Password')),
            TextButton(
                onPressed: goSignup, child: const Text('Create Account')),
          ],
        ),
      ),
    );
  }
}
