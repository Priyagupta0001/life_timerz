import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  GlobalKey<FormState> get formKey => _formKey;
  TextEditingController get nameController => _nameController;
  TextEditingController get emailController => _emailController;
  TextEditingController get passwordController => _passwordController;
  TextEditingController get confirmPasswordController =>
      _confirmPasswordController;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  //clear textfield
  void clearControllers() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    notifyListeners();
  }

  Future<String> signUp(BuildContext context) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (password != confirmPassword) {
      return "Passwords do not match!";
    }
    _setLoading(true);

    try {
      // CREATE USER
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      // STORE USER IN FIRESTORE
      if (user != null) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "name": name,
          "email": email,
          "createdAt": DateTime.now(),
        });

        _setLoading(false);
        clearControllers();
        return "success"; //IMPORTANT
      }

      _setLoading(false);
      return "Error: User not created";
    } on FirebaseAuthException catch (e) {
      _setLoading(false);

      if (e.code == 'email-already-in-use') {
        return "This email is already registered!";
      } else if (e.code == 'invalid-email') {
        return "Invalid email format!";
      } else if (e.code == 'weak-password') {
        return "Password is too weak!";
      }

      return e.message ?? "Signup failed, try again!";
    } catch (e) {
      _setLoading(false);
      return "Signup failed. Please try again!";
    }
  }
}
