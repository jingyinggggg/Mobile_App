import 'package:assignment_tripmate/screens/login.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentProfile.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentRevenue.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentReviewMainpage.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentSettingScreen.dart';
import 'package:assignment_tripmate/screens/user/helpCenter.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TravelAgentAccountScreen extends StatefulWidget {
  final String userId;

  const TravelAgentAccountScreen({super.key, required this.userId});

  @override
  State<TravelAgentAccountScreen> createState() => _TravelAgentAccountScreenState();
}

class _TravelAgentAccountScreenState extends State<TravelAgentAccountScreen> {
  int currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('travelAgent')
            .doc(widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(child: Text("Travel agent not found"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

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
                  // width: 150,
                  // height: 170,
                  // alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        userData['username'] ?? userData['name'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10,),
                      Container(
                        width: screenWidth * 0.25,  
                        height: screenWidth * 0.25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(0xFF467BA1),  // Border color
                            width: 3.0,  // Border width
                          ),
                        ),
                        child: userData['profileImage'] != null
                            ? CircleAvatar(
                                radius: screenWidth * 0.125,
                                backgroundImage: NetworkImage(userData['profileImage']),
                              )
                            : CircleAvatar(
                                radius: screenWidth * 0.125,
                                backgroundImage: AssetImage("images/profile.png"),
                                backgroundColor: Colors.white,
                              ),
                      )
                    ]
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
                    top: screenHeight * 0.16,
                    left: screenWidth * 0.55,
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
                                      TravelAgentProfileScreen(userId: widget.userId)),
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
                    top: screenHeight * 0.28,
                    left: screenWidth * 0.72,
                    child: Column(
                      children: [
                        const Text(
                          "Setting",
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
                                    TravelAgentSettingScreen(userId: widget.userId)),
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
                  //   top: 280,
                  //   left: 230,
                  //   child: Column(
                  //     children: [
                  //       const Text(
                  //         "Wishlist",
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
                    top: screenHeight * 0.37,
                    left: screenWidth * 0.26,
                    child: Column(
                      children: [
                        const Text(
                          "Review",
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
                                      TravelAgentViewReviewMainpageScreen(userId: widget.userId)),
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
                  //   top: 330,
                  //   left: 40,
                  //   child: Column(
                  //     children: [
                  //       const Text(
                  //         "Blog",
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
                    top: screenHeight * 0.55,
                    left: screenWidth * 0.12,
                    child: Column(
                      children: [
                        const Text(
                          "Revenue",
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
                                      TravelAgentRevenueScreen(userId: widget.userId)),
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
                    left: screenWidth * 0.35,
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
                                      HelpCenterScreen(userId: widget.userId, isTravelAgent: true,)),
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
