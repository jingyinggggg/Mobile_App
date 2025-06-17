import "package:assignment_tripmate/constants.dart";
import "package:assignment_tripmate/screens/admin/adminManageWithdrawalRequestDetails.dart";
import "package:assignment_tripmate/screens/admin/homepage.dart";
import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";

class AdminRevenueMainpageScreen extends StatefulWidget {
  final String userId;

  const AdminRevenueMainpageScreen({
    super.key,
    required this.userId,
  });

  @override
  State<AdminRevenueMainpageScreen> createState() => _AdminRevenueMainpageScreenState();
}

class _AdminRevenueMainpageScreenState extends State<AdminRevenueMainpageScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // State variable to hold the fetched data
  List<Map<String, dynamic>> _pendingRevenueDocuments = [];
  bool _isLoading = true;

  // Method to fetch documents with a withdrawal subcollection with "pending" status
  Future<void> _fetchRevenueDocuments() async {
    List<Map<String, dynamic>> revenueDocsWithPendingWithdrawal = [];

    // Query the revenue collection
    var querySnapshot = await _firestore.collection('revenue').get();

    // Loop through each revenue document
    for (var doc in querySnapshot.docs) {
      // Retrieve the 'id' field within the document (not the Firestore document ID)
      var revenueId = doc['id']; // Access the 'id' field inside the revenue document

      // Query the 'withdrawal' subcollection for documents where status is 'pending'
      var withdrawalSnapshot = await doc.reference.collection('withdrawal').where('status', isEqualTo: 'pending').get();
      
      if (withdrawalSnapshot.docs.isNotEmpty) {
        // If the withdrawal subcollection has documents with 'pending' status, store the relevant data
        // Loop through each document in the withdrawal subcollection
        for (var withdrawalDoc in withdrawalSnapshot.docs) {
          revenueDocsWithPendingWithdrawal.add({
            'userID': revenueId, // Store the 'id' field from the revenue document
            'withdrawalData': withdrawalDoc.data(), // Store the full data from the withdrawal document
          });
        }
      }
    }

    // Update the state with the fetched documents
    setState(() {
      _pendingRevenueDocuments = revenueDocsWithPendingWithdrawal;
      _isLoading = false; // Set loading to false after data is fetched
    });
  }

  @override
  void initState() {
    super.initState();
    // Fetch the revenue documents on init
    _fetchRevenueDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Withdrawal Request"),
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
              MaterialPageRoute(builder: (context) => AdminHomepageScreen(userId: widget.userId))
            );
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // Show loading spinner while fetching data
          : _pendingRevenueDocuments.isEmpty
              ? const Center(child: Text('No pending withdrawal requests.')) // Handle empty data
              : ListView.builder(
                  itemCount: _pendingRevenueDocuments.length,
                  itemBuilder: (context, index) {
                    var docData = _pendingRevenueDocuments[index];
                    var withdrawalUserId = docData['userID']; // Access the 'id' field from revenue document
                    var withdrawalData = docData['withdrawalData']; // Access the full withdrawal document data

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ListTile(
                        tileColor: const Color.fromARGB(255, 219, 239, 255),
                        contentPadding: const EdgeInsets.all(12.0),
                        title: Text(
                          'Withdrawal ID: ${withdrawalData['withdrawalID']}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontSize: defaultLabelFontSize
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10),
                            Text(
                              'Amount: RM ${withdrawalData['amount'].toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black,
                                fontSize: defaultFontSize
                              ),
                            ),
                            // You can format the withdrawal data further if needed
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => AdminRevenueDetailsScreen(userId: widget.userId, withdrawalID: withdrawalData['withdrawalID'], withdrawalUserID: withdrawalUserId))
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
