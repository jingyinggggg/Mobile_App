import "package:assignment_tripmate/constants.dart";
import "package:assignment_tripmate/screens/travelAgent/travelAgentReviewMainpage.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";

class TravelAgentViewReviewDetailsScreen extends StatefulWidget {
  final String userId;
  final String packageID;

  const TravelAgentViewReviewDetailsScreen({
    super.key, 
    required this.userId,
    required this.packageID
  });

  @override
  State<TravelAgentViewReviewDetailsScreen> createState() => _TravelAgentViewReviewDetailsScreenState();
}

class _TravelAgentViewReviewDetailsScreenState extends State<TravelAgentViewReviewDetailsScreen> {

  bool isFetching = false;
  List<Map<String, dynamic>> reviewData = [];

  @override
  void initState() {
    super.initState();
    _fetchReview();
  }

  Future<void> _fetchReview() async {
    setState(() {
      isFetching = true;
    });

    print("Package ID: ${widget.packageID}");

    try {
      // Fetch reviews where packageID equals the widget.packageID
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('review')
          .where('packageID', isEqualTo: widget.packageID)
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
            String userName = userDoc['name'] ?? 'Unknown'; // Provide default if the field doesn't exist
            String userProfile = userDoc['profileImage'] ?? ''; // Provide default if the field doesn't exist

            // Prepare the data to be added to the reviewData list
            Map<String, dynamic> reviewEntry = {
              'content': doc.data(), // Store the review data
              'userName': userName,
              'userProfile': userProfile,
            };

            // Add the review entry to the reviewData list
            reviewData.add(reviewEntry);
          }
        }
      }

      // Debugging output
      print('Review data: $reviewData');
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
      backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text("Review"),
          centerTitle: true,
          backgroundColor: const Color(0xFF749CB9),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontFamily: 'Inika',
            fontWeight: FontWeight.bold,
            fontSize: defaultAppBarTitleFontSize,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => TravelAgentViewReviewMainpageScreen(userId: widget.userId))
              );
            },
          ),
        ),
        body: isFetching
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : reviewData.isNotEmpty
        ? ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: reviewData.length,
          itemBuilder: (context, index){
            var docData = reviewData[index];

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
                        color: Color(0xFF467BA1),
                        width: 2.0,
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
                        Text(
                          docData['userName'],
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: defaultFontSize,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          docData['content']['review'],
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