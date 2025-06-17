import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUpdatePasswordScreen extends StatefulWidget {
  final String userId;

  const AdminUpdatePasswordScreen({super.key, required this.userId});

  @override
  State<AdminUpdatePasswordScreen> createState() => _AdminUpdatePasswordScreenState();
}

class _AdminUpdatePasswordScreenState extends State<AdminUpdatePasswordScreen> {
  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController = TextEditingController();

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.dispose();
  }

  bool currentPasswordVisible = true;
  bool newPasswordVisible = true;
  bool confirmNewPasswordVisible = true;
  bool isLoading = false;

  // Hash the password using bcrypt
  String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  // Verify the password against the hashed password
  bool verifyPassword(String password, String storedHash) {
    return BCrypt.checkpw(password, storedHash);
  }

  bool isValidPassword(String password) {
    final passwordRegex = RegExp(r'^(?=.*?[#?!@$%^&*-]).{8,}$');
    return passwordRegex.hasMatch(password);
  }

  Future<void> _updatePassword() async {
    setState(() {
      isLoading = true; // Start loading
    });

    String currentPassword = currentPasswordController.text;
    String newPassword = newPasswordController.text;
    String confirmNewPassword = confirmNewPasswordController.text;

    if (currentPassword.isNotEmpty && newPassword.isNotEmpty && confirmNewPassword.isNotEmpty) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('admin').doc(widget.userId).get();
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        String storedHashedPassword = userData?['password'] ?? '';

        if (!verifyPassword(currentPassword, storedHashedPassword)) {
          _showDialog(
            title: 'Error',
            content: 'Current password is incorrect.',
            onPressed: () {
              Navigator.of(context).pop();
            },
          );
          return;
        }

        if (!isValidPassword(newPassword)) {
          _showDialog(
            title: 'Invalid Password',
            content: 'Password must be at least 8 characters long and contain at least one special character.',
            onPressed: () {
              Navigator.of(context).pop();
            },
          );
          return;
        }

        if (newPassword != confirmNewPassword) {
          _showDialog(
            title: 'Error',
            content: 'New password and confirmation do not match.',
            onPressed: () {
              Navigator.of(context).pop();
            },
          );
          return;
        }

        String newHashedPassword = hashPassword(newPassword);

        await FirebaseFirestore.instance.collection('admin').doc(widget.userId).update({
          'password': newHashedPassword,
        });

        _showDialog(
          title: 'Success',
          content: 'Password updated successfully!',
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          },
        );
      } catch (e) {
        _showDialog(
          title: 'Error',
          content: 'An error occurred: $e',
          onPressed: () {
            Navigator.of(context).pop();
          },
        );
      } finally {
        setState(() {
          isLoading = false; // Stop loading
        });
      }
    } else {
      _showDialog(
        title: 'Validation Error',
        content: 'Please ensure all fields are filled completely.',
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  void _showDialog({
    required String title,
    required String content,
    required VoidCallback onPressed,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: onPressed,
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _passwordTextField({
    required TextEditingController controller,
    required String hintText,
    required String labelText,
    required bool obscureText,
    required VoidCallback onVisibilityToggle,
    required bool isVisible,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: const Icon(
          Icons.lock,
          color: Color(0xFF467BA1),
          size: 18,
        ),
        suffixIcon: IconButton(
          onPressed: onVisibilityToggle,
          icon: Icon(
            isVisible ? Icons.visibility_off : Icons.visibility,
            size: 18,
          ),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF467BA1),
            width: 2.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF467BA1),
            width: 2.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF467BA1),
            width: 2.5,
          ),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          shadows: [
            Shadow(
              offset: Offset(0.3, 0.3),
              color: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Update Password"),
        centerTitle: true,
        backgroundColor: const Color(0xFF749CB9),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inika',
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView( // Wrap with SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _passwordTextField(
                controller: currentPasswordController,
                hintText: "Enter your current password",
                labelText: "Current Password",
                obscureText: currentPasswordVisible,
                onVisibilityToggle: () {
                  setState(() {
                    currentPasswordVisible = !currentPasswordVisible;
                  });
                },
                isVisible: currentPasswordVisible,
              ),
              const SizedBox(height: 20),
              _passwordTextField(
                controller: newPasswordController,
                hintText: "Enter your new password",
                labelText: "New Password",
                obscureText: newPasswordVisible,
                onVisibilityToggle: () {
                  setState(() {
                    newPasswordVisible = !newPasswordVisible;
                  });
                },
                isVisible: newPasswordVisible,
              ),
              const SizedBox(height: 20),
              _passwordTextField(
                controller: confirmNewPasswordController,
                hintText: "Enter your new password again",
                labelText: "Confirm New Password",
                obscureText: confirmNewPasswordVisible,
                onVisibilityToggle: () {
                  setState(() {
                    confirmNewPasswordVisible = !confirmNewPasswordVisible;
                  });
                },
                isVisible: confirmNewPasswordVisible,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: isLoading ? null : _updatePassword,
                child: isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Update Password',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF467BA1),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
