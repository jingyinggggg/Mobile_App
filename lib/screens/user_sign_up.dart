// ignore_for_file: prefer_const_constructors, non_constant_identifier_names, unused_import, avoid_print, use_build_context_synchronously, no_leading_underscores_for_local_identifiers

import 'package:assignment_tripmate/firebase_auth_services.dart';
import 'package:assignment_tripmate/screens/login.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

class UserSignUpScreen extends StatefulWidget {
  const UserSignUpScreen({super.key});

  @override
  State<UserSignUpScreen> createState() => _UserSignUpScreenState();
}

class _UserSignUpScreenState extends State<UserSignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? dropdownValue;
  
  DateTime? _selectedDate;
  bool passwordVisible = true;
  bool confirmPasswordVisible = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Method to show date picker
  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2006, 12, 31),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(2006, 12, 31),
      builder: (BuildContext context, Widget? child) {
        return ScrollConfiguration(
          behavior: ScrollBehavior(),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _saveUserData() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    // Validate inputs
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _contactController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _selectedDate == null ||
        dropdownValue == null) {
      // Stop loading and show an error dialog if any field is empty
      setState(() {
        _isLoading = false;
      });
      _showDialog(
        title: 'Validation Error',
        content: 'Please fill all fields, select a date of birth and gender.',
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
      return;
    }

    // Check if passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      // Stop loading and show an error dialog if passwords do not match
      setState(() {
        _isLoading = false;
      });
      _showDialog(
        title: 'Validation Error',
        content: 'Passwords do not match.',
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
      return;
    }

    // Validate password
    final password = _passwordController.text;
    final specialCharRegExp = RegExp(r'[!@#%^&*(),.?":{}|<>]');
    String errorMessage = '';

    if (password.length < 8) {
      errorMessage += '• Password must be longer than 8 characters.\n';
    }

    if (!specialCharRegExp.hasMatch(password)) {
      errorMessage += '• Password must contain at least one special character.\n';
    }

    if (errorMessage.isNotEmpty) {
      // Stop loading and show an error dialog if password validation fails
      setState(() {
        _isLoading = false;
      });
      _showDialog(
        title: 'Validation Error',
        content: errorMessage,
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
      return;
    }

    final firestore = FirebaseFirestore.instance;

    String name = _nameController.text;
    String email = _emailController.text;
    DateTime? dob = _selectedDate;
    String contact = _contactController.text;
    String gender = dropdownValue!;

    try {
      // Check if email already exists
      final emailQuery = await firestore.collection('users')
        .where('email', isEqualTo: email)
        .get();

      if (emailQuery.docs.isNotEmpty) {
        // Stop loading and show an error dialog if email is already registered
        setState(() {
          _isLoading = false;
        });
        _showDialog(
          title: 'Validation Error',
          content: 'This email is already registered.',
          onPressed: () {
            Navigator.of(context).pop();
          },
        );
        return;
      }

      // Retrieve the current number of users
      final usersSnapshot = await firestore.collection('users').get();
      // final id = 'U${(usersSnapshot.docs.length + 1).toString().padLeft(4, '0')}';

      List<String> existingIDs = usersSnapshot.docs
        .map((doc) => doc.data()['id'] as String) // Extract cityID field
        .toList();
      
      String id = _generateNewID(existingIDs);

      // Convert date to a date-only format (without time)
      DateTime dobDateOnly = DateTime(dob!.year, dob.month, dob.day);

      // Hash the password
      String hashedPassword = BCrypt.hashpw(_passwordController.text, BCrypt.gensalt());

      // Save user data
      await firestore.collection('users').doc(id).set({
        'id': id,
        'name': name,
        'username': null,
        'email': email,
        'dob': Timestamp.fromDate(dobDateOnly),
        'contact': contact,
        'password': hashedPassword,
        'gender': gender,
        'profileImage': null,
      });

      // Show success dialog
      _showDialog(
        title: 'Registration Successful',
        content: 'You have been registered successfully.',
        onPressed: () {
          Navigator.of(context).pop(); // Close the success dialog
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        },
      );
    } catch (e) {
      // Show error dialog
      _showDialog(
        title: 'Registration Failed',
        content: 'Failed to save user data: $e',
        onPressed: () {
          Navigator.of(context).pop(); // Close the error dialog
        },
      );
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  String _generateNewID(List<String> existingIDs) {
    // Extract numeric parts from existing IDs and convert to integers
    List<int> numericIDs = existingIDs
        .map((id) {
          final match = RegExp(r'U(\d{4})').firstMatch(id);
          return match != null ? int.parse(match.group(1)!) : 0; // Convert "CTJAPANxxxx" to xxxx
        })
        .toList();

    // Find the highest ID
    int maxID = numericIDs.isNotEmpty ? numericIDs.reduce((a, b) => a > b ? a : b) : 0;

    // Generate new ID
    return 'U${(maxID + 1).toString().padLeft(4, '0')}'; // Ensure it has leading zeros
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

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
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top:20, left:20),
                          child: Image.asset(
                            'images/logo.png',
                            height: 35,
                            width: 35,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 15, top: 15),
                          child: Text(
                            'Register as user',
                            style: TextStyle(
                              fontFamily: 'inika',
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
                      child: Column(
                        children: [
                          name(),
                          SizedBox(height: 20),
                          email(),
                          SizedBox(height: 20),
                          gender(),
                          SizedBox(height: 20),
                          dobField(),
                          SizedBox(height: 20),
                          contact(),
                          SizedBox(height: 20),
                          password(),
                          SizedBox(height: 20),
                          confirm_password(),
                        ],
                      ),
                    ),

                    // Show loading indicator if _isLoading is true
                    if (_isLoading) 
                      Center(
                        child: CircularProgressIndicator(),
                      )
                    else
                      Padding(
                        padding: EdgeInsets.only(left: 15, right: 15, bottom: 20),
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                _saveUserData();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF467BA1),
                                textStyle: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                minimumSize: Size(screenWidth, screenHeight * 0.08),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),

                          SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF467BA1),
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              minimumSize: Size(screenWidth, screenHeight * 0.08),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Back',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          ],
                        )
                      )
                      
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget name() {
    return TextField(
      controller: _nameController,
      style: const TextStyle(
        fontFamily: 'Inika',
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Enter Name',
        labelText: 'Name',
        filled: true,
        fillColor: Colors.white,
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
              offset: Offset(0.5, 0.5),
              color: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  Widget email() {
    return TextField(
      controller: _emailController,
      style: const TextStyle(
        fontFamily: 'Inika',
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Enter Email',
        labelText: 'Email',
        filled: true,
        fillColor: Colors.white,
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
              offset: Offset(0.5, 0.5),
              color: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  Widget dobField() {
    return GestureDetector(
      onTap: () {}, // Prevents the TextField from being editable by touch.
      child: TextField(
        controller: TextEditingController(
          text: _selectedDate == null
              ? ''
              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
        ),
        style: TextStyle(
          fontFamily: 'Inika',
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: _selectedDate == null ? Colors.grey.shade600 : Colors.black,
        ),
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'Select your date of birth',
          labelText: 'Date of Birth',
          filled: true,
          fillColor: Colors.white,
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
                offset: Offset(0.5, 0.5),
                color: Colors.black87,
              ),
            ],
          ),
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF467BA1),
              size: 20,
            ),
            onPressed: () => _selectDate(context),
          ),
        ),
      ),
    );
  }

  Widget gender() {
    return DropdownButtonFormField<String>(
      value: dropdownValue,
      hint: Text('Select Gender'),
      decoration: InputDecoration(
        labelText: 'Gender',
        filled: true,
        fillColor: Colors.white,
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
              offset: Offset(0.5, 0.5),
              color: Colors.black87,
            ),
          ],
        ),
      ),
      items: const [
        DropdownMenuItem<String>(
          value: 'Male',
          child: Text('Male'),
        ),
        DropdownMenuItem<String>(
          value: 'Female',
          child: Text('Female'),
        ),
      ],
      onChanged: (String? newValue) {
        setState(() {
          dropdownValue = newValue;
        });
      },
      style: const TextStyle(
        fontFamily: 'Inika',
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Colors.black,
      ),
    );
  }

  Widget contact() {
    return TextField(
      controller: _contactController,
      style: const TextStyle(
        fontFamily: 'Inika',
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: 'Enter Contact Number',
        labelText: 'Contact Number',
        filled: true,
        fillColor: Colors.white,
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
              offset: Offset(0.5, 0.5),
              color: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  Widget password() {
    return TextField(
      controller: _passwordController,
      obscureText: passwordVisible,
      style: const TextStyle(
        fontFamily: 'Inika',
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Enter Password',
        labelText: 'Password',
        filled: true,
        fillColor: Colors.white,
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
              offset: Offset(0.5, 0.5),
              color: Colors.black87,
            ),
          ],
        ),
        suffixIcon: IconButton(
          icon: Icon(
            passwordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.black54,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              passwordVisible = !passwordVisible;
            });
          },
        ),
      ),
    );
  }

  Widget confirm_password() {
    return TextField(
      controller: _confirmPasswordController,
      obscureText: confirmPasswordVisible,
      style: const TextStyle(
        fontFamily: 'Inika',
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Confirm Password',
        labelText: 'Confirm Password',
        filled: true,
        fillColor: Colors.white,
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
              offset: Offset(0.5, 0.5),
              color: Colors.black87,
            ),
          ],
        ),
        suffixIcon: IconButton(
          icon: Icon(
            confirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.black54,
            size: 20,
          ),
          onPressed: () {
            setState(() {
              confirmPasswordVisible = !confirmPasswordVisible;
            });
          },
        ),
      ),
    );
  }
}
