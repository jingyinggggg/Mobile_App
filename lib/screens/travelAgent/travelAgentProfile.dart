import 'dart:typed_data';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentUpdateProfile.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; 

class TravelAgentProfileScreen extends StatefulWidget {
  final String userId;

  const TravelAgentProfileScreen({super.key, required this.userId});

  @override
  State<TravelAgentProfileScreen> createState() => _TravelAgentProfileScreenState();
}

class _TravelAgentProfileScreenState extends State<TravelAgentProfileScreen> {

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Profile"),
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

          // Format the DateTime object to only show the date
          String formatDate(DateTime dateTime) {
            return DateFormat('dd/MM/yyy').format(dateTime);
          }

          // Get the DateTime from the userData
          DateTime? dob = userData['dob']?.toDate(); // Convert Timestamp to DateTime

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
                padding: EdgeInsets.only(
                  top: screenHeight * 0.03,
                  left: screenWidth * 0.05,
                ),
                child: Container(
                  width: screenWidth * 0.4,
                  height: screenHeight * 0.25,
                  alignment: Alignment.center,
                  child: Column(
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
              Positioned(
                top: screenHeight * 0.07,
                left: screenWidth * 0.1,
                child: Image(
                  image: AssetImage("images/route line.png"),
                  height: screenHeight * 0.25,
                  width: screenWidth * 0.75,
                ),
              ),
              Positioned(
                top: screenHeight * 0.06,
                left: screenWidth * 0.745,
                child: Column(
                  children: [
                    Text(
                      "Profile",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    Image.asset(
                      'images/location-pin.png',
                      width: screenWidth * 0.1,
                      height: screenWidth * 0.1,
                    ),
                  ],
                ),
              ),

              Positioned(
                top: screenHeight * 0.3,
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF467BA1), 
                    borderRadius: BorderRadius.circular(15), 
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                      // The top blue part
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: Color(0xFF467BA1), // Same blue color
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "ACCOUNT INFO",
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                            Spacer(),
                            Icon(
                              Icons.airplane_ticket_outlined,
                              color: Colors.white,
                              size: screenWidth * 0.05,
                            )
                          ],
                        ),
                      ),

                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        color: Colors.white,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 7,
                                  child: Container(
                                    padding: EdgeInsets.only(right: 5),
                                    decoration: BoxDecoration(
                                      border: Border(right: BorderSide(color: Color(0xFF467BA1), width: 2))
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text(
                                              "Name: ",
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              userData['name'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500
                                              ),
                                              textAlign: TextAlign.justify,
                                              maxLines: null,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Text(
                                              "DOB: ",
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              dob != null ? formatDate(dob) : '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Text(
                                              "Email: ",
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text(
                                              userData['email'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500
                                              ),
                                              textAlign: TextAlign.justify,
                                              maxLines: null,
                                              overflow: TextOverflow.visible,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            const Text(
                                              "Account Status: ",
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Row(
                                              children: [
                                                if (userData['accountApproved'] == 0 || userData['accountApproved'] == 3)
                                                  Row(
                                                    children: const [
                                                      Text(
                                                        "Reviewing",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.orange, // You can change the color as needed
                                                          fontWeight: FontWeight.w900,
                                                        ),
                                                      ),
                                                      SizedBox(width: 5),
                                                      Icon(Icons.hourglass_empty, color: Colors.orange, size: 20), // Icon for reviewing
                                                    ],
                                                  )
                                                else if (userData['accountApproved'] == 1)
                                                  Row(
                                                    children: const [
                                                      Text(
                                                        "Approved",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.green, // You can change the color as needed
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      SizedBox(width: 5),
                                                      Icon(Icons.check_circle, color: Colors.green, size: 20), // Icon for approved
                                                    ],
                                                  )
                                                else if (userData['accountApproved'] == 2)
                                                  Row(
                                                    children: const [
                                                      Text(
                                                        "Reject",
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.red, // You can change the color as needed
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      SizedBox(width: 5),
                                                      Icon(Icons.no_accounts, color: Colors.red, size: 20), // Icon for approved
                                                    ],
                                                  )
                                                else
                                                  const Text(
                                                    "", // Default case (empty text)
                                                  ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                ),
                                SizedBox(width: 5),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Username:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        userData['username']?? '-',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        "Gender: ",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        userData['gender'] ?? 'Null',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),

                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Color(0xFF467BA1),
                                    width: 2,
                                  )
                                )
                              ),
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        "Company Name: ",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        userData['companyName'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500
                                        ),
                                        textAlign: TextAlign.justify,
                                        maxLines: null,
                                        overflow: TextOverflow.visible,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Text(
                                        "Company Contact: ",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        userData['companyContact'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 5),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Company Address: ",
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Expanded(
                                        child: Text(
                                          userData['companyAddress'] ?? '',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500
                                          ),
                                          textAlign: TextAlign.justify,
                                          maxLines: null,
                                          overflow: TextOverflow.visible,
                                        ),                                      
                                      )
                                    ],
                                  ),
                                ],
                              )
                            ),

                          ],
                        ), 
                        
                      ),
                      Container(
                        height: screenHeight * 0.04,
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        decoration: BoxDecoration(
                          color: const Color(0xFF467BA1),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(15),
                            bottomRight: Radius.circular(15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: screenHeight * 0.08,
                left: 0, // Remove left positioning
                right: 0, // Remove right positioning
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TravelAgentUpdateProfileScreen(userId: widget.userId,)),
                      );
                    },
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF467BA1),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.15,
                        vertical: screenHeight * 0.02,
                      ),
                      textStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
