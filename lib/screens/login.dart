// ignore_for_file: prefer_const_constructors, non_constant_identifier_names, use_build_context_synchronously, avoid_print

// import 'package:assignment_tripmate/firebase_auth_services.dart';
import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/admin/homepage.dart';
import 'package:assignment_tripmate/screens/forgot_password.dart';
import 'package:assignment_tripmate/screens/tarvel_agent_sign_up.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentHomepage.dart';
import 'package:assignment_tripmate/screens/user/homepage.dart';
import 'package:assignment_tripmate/screens/user_sign_up.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  // Add email and password controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  bool passwordVisible = true;
  bool rememberMe = false;
  bool isLoading = false; // Track loading state

  // Hash the password using bcrypt
  String hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  Future<void> _login() async {
    setState(() {
      isLoading = true; // Start loading
    });

    String email = emailController.text;
    String password = passwordController.text;

    try {
      // Check 'users' collection first
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userQuery.docs.first;

        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;
          String? storedPasswordHash = data['password']; // Password hash

          if (storedPasswordHash != null) {
            // Verify the entered password with the stored hash
            bool isPasswordCorrect = BCrypt.checkpw(password, storedPasswordHash);

            if (isPasswordCorrect) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => UserHomepageScreen(userId: userDoc.id)),
              );
            } else {
              _showDialog(
                title: 'Login Failed',
                content: 'Incorrect password.',
                onPressed: () {
                  Navigator.of(context).pop();
                },
              );
            }
          } else {
            _showDialog(
              title: 'Login Failed',
              content: 'Password field is missing.',
              onPressed: () {
                Navigator.of(context).pop();
              },
            );
          }
        } else {
          _showDialog(
            title: 'Login Failed',
            content: 'User does not exist in the system.',
            onPressed: () {
              Navigator.of(context).pop();
            },
          );
        }
      } else {
        // Check 'admin' collection if user not found
        QuerySnapshot adminQuery = await FirebaseFirestore.instance
            .collection('admin')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (adminQuery.docs.isNotEmpty) {
          DocumentSnapshot adminDoc = adminQuery.docs.first;

          if (adminDoc.exists) {
            String? storedPasswordHash = adminDoc['password']; // Password hash

            if (storedPasswordHash != null) {
              // Verify the entered password with the stored hash
              bool isPasswordCorrect = BCrypt.checkpw(password, storedPasswordHash);

              if (isPasswordCorrect) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AdminHomepageScreen(userId: adminDoc['id'])),
                );
              } else {
                _showDialog(
                  title: 'Login Failed',
                  content: 'Incorrect password for admin.',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                );
              }
            } else {
              _showDialog(
                title: 'Login Failed',
                content: 'Password field is missing in admin document.',
                onPressed: () {
                  Navigator.of(context).pop();
                },
              );
            }
          } else {
            _showDialog(
              title: 'Login Failed',
              content: 'Admin does not exist in the system.',
              onPressed: () {
                Navigator.of(context).pop();
              },
            );
          }
        } else {
          // Check 'travelAgent' collection if user not found
          QuerySnapshot TAQuery = await FirebaseFirestore.instance
            .collection('travelAgent')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
          
          if (TAQuery.docs.isNotEmpty) {
            DocumentSnapshot TADoc = TAQuery.docs.first;

            if (TADoc.exists) {
              String? storedPasswordHash = TADoc['password']; // Password hash

              if (storedPasswordHash != null) {
                // Verify the entered password with the stored hash
                bool isPasswordCorrect = BCrypt.checkpw(password, storedPasswordHash);

                if (isPasswordCorrect) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TravelAgentHomepageScreen(userId: TADoc.id)),
                  );
                } else {
                  _showDialog(
                    title: 'Login Failed',
                    content: 'Incorrect password for travel agent.',
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  );
                }
              } else {
                _showDialog(
                  title: 'Login Failed',
                  content: 'Password field is missing in travel agent document.',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                );
              }
            } else {
              _showDialog(
                title: 'Login Failed',
                content: 'Travel agent does not exist in the system.',
                onPressed: () {
                  Navigator.of(context).pop();
                },
              );
            }
          } else {
            _showDialog(
              title: 'Login Failed',
              content: 'Email not found in the system.',
              onPressed: () {
                Navigator.of(context).pop();
              },
            );
          }
        }
      }
    } catch (e) {
      _showDialog(
        title: 'Login Failed',
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
          size: 20,
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
  Widget password() {
    return TextField(
      controller: passwordController,
      obscureText: passwordVisible,
      style: const TextStyle(
        fontFamily: 'Inika',
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: "Enter your password",
        labelText: "Password",
        prefixIcon: const Icon(
          Icons.lock,
          color: Color(0xFF467BA1),
          size: 20,
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              passwordVisible = !passwordVisible;
            });
          },
          icon: Icon(
            passwordVisible ? Icons.visibility_off : Icons.visibility,
            size: 20,
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

  // Widget remember_me() {
  //   return Checkbox(
  //     value: rememberMe,
  //     onChanged: (bool? value) {
  //       setState(() {
  //         rememberMe = value!;
  //       });
  //     },
  //     activeColor: Color(0xFF467BA1), // Color when the checkbox is checked
  //     side: BorderSide(color: Color(0xFF467BA1), width: 2.0), // Border color and width
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true, // Allow the screen to resize when the keyboard appears
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
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Logo
                    SizedBox(height: screenHeight * 0.2), // Adjust the top position as needed
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

                    // Email Text Field
                    const SizedBox(height: 45), // Adjust the space as needed
                    email(),

                    // Password Text Field
                    const SizedBox(height: 20), // Adjust the space as needed
                    password(),

                    // Remember Me Option
                    const SizedBox(height: 5), // Adjust the space as needed
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Row(
                        //   children: [
                        //     remember_me(),
                        //     const Text(
                        //       "Remember me",
                        //       style: TextStyle(
                        //         fontSize: 12,
                        //         fontFamily: 'Inika',
                        //         fontWeight: FontWeight.w900,
                        //         color: Colors.black87,
                        //       ),
                        //     )
                        //   ],
                        // ),
                        TextButton(
                          onPressed: () {
                            // Handle button press to navigate to the next page
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                            );
                          },
                          child: Text(
                            "Forgot password?",
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Inika',
                              fontWeight: FontWeight.w900,
                              color: Colors.black87,
                              fontStyle: FontStyle.italic
                            ),
                          )
                        )
                      ],
                    ),

                    // Login Button
                    const SizedBox(height: 40), // Adjust the space as needed

                     // Show loading indicator or login button
                    isLoading
                      ? const CircularProgressIndicator(color: primaryColor) // Show loading indicator
                      : Container(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              _login();
                            },
                            child: const Text(
                              'Login',
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
                        ),

                    // Sign Up Procedure
                    const SizedBox(height: 50),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? Sign up as",
                          style: TextStyle(
                            fontSize: 15,
                            fontFamily: "Inika",
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const UserSignUpScreen()),
                                );
                                // context.go('/userRegister');
                              },
                              child: Text(
                                "user",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Inika",
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            Text(
                              " / ",
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: "Inika",
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const TravelAgentSignUpScreen()),
                                );
                                // context.go('/travelAgentRegister');
                              },
                              child: Text(
                                "travel agent",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: "Inika",
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
}
