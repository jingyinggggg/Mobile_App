import 'package:assignment_tripmate/screens/admin/adminProfile.dart';
import 'package:assignment_tripmate/screens/admin/adminSetting.dart';
import 'package:assignment_tripmate/screens/admin/adminViewFeedback.dart';
import 'package:assignment_tripmate/screens/login.dart';
import 'package:assignment_tripmate/screens/user/helpCenter.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAccountScreen extends StatefulWidget {
  final String userId;

  const AdminAccountScreen({super.key, required this.userId});

  @override
  State<AdminAccountScreen> createState() => _AdminAccountScreenState();
}

class _AdminAccountScreenState extends State<AdminAccountScreen> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('admin')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(child: Text("User not found"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          var username = userData['username'] ?? '';

          
          return Stack(
            children: [
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

              Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.02, left: screenWidth * 0.08 ,),
                child: Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: screenWidth * 0.25,  
                        height: screenWidth * 0.25,
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
                    ],
                  ),
                ),
              ),

              Stack(
                children: [
                  Positioned(
                    top: screenHeight * 0.115,
                    left: screenWidth * 0.06,
                    child: Image(
                      image: AssetImage("images/flight_line.png"),
                      height: screenHeight * 0.6,
                      width: screenWidth * 0.75,
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.18,
                    left: screenWidth * 0.6,
                    child: Column(
                      children: [
                        const Text(
                          "Profile",
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdminProfileScreen(userId: widget.userId)),
                            );
                          },
                          child: Image.asset(
                            'images/location-pin.png',
                            width: screenWidth * 0.1,
                            height: screenWidth * 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Positioned(
                  //   top: 230,
                  //   left: 310,
                  //   child: Column(
                  //     children: [
                  //       const Text(
                  //         "Setting",
                  //         style: TextStyle(
                  //             fontWeight: FontWeight.w900,
                  //             color: Colors.black,
                  //             fontSize: 16),
                  //       ),
                  //       GestureDetector(
                  //         onTap: () {
                  //           Navigator.push(
                  //             context,
                  //             MaterialPageRoute(
                  //                 builder: (context) =>
                  //                     AdminSettingScreen(userId: widget.userId,)),
                  //           );
                  //         },
                  //         child: Image.asset(
                  //           'images/location-pin.png',
                  //           width: 50,
                  //           height: 50,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  Positioned(
                    top: screenHeight * 0.36,
                    left: screenWidth * 0.4,
                    child: Column(
                      children: [
                        const Text(
                          "Setting",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      AdminSettingScreen(userId: widget.userId,)),
                            );
                          },
                          child: Image.asset(
                            'images/location-pin.png',
                            width: screenWidth * 0.1,
                            height: screenWidth * 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Positioned(
                  //   top: 320,
                  //   left: 110,
                  //   child: Column(
                  //     children: [
                  //       const Text(
                  //         "Booking",
                  //         style: TextStyle(
                  //             fontWeight: FontWeight.w900,
                  //             color: Colors.black,
                  //             fontSize: 16),
                  //       ),
                  //       GestureDetector(
                  //         onTap: () {
                  //           // Navigator.push(
                  //           //   context,
                  //           //   MaterialPageRoute(
                  //           //       builder: (context) =>
                  //           //           const SettingScreen()),
                  //           // );
                  //         },
                  //         child: Image.asset(
                  //           'images/location-pin.png',
                  //           width: 50,
                  //           height: 50,
                  //         ),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                  Positioned(
                    top: screenHeight * 0.4,
                    left: screenWidth * 0.07,
                    child: Column(
                      children: [
                        const Text(
                          "Feedback",
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      AdminViewFeedbackScreen(userId: widget.userId,)),
                            );
                          },
                          child: Image.asset(
                            'images/location-pin.png',
                            width: screenWidth * 0.1,
                            height: screenWidth * 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.6,
                    left: screenWidth * 0.25,
                    child: Column(
                      children: [
                        const Text(
                          "Help Center",
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      HelpCenterScreen(userId: widget.userId, isAdmin: true,)),
                            );
                          },
                          child: Image.asset(
                            'images/location-pin.png',
                            width: screenWidth * 0.1,
                            height: screenWidth * 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.61,
                    left: screenWidth * 0.74,
                    child: Column(
                      children: [
                        const Text(
                          "Logout",
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            FirebaseAuth.instance.signOut();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const LoginScreen()),
                            );
                          },
                          child: Image.asset(
                            'images/location-pin.png',
                            width: screenWidth * 0.1,
                            height: screenWidth * 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: screenHeight * 0.68,
                    left: screenWidth * 0.81,
                    child: Image.asset(
                      'images/flag.png',
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                    ),
                  ),
                ],
              )
            ],
          );
        },
      ),
    );
  }
}
