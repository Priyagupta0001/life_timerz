import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ProfileProvider extends ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _userData;

  bool _isUpdatingProfile = false;
  bool _isLoading = false;
  bool _isLogoutPressed = false;
  bool _isChangePasswordPressed = false;

  //getters- read only
  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;

  bool get isUpdatingProfile => _isUpdatingProfile;
  bool get isLoading => _isLoading;
  bool get isLogoutPressed => _isLogoutPressed;
  bool get isChangePasswordPressed => _isChangePasswordPressed;

  //constructor
  ProfileProvider() {
    _user = FirebaseAuth.instance.currentUser;
    _fetchUserData();
  }

  void setUser(User newUser) {
    _user = newUser;
    _fetchUserData(); // naya user ka data fetch
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _fetchUserData() {
    final uid = _user?.uid;
    if (uid != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((snapshot) {
            _userData = snapshot.data();
            notifyListeners();
          });
    }
  }

  void setLogoutPressed(bool value) {
    _isLogoutPressed = value;
    notifyListeners();
  }

  void setChangePasswordPressed(bool value) {
    _isChangePasswordPressed = value;
    notifyListeners();
  }

  // Update profile method
  Future<void> updateProfile({required String name}) async {
    if (_user == null) throw Exception("User not logged in");

    _isUpdatingProfile = true;
    notifyListeners();

    try {
      // Update Firebase Auth displayName
      await _user!.updateDisplayName(name);

      // Update Firestore user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .update({'name': name, 'updatedAt': FieldValue.serverTimestamp()});

      // Reload user to get updated info
      await _user!.reload();
      _user = FirebaseAuth.instance.currentUser;

      //updte loacal userDtaa
      _userData?['name'] = _user?.displayName;

      _isUpdatingProfile = false;
      notifyListeners();
    } catch (e) {
      _isUpdatingProfile = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint("Logout failed: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<String> sendPasswordReset() async {
    final email = _user?.email;

    if (email == null || email.trim().isEmpty) {
      return "Your email is not available. Please login again!";
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return "success";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }
}