import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:life_timerz/editprofile_page.dart';
import 'package:life_timerz/login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = "";
  String _email = "";
  bool _isLogoutPressed = false;
  bool _isChangePasswordPressed = false;

  User? _user;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;

    if (_user != null) {
      _name = _user!.displayName ?? "No Name Availabe";
      _email = _user!.email ?? "No Email Availabe";
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(255, 152, 167, 197),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  backgroundColor: Color.fromARGB(255, 32, 82, 233),
                  radius: 40,
                  child: Icon(
                    Icons.logout_outlined,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure want to logout?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'CANCEL',
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 32, 82, 233),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () async {
                await GoogleSignIn().signOut();
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    //after logout we cant back to profilr page
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (routes) => false,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Logged out successfully!',
                        style: TextStyle(color: Colors.green),
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'CONFIRM',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 246, 246, 255),
        automaticallyImplyLeading: false, // backbutton false
        toolbarHeight: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                alignment: Alignment.center,
                child: Stack(
                  alignment: AlignmentGeometry.bottomCenter,
                  children: [
                    Container(
                      padding: EdgeInsets.all(15.0),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: NetworkImage(
                          'https://picsum.photos/250',
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 5,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Color.fromARGB(255, 32, 82, 233),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                _name,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              Text(
                _email,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),

              const SizedBox(height: 5),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(),
                    ),
                  );
                  // reload updateduser data -> edit
                  await FirebaseAuth.instance.currentUser?.reload();
                  final updatedUser = FirebaseAuth.instance.currentUser;

                  if (updatedUser != null) {
                    setState(() {
                      _user = updatedUser;
                      _name = updatedUser.displayName ?? _name;
                      _email = updatedUser.email ?? _email;
                    });
                  }
                },
                icon: const Icon(
                  Icons.edit_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                label: const Text(
                  'EDIT',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 32, 82, 233),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    horizontalTitleGap: 13,
                    minVerticalPadding: 0,
                    dense: true,
                    leading: Icon(Icons.subscriptions_outlined),
                    title: Text('Subscription', style: TextStyle(fontSize: 14)),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    horizontalTitleGap: 13,
                    minVerticalPadding: 0,
                    dense: true,
                    leading: Icon(
                      Icons.lock_outline,
                      color: _isChangePasswordPressed
                          ? Colors.red
                          : Colors.black,
                    ),
                    title: Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isChangePasswordPressed
                            ? Colors.red
                            : Colors.black,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: _isChangePasswordPressed
                          ? Colors.red
                          : Colors.black,
                    ),
                    onTap: () async {
                      setState(() => _isChangePasswordPressed = true);
                      await Future.delayed(const Duration(milliseconds: 150));

                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null && user.email != null) {
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(
                            email: user.email!,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Password reset email sent successfully!',
                                style: TextStyle(color: Colors.green),
                              ),
                              backgroundColor: Colors.black,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        }
                      }
                      setState(() => _isChangePasswordPressed = false);
                    },
                  ),
                  Divider(height: 1, color: Colors.grey[300]),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    horizontalTitleGap: 13,
                    minVerticalPadding: 0,
                    dense: true,
                    leading: Icon(
                      Icons.logout_outlined,
                      color: _isLogoutPressed ? Colors.red : Colors.black,
                    ),
                    title: Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isLogoutPressed ? Colors.red : Colors.black,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: _isLogoutPressed ? Colors.red : Colors.black,
                    ),
                    onTap: () {
                      setState(() {
                        _isLogoutPressed = true;
                      });
                      Future.delayed(Duration(milliseconds: 150), () {
                        _showLogoutDialog(context);
                        setState(() {
                          _isLogoutPressed = false;
                        });
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
