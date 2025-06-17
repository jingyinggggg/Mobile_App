import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentRevenue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;

class TravelAgentRevenueDetailsScreen extends StatefulWidget {
  final String userId;
  final String withdrawalID;

  const TravelAgentRevenueDetailsScreen({
    super.key,
    required this.userId,
    required this.withdrawalID
  });

  @override
  State<TravelAgentRevenueDetailsScreen> createState() => _TravelAgentRevenueDetailsScreenState();
}

class _TravelAgentRevenueDetailsScreenState extends State<TravelAgentRevenueDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> withdrawalData = {};
  bool isLoading = false;
  bool isOpenProofFile = false;

  @override
  void initState() {
    super.initState();
    _fetchRevenueDocuments();
  }

  Future<void> _fetchRevenueDocuments() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Query the revenue collection
      var querySnapshot = await _firestore.collection('revenue').get();

      // Loop through each revenue document
      for (var doc in querySnapshot.docs) {
        // Query the 'withdrawal' subcollection for documents where withdrawalID matches
        var withdrawalSnapshot = await doc.reference
            .collection('withdrawal')
            .where('withdrawalID', isEqualTo: widget.withdrawalID)
            .get();

        // If a document with the specified withdrawalID exists, store its data
        if (withdrawalSnapshot.docs.isNotEmpty) {
          // Since we are looking for a single withdrawal document, take the first one
          withdrawalData = withdrawalSnapshot.docs.first.data();
          break; // Exit the loop if we found the document
        }
      }

      // Update the state to reflect the fetched data
      setState(() {
        isLoading = false; // Set loading to false after data is fetched
      });
    } catch (e) {
      print("Error fetching withdrawal data: $e");
    }
  }

  Future<void> downloadAndOpenImageFromUrl(String url) async {
    // Fetch the image from the URL
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // If the server returns an OK response, display the image
      final bytes = response.bodyBytes;

      // Display the image in a new screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PhotoView(
            imageProvider: MemoryImage(bytes),
            heroAttributes: const PhotoViewHeroAttributes(tag: "image"),
          ),
        ),
      );
    } else {
      // Handle the error case
      throw Exception('Failed to load image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Revenue"),
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
              MaterialPageRoute(builder: (context) => TravelAgentRevenueScreen(userId: widget.userId))
            );
          },
        ),
      ),
      body: isLoading
      ? Center(child: CircularProgressIndicator(color: primaryColor))
      : Padding(
        padding: EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            Icon(
              withdrawalData['status'] == "done" ? Icons.check_circle : Icons.pending_actions,
              color: withdrawalData['status'] == "done" ? Colors.green : Colors.orange,
              size: 50,
            ),
            SizedBox(height: 20),
            Text(
              "RM ${withdrawalData['amount'].toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                color: Colors.black
              ),
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Withdrawal ID:",
                  style: TextStyle(
                    fontSize: defaultLabelFontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.black
                  ),
                ),
                Text(
                  withdrawalData['withdrawalID'],
                  style: TextStyle(
                    fontSize: defaultLabelFontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.black
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Date:",
                  style: TextStyle(
                    fontSize: defaultLabelFontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.black
                  ),
                ),
                Text(
                  DateFormat('yyyy-MM-dd').format(withdrawalData['timestamp'].toDate()),
                  style: TextStyle(
                    fontSize: defaultLabelFontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.black
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Status:",
                  style: TextStyle(
                    fontSize: defaultLabelFontSize,
                    fontWeight: FontWeight.w500,
                    color: Colors.black
                  ),
                ),
                Text(
                  withdrawalData['status'] == "done" ? "Done" : "Pending",
                  style: TextStyle(
                    fontSize: defaultLabelFontSize,
                    fontWeight: FontWeight.bold,
                    color: withdrawalData['status'] == "done" ? Colors.green : Colors.orange
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            if(withdrawalData['status'] == "done")
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Proof:",
                    style: TextStyle(
                      fontSize: defaultLabelFontSize,
                      fontWeight: FontWeight.w500,
                      color: Colors.black
                    ),
                  ),
                  isOpenProofFile
                  ? SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(color: primaryColor),
                    ) 
                  : SizedBox(
                    height: 35,
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          isOpenProofFile = true; // Update the loading state
                        });
                        String url = withdrawalData['transferProof'];
                        await downloadAndOpenImageFromUrl(url);
                        setState(() {
                          isOpenProofFile = false; // Update the state when done
                        });
                      }, 
                      child:Text(
                        "View Transfer Proof",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,  
                        foregroundColor: primaryColor,  
                        shape: RoundedRectangleBorder(
                          side: BorderSide(color: primaryColor, width: 2),
                          borderRadius: BorderRadius.circular(10)
                        ),
                      ),
                    )
                  )

                ],
              ),
            SizedBox(height: 20),
            Text(
              withdrawalData['status'] == "done" ? "Note: Admin has issued your withdrawal request. Please check your bank." : "Note: Your withdrawal request is pending approved by admin.",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      )
    );    
  }
}


