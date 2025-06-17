import 'package:flutter/material.dart';

const String apiKey = "AIzaSyBFCbi7ht9miK8Mcqrusg25VWZzvLNa8qE";

const Color primaryColor = Color(0xFF467BA1);
const Color secondaryColor = Colors.black54;
const Color appBarColor = Color(0xFF749CB9);
const defaultFontSize = 14.0;
const defaultLabelFontSize = 16.0;
const defaultAppBarTitleFontSize = 20.0;
const defaultCarRentalFontSize = 12.0;

double getScreenWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

double getScreenHeight(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

// Method to show a dialog with a title and content
void showCustomDialog({
  required BuildContext context,
  required String title,
  required String content,
  required VoidCallback onPressed,
  String? textButton,
  bool showLoading = false, // Add showLoading parameter
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: showLoading
            ? Center(child: CircularProgressIndicator()) // Show loading indicator
            : Text(content, textAlign: TextAlign.justify),
        actions: [
          if (!showLoading) // Only show button if not loading
            TextButton(
              onPressed: onPressed,
              child: Text(textButton ?? 'OK'),
              style: TextButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      );
    },
  );
}

