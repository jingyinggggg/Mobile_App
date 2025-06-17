import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/leaveFeedback.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentUpdatePassword.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TravelAgentSettingScreen extends StatefulWidget {
  final String userId;

  const TravelAgentSettingScreen({super.key, required this.userId});

  @override
  State<TravelAgentSettingScreen> createState() => _TravelAgentSettingScreenState();
}

class _TravelAgentSettingScreenState extends State<TravelAgentSettingScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Setting"),
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
                  top: getScreenHeight(context) * 0.03,
                  left: getScreenWidth(context) * 0.05,
                ),
                child: Container(
                  width: getScreenWidth(context) * 0.4,
                  height: getScreenHeight(context) * 0.25,
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Text(
                        userData['username'] ?? userData['name'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Container(
                        width: getScreenWidth(context) * 0.25,
                        height: getScreenWidth(context) * 0.25,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF467BA1),
                            width: 3.0,
                          ),
                        ),
                        child: userData['profileImage'] != null
                            ? CircleAvatar(
                                radius: getScreenWidth(context) * 0.125,
                                backgroundImage: NetworkImage(userData['profileImage']),
                              )
                            : CircleAvatar(
                                radius: getScreenWidth(context) * 0.125,
                                backgroundImage: const AssetImage("images/profile.png"),
                                backgroundColor: Colors.white,
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: getScreenHeight(context) * 0.07,
                left: getScreenWidth(context) * 0.1,
                child: Image(
                  image: AssetImage("images/route line.png"),
                  height: getScreenHeight(context) * 0.25,
                  width: getScreenWidth(context) * 0.75,
                ),
              ),
              Positioned(
                top: getScreenHeight(context) * 0.06,
                left: getScreenWidth(context) * 0.745,
                child: Column(
                  children: [
                    Text(
                      "Setting",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    Image.asset(
                      'images/location-pin.png',
                      width: getScreenWidth(context) * 0.1,
                      height: getScreenWidth(context) * 0.1,
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.only(top: getScreenHeight(context) * 0.35, left: 10, right: 10),
                child: Column(
                  children: [
                    _buildButton(
                      icon: Icons.lock,
                      text: "Change Password",
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(
                            builder: (context) => TravelAgentUpdatePasswordScreen(userId: widget.userId)
                          )
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    _buildButton(
                      icon: AssetImage("images/leave_feedback.png"),
                      text: "Leave a feedback",
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => FeedbackScreen(userID: widget.userId))
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

    Widget _buildButton({required dynamic icon, required String text, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFF467BA1), width: 3),
          ),
          minimumSize: const Size.fromHeight(55),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (icon is IconData)
              Icon(icon, color: Colors.black, size: 20)
            else if (icon is ImageProvider)
              ImageIcon(icon, color: Colors.black, size: 20),
            SizedBox(width: 15),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, color: Colors.black),
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 20),
          ],
        ),
      ),
    );
  }
}
