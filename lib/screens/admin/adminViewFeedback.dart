import "package:assignment_tripmate/constants.dart";
import "package:assignment_tripmate/screens/admin/adminAccountPage.dart";
import "package:assignment_tripmate/screens/admin/homepage.dart";
import "package:assignment_tripmate/utils.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";

class AdminViewFeedbackScreen extends StatefulWidget {
  final String userId;

  const AdminViewFeedbackScreen({
    super.key, 
    required this.userId,
  });

  @override
  State<AdminViewFeedbackScreen> createState() => _AdminViewFeedbackScreenState();
}

class _AdminViewFeedbackScreenState extends State<AdminViewFeedbackScreen> {

  bool isFetching = false;
  List<Map<String, dynamic>> feedbackData = [];

  @override
  void initState() {
    super.initState();
    _fetchFeedback();
  }

  Future<void> _fetchFeedback() async {
    setState(() {
      isFetching = true;
    });

    try {
      // Fetch reviews where packageID equals the widget.localBuddyId
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('feedback')
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Iterate over each review document
        for (var doc in snapshot.docs) {
          // Get userID from the review document
          String userID = doc['userID'];

          // Fetch the user data from the 'users' collection based on userID
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userID)
              .get();

          if (userDoc.exists) {
            // Extract user details (assuming the fields exist)
            String userName = userDoc['name'] ?? 'Unknown';  // Provide default if the field doesn't exist
            String userProfile = userDoc['profileImage'] ?? '';  // Provide default if the field doesn't exist

            Map<String, dynamic> feedbackEntry = {
              'content': doc.data(),  // Store the review data
              'userName': userName,
              'userProfile': userProfile,
            };

            feedbackData.add(feedbackEntry);
          }
        }
      }
    } catch (e) {
      print("Error fetching reviews: $e");
    } finally {
      setState(() {
        isFetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 236, 236, 236),
        resizeToAvoidBottomInset: true,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE57373), Color.fromARGB(255, 236, 236, 236)], // Soft pink gradient
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: AppBar(
              title: const Text("Feedback"),
              centerTitle: true,
              backgroundColor: Colors.transparent, // Makes the gradient visible
              elevation: 0,
              titleTextStyle: const TextStyle(
                color: Colors.black,
                fontFamily: 'Inika',
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                onPressed: () {
                  
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => AdminAccountScreen(userId: widget.userId))
              );
                },
              ),
            ),
          ),
        ),
        body: isFetching
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : feedbackData.isNotEmpty
        ? ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: feedbackData.length,
          itemBuilder: (context, index){
            var docData = feedbackData[index];

            return Container(
              width: double.infinity,
              padding: EdgeInsets.all(15),
              margin: EdgeInsets.only(left: 15, right: 15, top: 15),
              decoration: BoxDecoration(
                border: Border.all(color: primaryColor, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(0xFFF50057),
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.white,
                      backgroundImage: docData['userProfile'] != null
                          ? NetworkImage(docData['userProfile'])
                          : AssetImage("images/profile.png") as ImageProvider,
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded( // Use Expanded to avoid overflow
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              docData['userName'],
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700,
                                fontSize: defaultFontSize,
                              ),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy').format(docData['content']['timestamp'].toDate()),
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ]
                        ),
                        
                        SizedBox(height: 5),
                        Text(
                          docData['content']['feedback'],
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.justify,
                          overflow: TextOverflow.visible, // Handle long text
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          
          )
        : Center(
            child: Text(
              "No review in the selected package.",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: defaultFontSize
              ),
              textAlign: TextAlign.center,
            )
          ),
    );
  }

}