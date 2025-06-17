import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUpdateProfileScreen extends StatefulWidget {
  final String userId;

  const AdminUpdateProfileScreen({super.key, required this.userId});

  @override
  State<AdminUpdateProfileScreen> createState() => _AdminUpdateProfileScreenState();
}

class _AdminUpdateProfileScreenState extends State<AdminUpdateProfileScreen> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();

  bool isUpdating = false; 
  bool _isDataInitialized = false;

  @override
  void initState() {
    super.initState();
    _fetchAdminData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

      Future<void> _fetchAdminData() async{
    setState(() {
      _isDataInitialized = true;
    });
    try{
      DocumentReference UserRef = FirebaseFirestore.instance.collection('admin').doc(widget.userId);
      DocumentSnapshot UserSnapshot = await UserRef.get();

      if(UserSnapshot.exists){
        Map<String, dynamic>? data = UserSnapshot.data() as Map<String, dynamic>?;

        setState(() {
          _isDataInitialized = false;

          _nameController.text = data?['name'] ?? '';
          _usernameController.text = data?['username'] ?? '';
          _emailController.text = data?['email'] ?? '';
        });
      } else{
        setState(() {
          _isDataInitialized = false;
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Current admin does not exists in the system')),
        );
        });
      }
    } catch(e){
        setState(() {
          _isDataInitialized = false;
        });
        print("Error fetch admin details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Update Profile"),
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
      body: Stack(
            children: [
              if(_isDataInitialized)
                Center(
                  child: Container(
                    // color: Colors.black.withOpacity(0.5), // Optional: semi-transparent background
                    child: const CircularProgressIndicator(),
                  ),
                ),

              if(!_isDataInitialized)
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("images/account_background.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: double.infinity,
                  width: double.infinity,
                  color: const Color(0xFFEDF2F6).withOpacity(0.6),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.only(top:20, left: 10, right: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 30),
                        child: Column(
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white, // Set background color
                                shape: BoxShape.circle,
                                border: Border.all(color: Color(0xFF467BA1), width: 4)
                              ),
                              child: ClipOval(
                                child: Padding(
                                  padding: const EdgeInsets.all(15.0), // Adding padding
                                  child: Image.asset(
                                    'images/logo.png', // Your updated logo asset
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),
                            username(),
                            const SizedBox(height: 20),
                            name(),
                            const SizedBox(height: 20),
                            email(),
                            const SizedBox(height: 20),

                            isUpdating
                              ? const CircularProgressIndicator() // Show loading indicator
                              : Center(
                                  child: 
                                    ElevatedButton(
                                      onPressed: _updateProfile,
                                      child: const Text(
                                        'Update',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF467BA1),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 70, vertical: 15),
                                        textStyle: const TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'Inika',
                                          fontWeight: FontWeight.bold,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                              )
                          ]
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
      );
    }

  Widget name() {
    return TextField(
      controller: _nameController,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Please update your name...',
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

  Widget username() {
    return TextField(
      controller: _usernameController,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      maxLength: 12,
      decoration: InputDecoration(
        hintText: 'Please update your username...',
        labelText: 'Username',
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
      readOnly: true,
      controller: _emailController,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
        color: Colors.black54,
      ),
      decoration: InputDecoration(
        hintText: 'Please update your email...',
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

  void _updateProfile() async {
    setState(() {
      isUpdating = true; // Start loading
    });

    try {
      await FirebaseFirestore.instance.collection('admin').doc(widget.userId).update({
        'name': _nameController.text,
        'username': _usernameController.text,
      });

      // Show success dialog
      _showDialog(
        title: 'Update Successful',
        content: 'Your details have been updated successfully.',
        onPressed: () {
          Navigator.of(context).pop(); // Close the success dialog
          Navigator.of(context).pop(); 
        },
      );
    } catch (e) {
      _showDialog(
        title: 'Updated Failed',
        content: 'An error occurred: $e',
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
    } finally {
      setState(() {
        isUpdating = false; // Stop loading
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
}
