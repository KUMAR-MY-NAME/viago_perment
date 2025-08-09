import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

// Hash password using SHA-256 (demo). For production, prefer server-side KDF.
  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

// Web uses ConfirmationResult; mobile uses verifyPhoneNumber.
  Future<dynamic> sendOtp(
    String phoneNumber, {
    Function(String verificationId, int? resendToken)? codeSent,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (kIsWeb) {
// Web
      return await _auth.signInWithPhoneNumber(phoneNumber);
    }

// Android/iOS
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: timeout,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval on Android may complete here. Optional: sign in automatically.
        // You can sign in here if you want:
        // try { await _auth.signInWithCredential(credential); } catch (_) {}
      },
      verificationFailed: (FirebaseAuthException e) {
        // Surface the exact code/message for debugging
        throw FirebaseAuthException(
          code: e.code,
          message: e.message,
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        if (codeSent != null) codeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        // Optional: log timeout
      },
    );
    return null;
  }

  Future<UserCredential> confirmOtpWeb(
      dynamic confirmationResult, String smsCode) async {
    return await confirmationResult.confirm(smsCode);
  }

  Future<UserCredential> signInWithCredential(
      PhoneAuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  PhoneAuthCredential buildSmsCredential(
      String verificationId, String smsCode) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
