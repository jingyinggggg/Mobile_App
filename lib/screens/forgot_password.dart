import 'package:assignment_tripmate/screens/login.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // Add email and password controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    newPasswordController.dispose();
    confirmNewPasswordController.dispose();
    super.dispose();
  }

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

  Future<void> _resetPassword() async {
    setState(() {
      isLoading = true; // Start loading
    });

    String email = emailController.text;
    String newPassword = newPasswordController.text;
    String confirmNewPassword = confirmNewPasswordController.text;

    // Validate the password (at least 8 characters and 1 special character)
    bool isValidPassword(String password) {
      final passwordRegex = RegExp(r'^(?=.*?[#?!@$%^&*-]).{8,}$');
      return passwordRegex.hasMatch(password);
    }

    if (email.isNotEmpty && newPassword.isNotEmpty && confirmNewPassword.isNotEmpty) {
      if (!isValidPassword(newPassword)) {
        _showDialog(
          title: 'Invalid Password',
          content: 'Password must be at least 8 characters long and contain at least one special character.',
          onPressed: () {
            Navigator.of(context).pop();
          },
        );
        setState(() {
          isLoading = false;
        });
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
        setState(() {
          isLoading = false;
        });
        return;
      }

      try {
         String newHashedPassword = hashPassword(newPassword);

        // Check 'users' collection first
        QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          DocumentSnapshot userDoc = userQuery.docs.first;
          
          // Update the password in the 'users' collection
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userDoc.id)
              .update({'password': newHashedPassword});

          _showDialog(
            title: 'Success',
            content: 'Password updated successfully!',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        const LoginScreen()),
              );
            },
          );
        } else {
          // Check 'travelAgent' collection if user not found
          QuerySnapshot TAQuery = await FirebaseFirestore.instance
              .collection('travelAgent')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          if (TAQuery.docs.isNotEmpty) {
            DocumentSnapshot TADoc = TAQuery.docs.first;
            
            // Update the password in the 'travelAgent' collection
            await FirebaseFirestore.instance
                .collection('travelAgent')
                .doc(TADoc.id)
                .update({'password': newHashedPassword});

            _showDialog(
              title: 'Success',
              content: 'Password updated successfully!',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          const LoginScreen()),
                );
              },
            );
          } else {
            _showDialog(
              title: 'Error',
              content: 'Email entered does not exist in the system. Please try again...',
              onPressed: () {
                Navigator.of(context).pop();
              },
            );
          }
        }
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
        isLoading = false;
      });
    }
  }

  // Method to show a dialog with a title and content
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

  // Define a method to create the email TextField
  Widget email() {
    return TextField(
      controller: emailController,
      style: const TextStyle(
        fontFamily: 'Inika',
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Enter your email',
        labelText: 'Email',
        prefixIcon: const Icon(
          Icons.email,
          color: Color(0xFF467BA1),
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
          fontFamily: 'Inika',
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

  // Define a method to create the password TextField
  Widget new_password() {
    return TextField(
      controller: newPasswordController,
      obscureText: newPasswordVisible,
      style: const TextStyle(
        fontFamily: 'Inika',
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: "Enter your new password",
        labelText: "New Password",
        prefixIcon: const Icon(
          Icons.lock,
          color: Color(0xFF467BA1),
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              newPasswordVisible = !newPasswordVisible;
            });
          },
          icon: Icon(
            newPasswordVisible
                ? Icons.visibility_off
                : Icons.visibility,
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
          fontFamily: 'Inika',
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

  // Define a method to create the confirm new password TextField
  Widget confirm_new_password() {
    return TextField(
      controller: confirmNewPasswordController,
      obscureText: confirmNewPasswordVisible,
      style: const TextStyle(
        fontFamily: 'Inika',
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: "Enter your new password again",
        labelText: "Confirm New Password",
        prefixIcon: const Icon(
          Icons.lock,
          color: Color(0xFF467BA1),
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              confirmNewPasswordVisible = !confirmNewPasswordVisible;
            });
          },
          icon: Icon(
            confirmNewPasswordVisible
                ? Icons.visibility_off
                : Icons.visibility,
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
          fontFamily: 'Inika',
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/welcome_background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // White container with opacity
          Container(
            height: double.infinity,
            color: const Color(0xFFEDF2F6).withOpacity(0.6),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05), // Responsive padding
                  child: Column(
                    children: [
                      // Back arrow icon aligned to the left
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            icon: Icon(Icons.arrow_back_outlined),
                            iconSize: screenWidth * 0.08, // Responsive icon size
                            color: Colors.black,
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenHeight * 0.02), // Responsive padding
                          ),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.07), // Responsive height
                      Container(
                        child: Column(
                          children: [
                            Center(
                              child: Image.asset(
                                'images/logo.png',
                                height: screenWidth * 0.3, // Responsive image height
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.03), // Responsive height
                            const Center(
                              child: Text(
                                'TripMate',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontFamily: 'Inika',
                                ),
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.03), // Responsive height
                            email(),
                            SizedBox(height: screenHeight * 0.03), // Responsive height
                            new_password(),
                            SizedBox(height: screenHeight * 0.03), // Responsive height
                            confirm_new_password(),
                            SizedBox(height: screenHeight * 0.05), // Responsive height
                            Container(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  _resetPassword();
                                },
                                child: const Text(
                                  'Reset Password',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF467BA1),
                                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02), // Responsive vertical padding
                                  textStyle: TextStyle(
                                    fontSize: screenWidth * 0.05, // Responsive font size
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
