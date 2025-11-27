import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _email = '';
  String get email => _email;
  set email(String value) {
    _email = value;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // FORGOT PASSWORD METHOD
  Future<String> sendPasswordResetEmail(
    BuildContext context, {
    required String email,
  }) async {
    if (_email.isEmpty) return "Email cannot be empty";

    _setLoading(true);
    try {
      await _auth.sendPasswordResetEmail(email: _email.trim());
      _setLoading(false);
      return "success"; // Success
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      if (e.code == 'user-not-found') {
        return "No user found for this email!";
      } else if (e.code == 'invalid-email') {
        return "Invalid email address!";
      } else {
        return "Error: ${e.message}";
      }
    } catch (e) {
      _setLoading(false);
      return "Error: ${e.toString()}";
    }
  }
}