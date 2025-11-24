import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  TextEditingController get emailController => _emailController;
  TextEditingController get passwordController => _passwordController;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearFields() {
    _emailController.clear();
    _passwordController.clear();
    notifyListeners();
  }
  
  // LOGIN
  Future<String> logIn(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    _setLoading(true);

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      _setLoading(false);
      return "success";
    } on FirebaseAuthException catch (e) {
      _setLoading(false);

      if (e.code == 'user-not-found') return "No user found!";
      if (e.code == 'wrong-password') return "Incorrect password!";
      if (e.code == 'invalid-email') return "Invalid email address!";
      return "Error: ${e.message}";
    } catch (e) {
      _setLoading(false);
      return "Error: ${e.toString()}";
    }
  }

  // GOOGLE LOGIN
  Future<String> googleLogin(BuildContext context) async {
    _setLoading(true);

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        _setLoading(false);
        return "Google Sign-In cancelled!";
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      _setLoading(false);
      return "success";
    } catch (e) {
      _setLoading(false);
      return "Google Login Failed: $e";
    }
  }
}
