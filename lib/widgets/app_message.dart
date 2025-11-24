import 'package:flutter/material.dart';

class AppMessageProvider extends ChangeNotifier {
  late GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  void showMessage(String message, {Color textColor = Colors.white}) {
    final messenger = scaffoldMessengerKey.currentState;

    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Text(message, style: TextStyle(color: textColor)),
          backgroundColor: Colors.black,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  //Error Message (RED TEXT)
  void showError(String message, BuildContext context) {
    showMessage(message, textColor: Colors.red);
  }

  //Success Message (GREEN TEXT)
  void showSuccess(String message, BuildContext context) {
    showMessage(message, textColor: Colors.green);
  }
}
