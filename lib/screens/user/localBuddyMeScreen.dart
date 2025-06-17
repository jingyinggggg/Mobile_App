import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/user/localBuddyEditInfo.dart';
import 'package:assignment_tripmate/screens/user/localBuddyRegistration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class LocalBuddyMeScreen extends StatefulWidget {
  final String userId;

  const LocalBuddyMeScreen({
    super.key,
    required this.userId,
  });

  @override
  State<StatefulWidget> createState() => _LocalBuddyMeScreenState();
}

class _LocalBuddyMeScreenState extends State<LocalBuddyMeScreen> {
  bool isLoading = false;
  String? registrationMessage;
  Map<String, dynamic>? localBuddyData;

  @override
  void initState() {
    super.initState();
    _checkCurrentUserStatus();
  }

  Future<void> _checkCurrentUserStatus() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Fetch the user document based on the userId using a where condition
      QuerySnapshot userQuerySnapshot = await FirebaseFirestore.instance
          .collection('localBuddy')
          .where('userID', isEqualTo: widget.userId) // Filter by userID
          .get();

      if (userQuerySnapshot.docs.isNotEmpty) {
        // If the query returns documents
        var userSnapshot = userQuerySnapshot.docs.first; // Get the first document
        localBuddyData = userSnapshot.data() as Map<String, dynamic>; // Save the entire document data

        int registrationStatus = localBuddyData!['registrationStatus'];

        switch (registrationStatus) {
          case 0:
            registrationMessage = 'Your request is pending review by admin.';
            break;
          case 1:
            registrationMessage = 'Your request has been approved by admin. You may have an interview meeting with admin. Please check your email for interview details.';
            break;
          case 2:
            registrationMessage = 'You has been shorlisted.';
            break;
          case 3:
            registrationMessage = 'Your registration request has been rejected by admin. Please check the rejection reason and submit the request again.';
            break;
          case 4:
            registrationMessage = 'Thank you for your interest in becoming a Local Buddy. We appreciate your enthusiasm and willingness to assist others. However, after careful consideration, we regret to inform you that you have not been shortlisted for the Local Buddy position at this time.';
            break;
          case 5:
            registrationMessage = 'Your request is pending review by admin.';
          default:
            registrationMessage = 'Unknown status.';
        }
      } else {
        registrationMessage = 'If you are interested in becoming a local buddy, click on the apply button to register as a local buddy.';
      }
    } catch (e) {
      registrationMessage = 'Error fetching user status: $e';
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading indicator
          : Center(
              child: registrationMessage != null
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if(localBuddyData?['registrationStatus'] != 2)
                      Column(
                        children: [
                          Icon(
                            localBuddyData?['registrationStatus'] == 0 || localBuddyData?['registrationStatus'] == 5
                              ? Icons.hourglass_bottom_rounded
                              : localBuddyData?['registrationStatus'] == 1
                                ? Icons.schedule
                                : localBuddyData?['registrationStatus'] == 3
                                  ? Icons.close_rounded
                                  : localBuddyData?['registrationStatus'] == 4
                                    ? Icons.no_accounts_rounded
                                    : Icons.app_registration,
                              size: 60,
                              color: localBuddyData?['registrationStatus'] == 0 || localBuddyData?['registrationStatus'] == 5
                                ? Colors.orange
                                : localBuddyData?['registrationStatus'] == 1
                                  ? Colors.blue
                                  : localBuddyData?['registrationStatus'] == 3
                                    ? Colors.red
                                    : localBuddyData?['registrationStatus'] == 4
                                      ? Colors.black
                                      : null
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.only(left: 10, right: 10),
                            child: Text(
                              registrationMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: defaultFontSize, fontWeight: FontWeight.w500),
                            ),
                          ),
                          
                          if(localBuddyData?['registrationStatus'] == null)
                            Container(
                              width: 200,
                              height: 50,
                              margin: EdgeInsets.only(top: 20),
                              child: ElevatedButton(
                                onPressed: (){
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (context) => LocalBuddyRegistrationScreen(userId: widget.userId))
                                  );
                                }, 
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF467BA1),
                                  textStyle: const TextStyle(
                                    fontSize: defaultLabelFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  "Become local buddy",
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),

                                )
                              ),
                            ),
                          
                          if(localBuddyData?['registrationStatus'] == 3)
                            Container(
                              width: 200,
                              height: 50,
                              margin: EdgeInsets.only(top: 20),
                              child: ElevatedButton(
                                onPressed: (){
                                  Navigator.push(
                                    context, 
                                    MaterialPageRoute(builder: (context) => LocalBuddyEditInfoScreen(userId: widget.userId))
                                  );
                                }, 
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF467BA1),
                                  textStyle: const TextStyle(
                                    fontSize: defaultLabelFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: Text(
                                  "View Reject Reason",
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),

                                )
                              ),
                            )

                        ],
                      )
                  ],
                )
              : const Text("No status available."),
          ),
    );
  }
}
